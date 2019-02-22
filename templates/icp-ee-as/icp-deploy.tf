##################################
## This module handles all the ICP confifguration
## and prerequisites setup
##################################

# TODO: Add azure-disk and azure-file volumes

data "azurerm_client_config" "client_config" {}

locals {

  # Intermediate interpolations
  credentials = "${var.registry_username != "" ? join(":", list("${var.registry_username}"), list("${var.registry_password}")) : ""}"
  cred_reg   = "${local.credentials != "" ? join("@", list("${local.credentials}"), list("${var.private_registry}")) : ""}"

  # Inception image formatted for ICP deploy module
  inception_image = "${local.cred_reg != "" ? join("/", list("${local.cred_reg}"), list("${var.icp_inception_image}")) : var.icp_inception_image}"

}

module "icpprovision" {
  source = "github.com/ibm-cloud-architecture/terraform-module-icp-deploy?ref=3.0.7"

  bastion_host = "${azurerm_public_ip.bootnode_pip.ip_address}"

  # Provide IP addresses for boot, master, mgmt, va, proxy and workers
  boot-node = "${element(concat(azurerm_network_interface.boot_nic.*.private_ip_address, list("")), 0)}"

  icp-host-groups = {
    master      = ["${azurerm_network_interface.master_nic.*.private_ip_address}"]
    worker      = ["${azurerm_network_interface.worker_nic.*.private_ip_address}"]
    proxy       = ["${azurerm_network_interface.proxy_nic.*.private_ip_address}"]
    #management  = ["${azurerm_network_interface.management_nic.*.private_ip_address}"]
    management  = "${slice(
      concat(azurerm_network_interface.management_nic.*.private_ip_address, azurerm_network_interface.master_nic.*.private_ip_address),
      0, var.management["nodes"] > 0 ? length(azurerm_network_interface.management_nic.*.private_ip_address) : length(azurerm_network_interface.master_nic.*.private_ip_address))}"
  }

  icp-inception = "${local.inception_image}"

  # Workaround for terraform issue #10857
  # When this is fixed, we can work this out autmatically

  cluster_size  = "${var.boot["nodes"] + var.master["nodes"] + var.worker["nodes"] + var.proxy["nodes"] + var.management["nodes"]}"

  icp_configuration = {
    "network_cidr"              = "${var.network_cidr}"
    "service_cluster_ip_range"  = "${var.cluster_ip_range}"
    "ansible_user"              = "icpdeploy"
    "ansible_become"            = "true"
    "cluster_lb_address"        = "${azurerm_public_ip.master_pip.fqdn}"
    "proxy_lb_address"          = "${azurerm_public_ip.master_pip.fqdn}"
    "cluster_CA_domain"         = "${azurerm_public_ip.master_pip.fqdn}"
    "cluster_name"              = "${var.cluster_name}"

    "private_registry_enabled"  = "${var.private_registry != "" ? "true" : "false"}"
    # "private_registry_server"   = "${var.private_registry}"
    "image_repo"                = "${var.private_registry != "" ? "${var.private_registry}/${dirname(var.icp_inception_image)}" : ""}"
    "docker_username"           = "${var.registry_username}"
    "docker_password"           = "${var.registry_password}"

    # An admin password will be generated if not supplied in terraform.tfvars
    "default_admin_password"    = "${var.icpadmin_password}"
    # This is the list of disabled management services
    "management_services"       = "${local.disabled_management_services}"


    "calico_ip_autodetection_method" = "first-found"
    "kubelet_nodename"          = "nodename"
    "cloud_provider"            = "azure"

    # Azure specific arguments
    "kube_controller_manager_extra_args" = ["--allocate-node-cidrs=true", "--feature-gates=ServiceNodeExclusion=true"]
    "kubelet_extra_args" = ["--enable-controller-attach-detach=true"]

    # Azure specific configurations
    # We don't need ip in ip with Azure networking
    "calico_ipip_enabled"       = "false"
    # Settings for patched icp-inception
    "calico_networking_backend"  = "none"
    "calico_ipam_type"           = "host-local"
    "calico_ipam_subnet"         = "usePodCidr"
    # Try this later: "calico_cluster_type" = "k8s"
    "etcd_extra_args"             = [
      "--grpc-keepalive-timeout=0",
      "--grpc-keepalive-interval=0",
      "--snapshot-count=10000",
      "--heartbeat-interval=250",
      "--election-timeout=1250"
    ]
    "azure"                  = {

      "cloud_provider_conf" = {
          "cloud"               = "AzurePublicCloud"
          "useInstanceMetadata" = "true"
          "tenantId"            = "${data.azurerm_client_config.client_config.tenant_id}"
          "subscriptionId"      = "${data.azurerm_client_config.client_config.subscription_id}"
          "resourceGroup"       = "${azurerm_resource_group.icp.name}"
          "useManagedIdentityExtension" = "true"
      }

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
          "vnetName"            = "${azurerm_virtual_network.icp_vnet.name}"
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
    "dummy_waitfor" = "${length(concat(azurerm_virtual_machine.boot.*.id, azurerm_virtual_machine.master.*.id, azurerm_virtual_machine.worker.*.id, azurerm_virtual_machine.management.*.id))}"
  }

  generate_key = true

  ssh_user         = "icpdeploy"
  ssh_key_base64   = "${base64encode(tls_private_key.installkey.private_key_pem)}"

}
