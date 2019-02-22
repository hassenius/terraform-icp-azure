# Azure Networking

The network implementation for ICP on Azure differs from other infrastructure platforms in that the routing for the container network is handled by the Azure network routing, rather than Calico.
This means that the container network must exist as an actual subnet in Azure, and the Azure Controller Manager needs write permission to the Azure Route Table to update the routing as the ICP cluster is created.
The Azure Controller Manager gets its access through the `aadClientId` and `aadClientSecret` template variables.

## Separate subnet for controlplane

In some cases it can be desirable to have separate subnets for control plane and worker nodes.
For example if you have tight integration between the VNet and on-prem environments, where you can not rely on Security Groups outside Azure, but would like to create firewall rules based on IP Address segments.
To create a separate subnet for your control plane nodes (masters, management, va, etcd) populate the template variables `controlplane_subnet_name` and `controlplane_subnet_prefix`. Workers and Proxy nodes will still be placed in the standard subnet.
So for example to place `controlplane` VMs in a subnet with prefix `10.0.1.0/24` and `worker` and `proxy` in a subnet with prefix `10.0.2.0/24` enter the following in your `terraform.tfvars` file:

```
controlplane_subnet_name    = "controlplane_subnet"
controlplane_subnet_prefix  = "10.0.1.0/24"
subnet_name                 = "workers_subnet"
subnet_prefix               = "10.0.2.0/24"
```

## Using existing Azure Virtual Network

In some cases it is desirable to use existing Azure Virtual Networks, that may reside in existing resoruce groups. It is possible to do this, as long as the ICP Cluster and resource group resides in the same Azure Region as the existing Azure Virtual Network.

To use an existing Azure Virtual Network follow these steps:
1. Create the required subnets in the existing VNet. At least 1 subnet for VMs and 1 subnet for the ICP Container network.
2. In your `terraform.tfvars` file, ensure the network entries are present
  ```
  virtual_network_name = "" # Leave blank to use existing VNet
  container_subnet_id = "/subscriptions/<subscription_id>/resourceGroups/<resource_group>/providers/Microsoft.Network/virtualNetworks/<vnet_name>/subnets/<subnetname>" # Replace values in anglebrackets
  vm_subnet_id = "/subscriptions/<subscription_id>/resourceGroups/<resource_group>/providers/Microsoft.Network/virtualNetworks/<vnet_name>/subnets/<subnetname>" # Replace values in anglebrackets
  ```
  If you have a separate subnet for controlplane you also need to populate `controlplane_subnet_id`
