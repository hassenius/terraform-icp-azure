
##################################
## Create Availability Sets
##################################


resource "azurerm_availability_set" "controlplane" {
  name                = "controlpane_availabilityset"
  location            = "${azurerm_resource_group.icp.location}"
  resource_group_name = "${azurerm_resource_group.icp.name}"
  managed             = true

  tags {
    environment = "Production"
  }
}

resource "azurerm_availability_set" "management" {
  name                = "management_availabilityset"
  location            = "${azurerm_resource_group.icp.location}"
  resource_group_name = "${azurerm_resource_group.icp.name}"
  managed             = true

  tags {
    environment = "Production"
  }
}

resource "azurerm_availability_set" "proxy" {
  name                = "proxy_availabilityset"
  location            = "${azurerm_resource_group.icp.location}"
  resource_group_name = "${azurerm_resource_group.icp.name}"
  managed             = true

  tags {
    environment = "Production"
  }
}
#
#
resource "azurerm_availability_set" "workers" {
  name                = "workers_availabilityset"
  location            = "${azurerm_resource_group.icp.location}"
  resource_group_name = "${azurerm_resource_group.icp.name}"
  managed             = true

  tags {
    environment = "Production"
  }
}

##################################
## Create Boot VM
##################################
resource "azurerm_virtual_machine" "boot" {
  count                 = "${var.boot["nodes"]}"
  name                  = "${var.boot["name"]}${count.index + 1}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.icp.name}"
  vm_size               = "${var.boot["vm_size"]}"
  network_interface_ids = ["${element(azurerm_network_interface.boot_nic.*.id, count.index)}"]

  # The SystemAssigned identity enables the Azure Cloud Provider to use ManagedIdentityExtension
  identity = {
    type = "SystemAssigned"
  }


  storage_image_reference {
    publisher = "${lookup(var.os_image_map, join("_publisher", list(var.os_image, "")))}"
    offer     = "${lookup(var.os_image_map, join("_offer", list(var.os_image, "")))}"
    sku       = "${lookup(var.os_image_map, join("_sku", list(var.os_image, "")))}"
    version   = "${lookup(var.os_image_map, join("_version", list(var.os_image, "")))}"
  }

  storage_os_disk {
    name              = "${var.boot["name"]}-osdisk-${count.index + 1}"
    managed_disk_type = "${var.boot["os_disk_type"]}"
    disk_size_gb      = "${var.boot["os_disk_size"]}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  storage_data_disk {
    name              = "${var.boot["name"]}-dockerdisk-${count.index + 1}"
    managed_disk_type = "${var.boot["docker_disk_type"]}"
    disk_size_gb      = "${var.boot["docker_disk_size"]}"
    caching           = "ReadWrite"
    create_option     = "Empty"
    lun               = 1
  }

  os_profile {
    computer_name  = "${var.boot["name"]}${count.index + 1}"
    admin_username = "${var.admin_username}"
    custom_data    = "${data.template_cloudinit_config.bootconfig.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = "${var.disable_password_authentication}"
    ssh_keys {
      key_data = "${var.ssh_public_key}"
      path = "/home/${var.admin_username}/.ssh/authorized_keys"
    }
  }
}


##################################
## Create Master VM
##################################
resource "azurerm_virtual_machine" "master" {
  count                 = "${var.master["nodes"]}"
  name                  = "${var.master["name"]}${count.index + 1}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.icp.name}"
  vm_size               = "${var.master["vm_size"]}"
  network_interface_ids = ["${element(azurerm_network_interface.master_nic.*.id, count.index)}"]

  # The SystemAssigned identity enables the Azure Cloud Provider to use ManagedIdentityExtension
  identity = {
    type = "SystemAssigned"
  }

  availability_set_id = "${azurerm_availability_set.controlplane.id}"
  #zones               = ["${count.index % var.zones + 1}"]

  storage_image_reference {
    publisher = "${lookup(var.os_image_map, join("_publisher", list(var.os_image, "")))}"
    offer     = "${lookup(var.os_image_map, join("_offer", list(var.os_image, "")))}"
    sku       = "${lookup(var.os_image_map, join("_sku", list(var.os_image, "")))}"
    version   = "${lookup(var.os_image_map, join("_version", list(var.os_image, "")))}"
  }

  storage_os_disk {
    name              = "${var.master["name"]}-osdisk-${count.index + 1}"
    managed_disk_type = "${var.master["os_disk_type"]}"
    disk_size_gb      = "${var.master["docker_disk_size"]}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  # Docker disk
  storage_data_disk {
    name              = "${var.master["name"]}-dockerdisk-${count.index + 1}"
    managed_disk_type = "${var.master["docker_disk_type"]}"
    disk_size_gb      = "${var.master["docker_disk_size"]}"
    caching           = "ReadWrite"
    create_option     = "Empty"
    lun               = 1
  }

  # ETCD Data disk
  storage_data_disk {
    name              = "${var.master["name"]}-etcddata-${count.index + 1}"
    managed_disk_type = "${var.master["etcd_data_type"]}"
    disk_size_gb      = "${var.master["etcd_data_size"]}"
    caching           = "ReadWrite"
    create_option     = "Empty"
    lun               = 2
  }

  # ETCD WAL disk
  storage_data_disk {
    name              = "${var.master["name"]}-etcdwal-${count.index + 1}"
    managed_disk_type = "${var.master["etcd_wal_type"]}"
    disk_size_gb      = "${var.master["etcd_wal_size"]}"
    caching           = "ReadWrite"
    create_option     = "Empty"
    lun               = 3
  }

  os_profile {
    computer_name  = "${var.master["name"]}${count.index + 1}"
    admin_username = "${var.admin_username}"
    custom_data    = "${data.template_cloudinit_config.masterconfig.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = "${var.disable_password_authentication}"
    ssh_keys {
      key_data = "${var.ssh_public_key}"
      path = "/home/${var.admin_username}/.ssh/authorized_keys"
    }
  }
}


##################################
## Create Proxy VM
##################################
resource "azurerm_virtual_machine" "proxy" {
  count                 = "${var.proxy["nodes"]}"
  name                  = "${var.proxy["name"]}${count.index + 1}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.icp.name}"
  vm_size               = "${var.proxy["vm_size"]}"
  network_interface_ids = ["${element(azurerm_network_interface.proxy_nic.*.id, count.index)}"]

  # The SystemAssigned identity enables the Azure Cloud Provider to use ManagedIdentityExtension
  identity = {
    type = "SystemAssigned"
  }

  availability_set_id = "${azurerm_availability_set.proxy.id}"
  # zones               = ["${count.index % var.zones + 1}"]

  storage_image_reference {
    publisher = "${lookup(var.os_image_map, join("_publisher", list(var.os_image, "")))}"
    offer     = "${lookup(var.os_image_map, join("_offer", list(var.os_image, "")))}"
    sku       = "${lookup(var.os_image_map, join("_sku", list(var.os_image, "")))}"
    version   = "${lookup(var.os_image_map, join("_version", list(var.os_image, "")))}"
  }

  storage_os_disk {
    name              = "${var.proxy["name"]}-osdisk-${count.index + 1}"
    managed_disk_type = "${var.proxy["os_disk_type"]}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  storage_data_disk {
    name              = "${var.proxy["name"]}-dockerdisk-${count.index + 1}"
    managed_disk_type = "${var.proxy["docker_disk_type"]}"
    disk_size_gb      = "${var.proxy["docker_disk_size"]}"
    caching           = "ReadWrite"
    create_option     = "Empty"
    lun               = 1
  }

  os_profile {
    computer_name  = "${var.proxy["name"]}${count.index + 1}"
    admin_username = "${var.admin_username}"
    custom_data    = "${data.template_cloudinit_config.workerconfig.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = "${var.disable_password_authentication}"
    ssh_keys {
      key_data = "${var.ssh_public_key}"
      path = "/home/${var.admin_username}/.ssh/authorized_keys"
    }
  }
}

##################################
## Create Management VM
##################################
resource "azurerm_virtual_machine" "management" {
  count                 = "${var.management["nodes"]}"
  name                  = "${var.management["name"]}${count.index + 1}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.icp.name}"
  vm_size               = "${var.management["vm_size"]}"
  network_interface_ids = ["${element(azurerm_network_interface.management_nic.*.id, count.index)}"]

  # The SystemAssigned identity enables the Azure Cloud Provider to use ManagedIdentityExtension
  identity = {
    type = "SystemAssigned"
  }

  availability_set_id = "${azurerm_availability_set.management.id}"
  # zones               = ["${count.index % var.zones + 1}"]

  storage_image_reference {
    publisher = "${lookup(var.os_image_map, join("_publisher", list(var.os_image, "")))}"
    offer     = "${lookup(var.os_image_map, join("_offer", list(var.os_image, "")))}"
    sku       = "${lookup(var.os_image_map, join("_sku", list(var.os_image, "")))}"
    version   = "${lookup(var.os_image_map, join("_version", list(var.os_image, "")))}"
  }

  storage_os_disk {
    name              = "${var.management["name"]}-osdisk-${count.index + 1}"
    managed_disk_type = "${var.management["os_disk_type"]}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  storage_data_disk {
    name              = "${var.management["name"]}-dockerdisk-${count.index + 1}"
    managed_disk_type = "${var.management["docker_disk_type"]}"
    disk_size_gb      = "${var.management["docker_disk_size"]}"
    caching           = "ReadWrite"
    create_option     = "Empty"
    lun               = 1
  }

  os_profile {
    computer_name  = "${var.management["name"]}${count.index + 1}"
    admin_username = "${var.admin_username}"
    custom_data    = "${data.template_cloudinit_config.workerconfig.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = "${var.disable_password_authentication}"
    ssh_keys {
      key_data = "${var.ssh_public_key}"
      path = "/home/${var.admin_username}/.ssh/authorized_keys"
    }
  }
}


##################################
## Create Worker VM
##################################
resource "azurerm_virtual_machine" "worker" {
  count                 = "${var.worker["nodes"]}"
  name                  = "${var.worker["name"]}${count.index + 1}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.icp.name}"
  vm_size               = "${var.worker["vm_size"]}"
  network_interface_ids = ["${element(azurerm_network_interface.worker_nic.*.id, count.index)}"]

  # The SystemAssigned identity enables the Azure Cloud Provider to use ManagedIdentityExtension
  identity = {
    type = "SystemAssigned"
  }

  availability_set_id = "${azurerm_availability_set.workers.id}"
  # zones               = ["${count.index % var.zones + 1}"]

  storage_image_reference {
    publisher = "${lookup(var.os_image_map, join("_publisher", list(var.os_image, "")))}"
    offer     = "${lookup(var.os_image_map, join("_offer", list(var.os_image, "")))}"
    sku       = "${lookup(var.os_image_map, join("_sku", list(var.os_image, "")))}"
    version   = "${lookup(var.os_image_map, join("_version", list(var.os_image, "")))}"
  }

  storage_os_disk {
    name              = "${var.worker["name"]}-osdisk-${count.index + 1}"
    managed_disk_type = "${var.worker["os_disk_type"]}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  storage_data_disk {
    name              = "${var.worker["name"]}-dockerdisk-${count.index + 1}"
    managed_disk_type = "${var.worker["docker_disk_type"]}"
    disk_size_gb      = "${var.worker["docker_disk_size"]}"
    caching           = "ReadWrite"
    create_option     = "Empty"
    lun               = 1
  }

  os_profile {
    computer_name  = "${var.worker["name"]}${count.index + 1}"
    admin_username = "${var.admin_username}"
    custom_data    = "${data.template_cloudinit_config.workerconfig.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = "${var.disable_password_authentication}"
    ssh_keys {
      key_data = "${var.ssh_public_key}"
      path = "/home/${var.admin_username}/.ssh/authorized_keys"
    }
  }
}
