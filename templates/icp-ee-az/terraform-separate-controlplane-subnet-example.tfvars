# This is an example tfvars file for placing controlplane vms on a separate azure subnet.

## The default setings in variables.tf is
# virtual_network_cidr = "10.0.0.0/16" for the overall azure vnet that is created
# and subnet_prefix = "10.0.0.0/24" for the VM subnet.
# Normally the control plane VMs (masters, management, etc) is placed in this subnet together
# with the worker VMs. To create a separate subnet for the subnet for the control plane VMs
# we can populate the following variables

controlplane_subnet_name = "controlplane_subnet"
controlplane_subnet_prefix = "10.0.1.0/24"
