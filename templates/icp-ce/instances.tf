
data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  # Create the icpdeploy user which we will use during initial deployment of ICP.
  part {
    content_type = "text/cloud-config"
    content      =  <<EOF
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

  # Setup the docker disk
  part {
    content_type = "text/x-shellscript"
    content      = <<EOF
#!/bin/bash
sudo mkdir -p /var/lib/docker
# sudo parted -s -a optimal /dev/sdc mklabel gpt -- mkpart primary xfs 1 -1

# sudo partprobe
umount /mnt
mount /dev/sdb1 /var/lib/docker
sudo sed -i 's|/mnt|/var/lib/docker|' /etc/fstab
#sudo mkfs.xfs -n ftype=1 /dev/sdc1
#echo "/dev/sdc1  /var/lib/docker   xfs  defaults   0 0" | sudo tee -a /etc/fstab
#sudo mount -a
EOF
  }
}



##################################
## Create Availability Sets
##################################

resource "azurerm_availability_set" "workers" {
  name                = "workers_availabilityset"
  location            = "${azurerm_resource_group.icp.location}"
  resource_group_name = "${azurerm_resource_group.icp.name}"
  managed             = true

  tags {
    environment = "Production"
  }
}

##################################
## Create Boot VM
##################################
resource "azurerm_virtual_machine" "boot" {
  count                 = "${var.boot["nodes"]}"
  name                  = "${var.boot["name"]}${count.index + 1}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.icp.name}"
  vm_size               = "${var.boot["vm_size"]}"
  network_interface_ids = ["${element(azurerm_network_interface.boot_nic.*.id, count.index)}"]

  # The SystemAssigned identity enables the Azure Cloud Provider to use ManagedIdentityExtension
  identity = {
    type = "SystemAssigned"
  }

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true
  # Enable using a different OS for the boot node
  storage_image_reference {
    publisher = "${lookup(var.os_image_map, join("_publisher", list(var.boot["os_image"], "")))}"
    offer     = "${lookup(var.os_image_map, join("_offer", list(var.boot["os_image"], "")))}"
    sku       = "${lookup(var.os_image_map, join("_sku", list(var.boot["os_image"], "")))}"
    version   = "${lookup(var.os_image_map, join("_version", list(var.boot["os_image"], "")))}"
  }

  storage_os_disk {
    name              = "${var.boot["name"]}-osdisk-${count.index + 1}"
    managed_disk_type = "${var.boot["os_disk_type"]}"
    disk_size_gb      = "${var.boot["os_disk_size"]}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  storage_data_disk {
    name              = "${var.proxy["name"]}-dockerdisk-${count.index + 1}"
    managed_disk_type = "${var.proxy["docker_disk_type"]}"
    disk_size_gb      = "${var.proxy["docker_disk_size"]}"
    caching           = "ReadWrite"
    create_option     = "Empty"
    lun               = 1
  }

  os_profile {
    computer_name  = "${var.boot["name"]}${count.index + 1}"
    admin_username = "${var.admin_username}"
    custom_data    = "${data.template_cloudinit_config.config.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = "${var.disable_password_authentication}"
    ssh_keys {
      key_data = "${var.ssh_public_key}"
      path = "/home/${var.admin_username}/.ssh/authorized_keys"
    }
  }
}


##################################
## Create Master VM
##################################
resource "azurerm_virtual_machine" "master" {
  count                 = "${var.master["nodes"]}"
  name                  = "${var.master["name"]}${count.index + 1}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.icp.name}"
  vm_size               = "${var.master["vm_size"]}"
  network_interface_ids = ["${element(azurerm_network_interface.master_nic.*.id, count.index)}"]

  # The SystemAssigned identity enables the Azure Cloud Provider to use ManagedIdentityExtension
  identity = {
    type = "SystemAssigned"
  }

  storage_image_reference {
    publisher = "${lookup(var.os_image_map, join("_publisher", list(var.os_image, "")))}"
    offer     = "${lookup(var.os_image_map, join("_offer", list(var.os_image, "")))}"
    sku       = "${lookup(var.os_image_map, join("_sku", list(var.os_image, "")))}"
    version   = "${lookup(var.os_image_map, join("_version", list(var.os_image, "")))}"
  }

  storage_os_disk {
    name              = "${var.master["name"]}-osdisk-${count.index + 1}"
    managed_disk_type = "${var.master["os_disk_type"]}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  os_profile {
    computer_name  = "${var.master["name"]}${count.index + 1}"
    admin_username = "${var.admin_username}"
    custom_data    = "${data.template_cloudinit_config.config.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = "${var.disable_password_authentication}"
    ssh_keys {
      key_data = "${var.ssh_public_key}"
      path = "/home/${var.admin_username}/.ssh/authorized_keys"
    }
  }
}


##################################
## Create Proxy VM
##################################
resource "azurerm_virtual_machine" "proxy" {
  count                 = "${var.proxy["nodes"]}"
  name                  = "${var.proxy["name"]}${count.index + 1}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.icp.name}"
  vm_size               = "${var.proxy["vm_size"]}"
  network_interface_ids = ["${element(azurerm_network_interface.proxy_nic.*.id, count.index)}"]

  # The SystemAssigned identity enables the Azure Cloud Provider to use ManagedIdentityExtension
  identity = {
    type = "SystemAssigned"
  }

  storage_image_reference {
    publisher = "${lookup(var.os_image_map, join("_publisher", list(var.os_image, "")))}"
    offer     = "${lookup(var.os_image_map, join("_offer", list(var.os_image, "")))}"
    sku       = "${lookup(var.os_image_map, join("_sku", list(var.os_image, "")))}"
    version   = "${lookup(var.os_image_map, join("_version", list(var.os_image, "")))}"
  }

  storage_os_disk {
    name              = "${var.proxy["name"]}-osdisk-${count.index + 1}"
    managed_disk_type = "${var.proxy["os_disk_type"]}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  os_profile {
    computer_name  = "${var.proxy["name"]}${count.index + 1}"
    admin_username = "${var.admin_username}"
    custom_data    = "${data.template_cloudinit_config.config.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = "${var.disable_password_authentication}"
    ssh_keys {
      key_data = "${var.ssh_public_key}"
      path = "/home/${var.admin_username}/.ssh/authorized_keys"
    }
  }
}

##################################
## Create Management VM
##################################
resource "azurerm_virtual_machine" "management" {
  count                 = "${var.management["nodes"]}"
  name                  = "${var.management["name"]}${count.index + 1}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.icp.name}"
  vm_size               = "${var.management["vm_size"]}"
  network_interface_ids = ["${element(azurerm_network_interface.management_nic.*.id, count.index)}"]

  # The SystemAssigned identity enables the Azure Cloud Provider to use ManagedIdentityExtension
  identity = {
    type = "SystemAssigned"
  }

  storage_image_reference {
    publisher = "${lookup(var.os_image_map, join("_publisher", list(var.os_image, "")))}"
    offer     = "${lookup(var.os_image_map, join("_offer", list(var.os_image, "")))}"
    sku       = "${lookup(var.os_image_map, join("_sku", list(var.os_image, "")))}"
    version   = "${lookup(var.os_image_map, join("_version", list(var.os_image, "")))}"
  }

  storage_os_disk {
    name              = "${var.management["name"]}-osdisk-${count.index + 1}"
    managed_disk_type = "${var.management["os_disk_type"]}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  os_profile {
    computer_name  = "${var.management["name"]}${count.index + 1}"
    admin_username = "${var.admin_username}"
    custom_data    = "${data.template_cloudinit_config.config.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = "${var.disable_password_authentication}"
    ssh_keys {
      key_data = "${var.ssh_public_key}"
      path = "/home/${var.admin_username}/.ssh/authorized_keys"
    }
  }
}


##################################
## Create Worker VM
##################################
resource "azurerm_virtual_machine" "worker" {
  count                 = "${var.worker["nodes"]}"
  name                  = "${var.worker["name"]}${count.index + 1}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.icp.name}"
  vm_size               = "${var.worker["vm_size"]}"
  network_interface_ids = ["${element(azurerm_network_interface.worker_nic.*.id, count.index)}"]

  # The SystemAssigned identity enables the Azure Cloud Provider to use ManagedIdentityExtension
  identity = {
    type = "SystemAssigned"
  }

  availability_set_id = "${azurerm_availability_set.workers.id}"

  storage_image_reference {
    publisher = "${lookup(var.os_image_map, join("_publisher", list(var.os_image, "")))}"
    offer     = "${lookup(var.os_image_map, join("_offer", list(var.os_image, "")))}"
    sku       = "${lookup(var.os_image_map, join("_sku", list(var.os_image, "")))}"
    version   = "${lookup(var.os_image_map, join("_version", list(var.os_image, "")))}"
  }

  storage_os_disk {
    name              = "${var.worker["name"]}-osdisk-${count.index + 1}"
    managed_disk_type = "${var.worker["os_disk_type"]}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  os_profile {
    computer_name  = "${var.worker["name"]}${count.index + 1}"
    admin_username = "${var.admin_username}"
    custom_data    = "${data.template_cloudinit_config.config.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = "${var.disable_password_authentication}"
    ssh_keys {
      key_data = "${var.ssh_public_key}"
      path = "/home/${var.admin_username}/.ssh/authorized_keys"
    }
  }
}
