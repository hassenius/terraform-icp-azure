##################################
## This module handles all the ICP confifguration
## and prerequisites setup
##################################

module "icpprovision" {
  source = "github.com/ibm-cloud-architecture/terraform-module-icp-deploy?ref=2.3.3"

  bastion_host = "${azurerm_public_ip.master_pip.0.ip_address}"

  # Provide IP addresses for boot, master, mgmt, va, proxy and workers
  boot-node = "${azurerm_public_ip.master_pip.0.ip_address}"

  icp-host-groups = {
    master      = ["${azurerm_network_interface.master_nic.*.private_ip_address}"]
    worker      = ["${azurerm_network_interface.worker_nic.*.private_ip_address}"]
    proxy       = ["${azurerm_network_interface.master_nic.*.private_ip_address}"]
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
    "proxy_access_ip"           = "${element(azurerm_public_ip.master_pip.*.ip_address, 0)}"
    "calico_ip_autodetection_method" = "can-reach=${azurerm_network_interface.master_nic.0.private_ip_address}"
  }

  generate_key = true

  ssh_user  = "icpdeploy"
  ssh_key   = "${tls_private_key.installkey.private_key_pem}"

}
