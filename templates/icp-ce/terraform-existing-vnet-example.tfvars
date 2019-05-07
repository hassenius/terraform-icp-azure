# Example tfvars for provisioning ICP to a existing vnet
# First thing when using existing VNET you must explicitly leave virtual_network_name empty
virtual_network_name = ""

# Then you must specify the existing subnet IDs in the following example format
container_subnet_id = "/subscriptions/0e0a4287-8719-4849-bb0b-5242e4507709/resourceGroups/hans-moen-network/providers/Microsoft.Network/virtualNetworks/hans-vnet/subnets/containersubnet"
vm_subnet_id = "/subscriptions/0e0a4287-8719-4849-bb0b-5242e4507709/resourceGroups/hans-moen-network/providers/Microsoft.Network/virtualNetworks/hans-vnet/subnets/workersubnet"
controlplane_subnet_id = "/subscriptions/0e0a4287-8719-4849-bb0b-5242e4507709/resourceGroups/hans-moen-network/providers/Microsoft.Network/virtualNetworks/hans-vnet/subnets/controlplanesubnet"

# Importantly cluster_ip_range must match the range of container_subnet_id
# and network_cidr must be unique in the overall network
cluster_ip_range = "172.16.128.0/17" # Should match the setting for container_subnet_id
network_cidr = "192.168.1.0/24" # For internal kubernetes services. Should not clash with any other CIDR

# Location should match the location of existing vnet
location = "Central US"
