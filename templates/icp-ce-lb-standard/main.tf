##################################
## Configure the provider
##################################
# Details about authentication options here: https://www.terraform.io/docs/providers/azurerm

provider "azurerm" { }



##################################
## Create a resource group
##################################
resource "azurerm_resource_group" "icp" {
  name     = "${var.resource_group}_${random_id.clusterid.id}"
  location = "${var.location}"

  tags = "${merge(
    var.default_tags, map(
      "Clusterid", "${random_id.clusterid.hex}",
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

##################################
## Create a random id to uniquely identifying cluster
##################################
resource "random_id" "clusterid" {
  byte_length = 4
}
