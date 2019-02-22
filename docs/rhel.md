# Red Hat Enterprise Linux in Azure

This automation relies on cloud-init for a substantial amount of the environment preparation.
Currently the only RHEL image in Azure that supports cloud-init is `7-RAW-CI`, which is in preview.
More details [here](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/using-cloud-init)

Since `7-RAW-CI` is a preview image, it is not recommended to use this in production, but rather include cloud-init in the normal _golden image_ creation process.

RHEL 7.4 and earlier may also require some additional settings for mounting Azure Files.
Azure Files is needed for shared storage in the `icp-ee` templates, and also when using the kubernetes integration for dynamic volume provisioning. Details available [here](https://access.redhat.com/solutions/3176281)


## cloud-init in RHEL
For cloud-init to work on RHEL you will need a few steps in preparation

1. Install cloud-init
  ```
  sudo yum -y install cloud-init
  ```
2. Create a hostname wrapper file saved in `/etc/cloud/hostnamewrapper.sh`
  ```
  #!/bin/bash

  if [[ -n $1 ]]; then
    /bin/hostnamectl set-hostname $1
  else
    /bin/hostname
  fi
  ```
3. Ensure hostname wrapper is called by creating `/etc/cloud/cloud.cfg.d/90-hostnamectl-workaround-azure.cfg`
  ```
  datasource:
    Azure:
      hostname_bounce:
        hostname_command: /etc/cloud/hostnamewrapper.sh
  ```
4. Ensure Azure datasource is enabled by creating `/etc/cloud/cloud.cfg.d/91-azure_datasource.cfg`
  ```
  datasource_list: [ Azure ]
  ```
