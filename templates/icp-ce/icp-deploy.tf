##################################
## This module handles all the ICP confifguration
## and prerequisites setup
##################################

# Azure client config let's us pull out some details such as subscription ID
# which is used by the azure cloud provider
data "azurerm_client_config" "client_config" {}

module "icpprovision" {
  source = "github.com/ibm-cloud-architecture/terraform-module-icp-deploy?ref=3.0.7"

  bastion_host = "${element(concat(azurerm_public_ip.bootnode_pip.*.ip_address, azurerm_public_ip.master_pip.*.ip_address, list("")), 0)}"

  # Provide IP addresses for boot, master, mgmt, va, proxy and workers
  boot-node = "${element(concat(azurerm_network_interface.boot_nic.*.private_ip_address, azurerm_network_interface.master_nic.*.private_ip_address, list("")), 0)}"

  icp-host-groups = {
    master      = ["${azurerm_network_interface.master_nic.*.private_ip_address}"]
    worker      = ["${azurerm_network_interface.worker_nic.*.private_ip_address}"]
    proxy       = ["${azurerm_network_interface.proxy_nic.*.private_ip_address}"]
    management  = ["${azurerm_network_interface.management_nic.*.private_ip_address}"]
  }

  icp-inception = "${var.icp_version}"

  # Workaround for terraform issue #10857
  # When this is fixed, we can work this out autmatically

  cluster_size  = "${var.boot["nodes"] + var.master["nodes"] + var.worker["nodes"] + var.proxy["nodes"] + var.management["nodes"]}"

  icp_configuration = {
    "network_cidr"              = "${var.network_cidr}"
    "service_cluster_ip_range"  = "${var.cluster_ip_range}"
    "ansible_user"              = "icpdeploy"
    "ansible_become"            = "true"
    "cluster_lb_address"        = "${element(azurerm_public_ip.master_pip.*.fqdn, 0)}"
    "proxy_lb_address"          = "${element(azurerm_public_ip.proxy_pip.*.fqdn, 0)}"
    "cluster_CA_domain"         = "${azurerm_public_ip.master_pip.fqdn}"
    "cluster_name"              = "${var.cluster_name}"

    # RHEL requires firewall enabled flag
    "firewall_enabled"          = "true"

    # An admin password will be generated if not supplied in terraform.tfvars
    "default_admin_password"    = "${var.icpadmin_password}"

    # This is the list of disabled management services
    "management_services"       = "${local.disabled_management_services}"

    "calico_ip_autodetection_method" = "can-reach=${azurerm_network_interface.master_nic.0.private_ip_address}"
    "kubelet_nodename"          = "nodename"
    "cloud_provider"            = "azure"

    # Azure specific arguments
    "kube_controller_manager_extra_args" = ["--allocate-node-cidrs=true", "--feature-gates=ServiceNodeExclusion=true", "--node-cidr-mask-size=26"]
    "kubelet_extra_args" = ["--enable-controller-attach-detach=true"]

    # Azure specific configurations
    # We don't need ip in ip with Azure networking
    "calico_ipip_enabled"       = "false"
    "calico_networking_backend" = "none"
    "calico_ipam_type"          = "host-local"
    "calico_ipam_subnet"        = "usePodCidr"

    "azure"                  = {
      # Common authantication details for both kubelet and controller manager
      "cloud_provider_conf" = {
          "cloud"               = "AzurePublicCloud"
          "useInstanceMetadata" = "true"
          "tenantId"            = "${data.azurerm_client_config.client_config.tenant_id}"
          "subscriptionId"      = "${data.azurerm_client_config.client_config.subscription_id}"
          "resourceGroup"       = "${azurerm_resource_group.icp.name}"
          "useManagedIdentityExtension" = "true"
      }
      # Authentication information specific for controller
      ## Controller will need additional permissions as it needs to create routes in the router table,
      ## interact with storage and networking resources
      "cloud_provider_controller_conf" = {
          "cloud"               = "AzurePublicCloud"
          "useInstanceMetadata" = "true"
          "tenantId"            = "${data.azurerm_client_config.client_config.tenant_id}"
          "subscriptionId"      = "${data.azurerm_client_config.client_config.subscription_id}"
          "resourceGroup"       = "${azurerm_resource_group.icp.name}"
          "aadClientId"         = "${var.aadClientId}"
          "aadClientSecret"     = "${var.aadClientSecret}"
          "location"            = "${azurerm_resource_group.icp.location}"
          "subnetName"          = "${element(compact(concat(list("${var.container_subnet_id}"), azurerm_subnet.container_subnet.*.id)), 0)}"
          "vnetName"            = "${var.virtual_network_name}"
          "vnetResourceGroup"   = "${azurerm_resource_group.icp.name}"
          "routeTableName"      = "${azurerm_route_table.routetb.name}"
          "cloudProviderBackoff"        = "false"
          "loadBalancerSku"             = "Standard"
          "primaryAvailabilitySetName"  = "${basename(element(azurerm_virtual_machine.worker.*.availability_set_id, 0))}"# "workers_availabilityset"
          "securityGroupName"           = "${azurerm_network_security_group.worker_sg.name}"# "hktest-worker-sg"
          "excludeMasterFromStandardLB" = "true"
          "useManagedIdentityExtension" = "false"
      }
    }

    # We'll insert a dummy value here to create an implicit dependency on VMs in Terraform
    "dummy_waitfor" = "${length(concat(azurerm_virtual_machine.master.*.id, azurerm_virtual_machine.worker.*.id, azurerm_virtual_machine.management.*.id))}"

  }

  generate_key = true

  ssh_user         = "icpdeploy"
  ssh_key_base64   = "${base64encode(tls_private_key.installkey.private_key_pem)}"
  ssh_agent        = "${var.ssh_agent}"

}

output "icp_admin_password" {
  value = "${module.icpprovision.default_admin_password}"
}

output "cloudctl" {
  value = "cloudctl login --skip-ssl-validation -a https://${element(azurerm_public_ip.master_pip.*.fqdn, 0)}:8443 -u admin -p ${module.icpprovision.default_admin_password} -n default -c id-${var.cluster_name}-account"
}
