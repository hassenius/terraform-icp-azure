##################################
## Configure the provider
##################################
# Details about authentication options here: https://www.terraform.io/docs/providers/azurerm

provider "azurerm" { }


##################################
## Create a resource group
##################################
resource "azurerm_resource_group" "icp" {
  name     = "${var.resource_group}"
  location = "${var.location}"

  tags = "${merge(
    var.default_tags, map(
      "Name", "${var.instance_name}"
    )
  )}"
}
##################################
## Create the SSH key terraform will use for installation
##################################
resource "tls_private_key" "installkey" {
  algorithm   = "RSA"
}
