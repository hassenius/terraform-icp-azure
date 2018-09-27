##################################
## This module handles all the ICP confifguration
## and prerequisites setup
##################################

# TODO: Add azure-disk and azure-file volumes
# TODO: Separate vmadmin key and icpdeploy key

# data "template_file" "azure_provider_config" {
#   template = "${file("azure-config.json.tpl")}"
#
# }

data "azurerm_client_config" "client_config" {}

module "icpprovision" {
  source = "github.com/ibm-cloud-architecture/terraform-module-icp-deploy?ref=2.3.4"

  bastion_host = "${azurerm_public_ip.master_pip.0.ip_address}"

  # Provide IP addresses for boot, master, mgmt, va, proxy and workers
  boot-node = "${element(azurerm_network_interface.master_nic.*.private_ip_address, 0)}"

  icp-host-groups = {
    master      = ["${azurerm_network_interface.master_nic.*.private_ip_address}"]
    worker      = ["${azurerm_network_interface.worker_nic.*.private_ip_address}"]
    proxy       = ["${azurerm_network_interface.proxy_nic.*.private_ip_address}"]
    management  = ["${azurerm_network_interface.management_nic.*.private_ip_address}"]
  }

  icp-version = "${var.icp_version}"

  # Workaround for terraform issue #10857
  # When this is fixed, we can work this out autmatically

  cluster_size  = "${var.master["nodes"] + var.worker["nodes"] + var.proxy["nodes"] + var.management["nodes"]}"

  icp_configuration = {
    "network_cidr"              = "${var.network_cidr}"
    "service_cluster_ip_range"  = "${var.cluster_ip_range}"
    "ansible_user"              = "icpdeploy"
    "ansible_become"            = "true"
    "default_admin_password"    = "${var.icpadmin_password}"
    "cluster_access_ip"         = "${element(azurerm_public_ip.master_pip.*.ip_address, 0)}"
    "proxy_access_ip"           = "${element(azurerm_public_ip.proxy_pip.*.ip_address, 0)}"

    #

    "calico_ip_autodetection_method" = "can-reach=${azurerm_network_interface.master_nic.0.private_ip_address}"
    "kubelet_nodename"          = "nodename"
    "cloud_provider"            = "azure"

    # If you want to use calico in policy only mode and Azure routed routes.
    "kube_controller_manager_extra_args" = ["--allocate-node-cidrs=true"]
    "kubelet_extra_args" = ["--enable-controller-attach-detach=true"]

    # Azure specific configurations
    # We don't need ip in ip with Azure networking
    "calico_ipip_enabled"       = "false"
    # Settings for patched icp-inception
    "calico_networking_backend"  = "none"
    "calico_ipam_type"           = "host-local"
    "calico_ipam_subnet"         = "usePodCidr"
    # Try this later: "calico_cluster_type" = "k8s"

    "azure_conf"                  = {
      # Common authantication details for both kubelet and controller manager
      "auth" = {
          "cloud"               = "AzurePublicCloud"
          "useInstanceMetadata" = "true"
          "tenantId"            = "${data.azurerm_client_config.client_config.tenant_id}"
          "subscriptionId"      = "${data.azurerm_client_config.client_config.subscription_id}"
          "resourceGroup"       = "${azurerm_resource_group.icp.name}"
      }
      # Authentication information for kubelet
      "kubelet_auth" = {
          "useManagedIdentityExtension" = "true"
      }
      # Authentication information specific for controller
      ## Controller will need additional permissions as it needs to create routes in the router table,
      ## interact with storage and networking resources
      "controller_auth" = {
          "aadClientId"     = "${var.aadClientId}"
          "aadClientSecret" = "${var.aadClientSecret}"
      }
      # Cluster configuration for controller manager
      "cluster_conf" = {
          "location"      = "${azurerm_resource_group.icp.location}"
          "subnetName"    = "${azurerm_subnet.container_subnet.name}"
          "securityGroupName" = "" # used to be myicp-master-sg by try empty
          "vnetName"      = "${azurerm_virtual_network.icp_vnet.name}"
          "vnetResourceGroup" = "${azurerm_resource_group.icp.name}"
          "routeTableName" = "${azurerm_route_table.routetb.name}"
          "cloudProviderBackoff" = "false"
      }
    }
  }


  # Attempt for patched icp-inception
  hooks = {
    "boot-preconfig" = [
      "cd /tmp ; wget https://raw.githubusercontent.com/ibm-cloud-architecture/terraform-module-icp-deploy/master/scripts/boot-master/install-docker.sh",
      "chmod a+x /tmp/install-docker.sh ; /tmp/install-docker.sh",
      "git clone https://github.com/hassenius/icp-azure-patch.git",
      "cd /tmp/icp-azure-patch ; git checkout icp31-ce ",
      "sudo docker build -t ibmcom/icp-inception:3.1.0-azure ."
    ]
    "postinstall" = [
      "echo Here we will load some storage stuff"
    ]
  }

  generate_key = true

  ssh_user         = "icpdeploy"
  ssh_key_base64   = "${base64encode(tls_private_key.installkey.private_key_pem)}"

}
