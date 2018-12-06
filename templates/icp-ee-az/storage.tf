#########
## Storage account for ICP components
#########
resource "azurerm_storage_account" "infrastructure" {
  name                     = "infrastructure${random_id.clusterid.hex}"
  resource_group_name      = "${azurerm_resource_group.icp.name}"
  location                 = "${var.location}"
  account_tier             = "${var.storage_account_tier}"
  account_replication_type = "${var.storage_replication_type}"

  tags {
    environment = "icp"
  }
}

resource "azurerm_storage_share" "icpregistry" {
  name = "icpregistry"

  resource_group_name  = "${azurerm_resource_group.icp.name}"
  storage_account_name = "${azurerm_storage_account.infrastructure.name}"

}
