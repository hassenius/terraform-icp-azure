output "ICP Console URL" {
  value = "https://${element(azurerm_public_ip.master_pip.*.ip_address, 0)}:8443"
}

output "ICP Proxy" {
  value = "${element(azurerm_public_ip.proxy_pip.*.ip_address, 0)}"
}

output "ICP Kubernetes API URL" {
  value = "https://${element(azurerm_public_ip.master_pip.*.ip_address, 0)}:8001"
}

output "ICP Admin Username" {
  value = "admin"
}

output "ICP Admin Password" {
  value = "${local.icppassword}"
}
