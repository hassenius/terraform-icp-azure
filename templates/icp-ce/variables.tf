

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

variable "virtual_network_name" {
  description = "The name for the virtual network."
  default     = "vnet"
}
variable "address_spaces" {
  type = "list"
  description = "The address space that is used by the virtual network. You can supply more than one address space. Changing this forces a new resource to be created."
  default     = ["172.16.0.0/16","10.1.0.0/16","10.0.0.0/24"]
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
  description = "The address prefix to use for the subnet."
  default     = "172.16.1.0/24"
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
    rhel_sku         = "7.4"
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
/*
variable "admin_password" {
  description = "administrator password (recommended to disable password auth)"
  default = ""
}
*/
variable "ssh_key_name" {
  default = "az-icp"
}
##### ICP Configurations ######
variable "network_cidr" {
  description = "ICP Network CIDR"
  default     = "10.1.0.0/16"
}
variable "cluster_ip_range" {
  description = "ICP Service Cluster IP Range"
  default     = "10.0.0.1/24"
}
variable "icpadmin_password" {
    description = "ICP admin password"
    default = "admin"
}
variable "icp_version" {
    description = "ICP Version"
    default = "2.1.0.3"
}
variable "cluster_name" {
  description = "Deployment name for resources prefix"
  default     = "myicp"
}
variable "master" {
  type = "map"
  default = {
    nodes       = "1"
    name        = "master"
    vm_size     = "Standard_A4_v2"
  }
}
variable "proxy" {
  type = "map"
  default = {
    nodes       = "1"
    name        = "proxy"
    vm_size     = "Standard_A2_v2"
  }
}
variable "management" {
  type = "map"
  default = {
    nodes       = "1"
    name        = "mgmt"
    vm_size     = "Standard_A4_v2"
  }
}
variable "worker" {
  type = "map"
  default = {
    nodes       = "3"
    name        = "worker"
    vm_size     = "Standard_A4_v2"
  }
}
