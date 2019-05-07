output "resource_group" {
  value = "${azurerm_resource_group.icp.name}"
}

output "icp_console_url" {
  value = "https://${element(azurerm_public_ip.master_pip.*.fqdn, 0)}:8443"
}

output "icp_console_server" {
  value = "${element(azurerm_public_ip.master_pip.*.fqdn, 0)}"
}

output "icp_proxy" {
  value = "${element(azurerm_public_ip.proxy_pip.*.fqdn, 0)}"
}

output "kubernetes_api_url" {
  value = "https://${element(azurerm_public_ip.master_pip.*.fqdn, 0)}:8001"
}

output "icp_admin_username" {
  value = "admin"
}
