##############################################
## Cloud-init definitions to be used when creating instances
##############################################

## Some common definitions that can be reused with different node types
data "template_file" "common_config" {
  template = <<EOF
  #cloud-config
  package_upgrade: true
  packages:
    - cifs-utils
    - nfs-common
    - python-yaml
  users:
    - default
    - name: icpdeploy
      groups: [ wheel ]
      sudo: [ "ALL=(ALL) NOPASSWD:ALL" ]
      shell: /bin/bash
      ssh-authorized-keys:
        - ${tls_private_key.installkey.public_key_openssh}
EOF
}

data "template_file" "docker_disk" {
  template = <<EOF
#!/bin/bash
sudo mkdir -p /var/lib/docker
# Check if we have a separate docker disk, or if we should use temporary disk
if [ -e /dev/sdc ]; then
  sudo parted -s -a optimal /dev/disk/azure/scsi1/lun1 mklabel gpt -- mkpart primary xfs 1 -1
  sudo partprobe
  sudo mkfs.xfs -n ftype=1 /dev/disk/azure/scsi1/lun1-part1
  echo "/dev/disk/azure/scsi1/lun1-part1  /var/lib/docker   xfs  defaults   0 0" | sudo tee -a /etc/fstab
else
  # Use the temporary disk
  sudo umount /mnt
  sudo sed -i 's|/mnt|/var/lib/docker|' /etc/fstab
fi
sudo mount /var/lib/docker
EOF
}

data "template_file" "etcd_disk" {
  template = <<EOF
#!/bin/bash
sudo mkdir -p /var/lib/etcd
sudo mkdir -p /var/lib/etcd-wal
etcddisk=$(ls /dev/disk/azure/*/lun2)
waldisk=$(ls /dev/disk/azure/*/lun3)

sudo parted -s -a optimal $etcddisk mklabel gpt -- mkpart primary xfs 1 -1
sudo parted -s -a optimal $waldisk mklabel gpt -- mkpart primary xfs 1 -1
sudo partprobe

sudo mkfs.xfs -n ftype=1 $etcddisk-part1
sudo mkfs.xfs -n ftype=1 $waldisk-part1
echo "$etcddisk-part1  /var/lib/etcd   xfs  defaults   0 0" | sudo tee -a /etc/fstab
echo "$waldisk-part1  /var/lib/etcd-wal   xfs  defaults   0 0" | sudo tee -a /etc/fstab

sudo mount /var/lib/etcd
sudo mount /var/lib/etcd-wal
EOF
}

data "template_file" "load_tarball" {
  template = <<EOF
#!/bin/bash
image_file="$(basename $${tarball})"

cd /tmp
wget -O azcopy.tar.gz https://aka.ms/downloadazcopylinux64
tar -xf azcopy.tar.gz
sudo ./install.sh

mkdir -p /opt/ibm/cluster/images
azcopy --source $${tarball} --source-key $${key} --destination /opt/ibm/cluster/images/$image_file

# For now we need to install docker here
wget https://raw.githubusercontent.com/ibm-cloud-architecture/terraform-module-icp-deploy/master/scripts/boot-master/install-docker.sh
chmod a+x install-docker.sh
# Don't know why I need to do this first in azure
sudo chmod 777 /tmp
./install-docker.sh

# Now load the docker tarball
tar xf /opt/ibm/cluster/images/$image_file -O | sudo docker load
EOF

  vars {
    tarball = "${var.image_location}"
    key     = "${var.image_location_key}"
  }
}

data "template_file" "master_config" {
  template = <<EOF
#cloud-config
write_files:
- path: /etc/smbcredentials/icpregistry.cred
  content: |
    username=$${username}
    password=$${password}
mounts:
- [ ${element(split(":", azurerm_storage_share.icpregistry.url), 1)}, /var/lib/registry, cifs, "nofail,credentials=/etc/smbcredentials/icpregistry.cred,dir_mode=0777,file_mode=0777,serverino" ]

EOF

  vars {
    username= "${azurerm_storage_account.infrastructure.name}"
    password= "${azurerm_storage_account.infrastructure.primary_access_key}"
    tarball = "${var.image_location}"
    key     = "${var.image_location_key}"
  }
}

data "template_cloudinit_config" "bootconfig" {
  gzip          = true
  base64_encode = true

  # Create the icpdeploy user which we will use during initial deployment of ICP.
  part {
    content_type = "text/cloud-config"
    content      =  "${data.template_file.common_config.rendered}"
  }

  # Setup the docker disk
  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.docker_disk.rendered}"
  }

  # Load the ICP Images
  part {
    content_type = "text/x-shellscript"
    content      = "${var.image_location != "" ? data.template_file.load_tarball.rendered : "#!/bin/bash"}"
  }

}

## Definitions for each VM type
data "template_cloudinit_config" "masterconfig" {
  gzip          = true
  base64_encode = true

  # Create the icpdeploy user which we will use during initial deployment of ICP.
  part {
    content_type = "text/cloud-config"
    content      =  "${data.template_file.common_config.rendered}"
  }

  # Setup the docker disk
  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.docker_disk.rendered}"
  }

  # Setup the etcd disks
  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.etcd_disk.rendered}"
  }

  # Setup the icp registry share
  part {
    content_type = "text/cloud-config"
    content      =  "${data.template_file.master_config.rendered}"
  }

  # Load the ICP Images
  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.load_tarball.rendered}"
  }
}


data "template_cloudinit_config" "workerconfig" {
  gzip          = true
  base64_encode = true

  # Create the icpdeploy user which we will use during initial deployment of ICP.
  part {
    content_type = "text/cloud-config"
    content      =  "${data.template_file.common_config.rendered}"
  }

  # Setup the docker disk
  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.docker_disk.rendered}"
  }
}
