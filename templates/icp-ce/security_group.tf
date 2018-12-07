#Network Security Group - Master
resource "azurerm_network_security_group" "master_sg" {
  name                = "${var.cluster_name}-${var.master["name"]}-sg"
  location            = "${azurerm_resource_group.icp.location}"
  resource_group_name = "${azurerm_resource_group.icp.name}"

  security_rule {
    name                       = "${var.cluster_name}-${var.master["name"]}-ssh"
    description                = "Allow inbound SSH from all locations"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "${var.cluster_name}-${var.master["name"]}-icp"
    description                = "Allow inbound ICPUI from all locations"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "${var.cluster_name}-${var.master["name"]}-kube"
    description                = "Allow inbound kubectl from all locations"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8001"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "${var.cluster_name}-${var.master["name"]}-registry"
    description                = "Allow inbound docker registry from all locations"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8500"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "${var.cluster_name}-${var.master["name"]}-im"
    description                = "Allow inbound image manager from all locations"
    priority                   = 450
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8600"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "${var.cluster_name}-${var.master["name"]}-monitoring"
    description                = "Allow inbound Monitoring from all locations"
    priority                   = 500
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "4300"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "${var.cluster_name}-${var.proxy["name"]}-nodeport"
    description                = "Allow inbound Nodeport from all locations"
    priority                   = 600
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-32767"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "${var.cluster_name}-${var.master["name"]}-liberty"
    description                = "Allow inbound Liberty from all locations"
    priority                   = 700
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
#Network Security Group - Proxy
resource "azurerm_network_security_group" "proxy_sg" {
  name                = "${var.cluster_name}-${var.proxy["name"]}-sg"
  location            = "${azurerm_resource_group.icp.location}"
  resource_group_name = "${azurerm_resource_group.icp.name}"

  # security_rule {
  #   name                       = "${var.cluster_name}-${var.proxy["name"]}-ssh"
  #   description                = "Allow inbound SSH from all locations"
  #   priority                   = 100
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "22"
  #   source_address_prefix      = "*"
  #   destination_address_prefix = "*"
  # }
  security_rule {
    name                       = "${var.cluster_name}-${var.proxy["name"]}-nodeport"
    description                = "Allow inbound Nodeport from all locations"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-32767"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "${var.cluster_name}-${var.proxy["name"]}-https-ingress"
    description                = "Allow inbound https ingress from all locations"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "${var.cluster_name}-${var.proxy["name"]}-http-ingress"
    description                = "Allow inbound http ingress from all locations"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
#Network Security Group - Management and Worker
resource "azurerm_network_security_group" "worker_sg" {
  name                = "${var.cluster_name}-worker-sg"
  location            = "${azurerm_resource_group.icp.location}"
  resource_group_name = "${azurerm_resource_group.icp.name}"

  # security_rule {
  #   name                       = "${var.cluster_name}-worker-ssh"
  #   description                = "Allow inbound SSH from all locations"
  #   priority                   = 100
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "22"
  #   source_address_prefix      = "*"
  #   destination_address_prefix = "*"
  # }
}

resource "azurerm_network_security_group" "boot_sg" {
  count               = "${var.boot["nodes"]}"
  name                = "${var.cluster_name}-${var.boot["name"]}-sg"
  location            = "${azurerm_resource_group.icp.location}"
  resource_group_name = "${azurerm_resource_group.icp.name}"

  security_rule {
    name                       = "${var.cluster_name}-${var.boot["name"]}-ssh"
    description                = "Allow inbound SSH from all locations"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
