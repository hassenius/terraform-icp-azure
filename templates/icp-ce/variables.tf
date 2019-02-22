

# See https://azure.microsoft.com/en-us/global-infrastructure/regions/ for details of locatiopn
variable "location" {
  description = "Region to deploy to"
  default     = "West Europe"
}


variable "instance_name" {
  description = "Name of the deployment. Will be added to virtual machine names"
  default     = "icp"
}
# Default tags to apply to resources
variable "default_tags" {
  description = "Map of default tags to be assign to any resource that supports it"
  type    = "map"
  default = {
    Owner         = "icpuser"
    Environment   = "icp-test"
  }
}


variable "resource_group" {
  description = "Azure resource group name"
  default = "icp_rg"
}

variable "container_subnet_id" {
  description = "ID of container subnet if using existing VNET. Only when var.virtual_network_name is empty"
  default = ""
}

variable "vm_subnet_id" {
  description = "ID of vm subnet if using existing VNET. Only when var.virtual_network_name is empty"
  default = ""
}

variable "controlplane_subnet_id" {
  description = "ID of controlplane subnet if using existing VNET. Only when var.virtual_network_name is empty and want control plane separate from workers"
  default = ""
}

variable "virtual_network_name" {
  description = "The name for the Azure virtual network. Leave blank and populate *_subnet_id to use existing Azure Virtual Network"
  default     = "icp_vnet"
}

variable "virtual_network_cidr" {
  description = "cidr for the Azure virtual network"
  default     = "10.0.0.0/16"
}
variable "route_table_name" {
  description = "The name for the route table."
  default     = "icp_route"
}
variable "subnet_name" {
  description = "The subnet name"
  default     = "icp_subnet"
}
variable "subnet_prefix" {
  description = "The address prefix to use for the VM subnet."
  default     = "10.0.0.0/24"
}

variable "controlplane_subnet_name" {
  description = "The name of the controlplane subnet. Leave blank single subnet for cluster"
  default     = ""
}

variable "controlplane_subnet_prefix" {
  description = "The address prefix to use if creating separate controlplane subnet."
  default     = ""
}

variable "storage_account_tier" {
  description = "Defines the Tier of storage account to be created. Valid options are Standard and Premium."
  default     = "Standard"
}
variable "storage_replication_type" {
  description = "Defines the Replication Type to use for this storage account. Valid options include LRS, GRS etc."
  default     = "LRS"
}
variable "ssh_public_key" {
    description = "SSH Public Key"
    default = ""
}

variable "disable_password_authentication" {
  description = "Whether to enable or disable ssh password authentication for the created Azure VMs. Default: true"
  default     = "true"

}
variable "os_image" {
  description = "Select from Ubuntu (ubuntu) or RHEL (rhel) for the Operating System"
  default     = "ubuntu"
}

variable "os_image_map" {
  description = "os image map"
  type        = "map"

  default = {
    rhel_publisher   = "RedHat"
    rhel_offer       = "RHEL"
    #rhel_sku         = "7.5"
    rhel_sku         = "7-RAW-CI"
    rhel_version     = "latest"
    ubuntu_publisher = "Canonical"
    ubuntu_offer     = "UbuntuServer"
    ubuntu_sku       = "16.04-LTS"
    ubuntu_version   = "latest"
  }
}
variable "admin_username" {
  description = "linux vm administrator user name"
  default     = "vmadmin"
}


##### ICP Configurations ######
variable "network_cidr" {
  description = "ICP Network CIDR for PODs"
  default     = "10.0.128.0/17"
}
variable "cluster_ip_range" {
  description = "ICP Service Cluster IP Range"
  default     = "10.1.0.0/24"
}
variable "icpadmin_password" {
    description = "ICP admin password"
    default = ""
}
variable "icp_version" {
    description = "ICP Version"
    default = "3.1.2"
}
variable "cluster_name" {
  description = "Deployment name for resources prefix"
  default     = "myicp"
}

variable "boot" {
  type = "map"
  default = {
    nodes         = "0"
    name          = "bootnode"
    os_image      = "ubuntu"
    vm_size       = "Standard_A2_v2"
    os_disk_type  = "Standard_LRS"
    os_disk_size  = "100"
    docker_disk_size = "100"
    docker_disk_type = "StandardSSD_LRS"
    enable_accelerated_networking = "false"
  }
}

variable "master" {
  type = "map"
  default = {
    nodes         = "1"
    name          = "master"
    vm_size       = "Standard_A8_v2"
    os_disk_type  = "Standard_LRS"
    docker_disk_size = "100"
    docker_disk_type = "Standard_LRS"
  }
}
variable "proxy" {
  type = "map"
  default = {
    nodes         = "1"
    name          = "proxy"
    vm_size       = "Standard_A2_v2"
    os_disk_type  = "Standard_LRS"
    docker_disk_size = "100"
    docker_disk_type = "Standard_LRS"
  }
}
variable "management" {
  type = "map"
  default = {
    nodes         = "1"
    name          = "mgmt"
    #vm_size      = "Standard_A4_v2"
    vm_size       = "Standard_A8_v2"
    os_disk_type  = "Standard_LRS"
    docker_disk_size = "100"
    docker_disk_type = "Standard_LRS"
  }
}
variable "worker" {
  type = "map"
  default = {
    nodes         = "2"
    name          = "worker"
    vm_size       = "Standard_A4_v2"
    os_disk_type  = "Standard_LRS"
    docker_disk_size = "100"
    docker_disk_type = "Standard_LRS"
  }
}

## IAM options for kubelet and controller manager
variable "aadClientId" {
  description = "aadClientId to be provided to kubernetes controller manager"
}
variable "aadClientSecret" {
  description = "aadClientSecret to be provided to kubernetes controller manager"
}

# The following services can be disabled for 3.1
# custom-metrics-adapter, image-security-enforcement, istio, metering, monitoring, service-catalog, storage-minio, storage-glusterfs, and vulnerability-advisor
variable "disabled_management_services" {
  description = "List of management services to disable"
  type        = "list"
  default     = ["istio", "vulnerability-advisor", "storage-glusterfs", "storage-minio", "metrics-server", "custom-metrics-adapter", "image-security-enforcement", "metering", "monitoring", "logging", "audit-logging"]
}
