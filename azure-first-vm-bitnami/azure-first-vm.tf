provider "azurerm" {
  subscription_id = "22b0e698-1167-4f4f-8318-c6216cf0bcaa"
  client_id       = "82803899-01fd-4fdf-a938-7e655fc0989d"
  client_secret   = "d+mQQpE9ym2yRY2Ql7D434FzbvuyHdx9DrEIQzhqOS4="
  tenant_id       = "32b8703c-8c4b-4847-b935-9108efbf33ed"
}

resource "azurerm_resource_group" "test" {
  name     = "terraform_group_1"
  location = "Central US"
}

resource "azurerm_virtual_network" "test" {
  name                = "terra_vn"
  address_space       = ["10.0.0.0/16"]
  location            = "Central US"
  resource_group_name = "${azurerm_resource_group.test.name}"
}

resource "azurerm_subnet" "test" {
  name                 = "terra_net"
  resource_group_name  = "${azurerm_resource_group.test.name}"
  virtual_network_name = "${azurerm_virtual_network.test.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "test" {
  name                = "terra_ni"
  location            = "Central US"
  resource_group_name = "${azurerm_resource_group.test.name}"

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.test.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.test.id}"
  }
}

resource "azurerm_public_ip" "test" {
  name                         = "terra_ip"
  location                     = "Central US"
  resource_group_name          = "${azurerm_resource_group.test.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_storage_account" "test" {
  name                = "terrastorageaccnt"
  resource_group_name = "${azurerm_resource_group.test.name}"
  location            = "centralus"
  account_type        = "Standard_LRS"
}

/* resource "azurerm_managed_disk" "copy" {
  name = "terra_managed_disk_copy"
  location = "Central US"
  resource_group_name = "${azurerm_resource_group.test.name}"
  storage_account_type = "Standard_LRS"
  create_option = "Copy"
  source_resource_id = "${azurerm_virtual_machine.test.storage_os_disk.429214147.managed_disk_id}"
  disk_size_gb = "30"
} */

resource "azurerm_storage_container" "test" {
  name                  = "vhds"
  resource_group_name   = "${azurerm_resource_group.test.name}"
  storage_account_name  = "${azurerm_storage_account.test.name}"
  container_access_type = "private"
}

resource "azurerm_virtual_machine" "test" {
  name                  = "terravm01"
  location              = "Central US"
  resource_group_name   = "${azurerm_resource_group.test.name}"
  network_interface_ids = ["${azurerm_network_interface.test.id}"]
  vm_size               = "Standard_DS1"

  storage_image_reference {
    publisher = "confluentinc"
    offer     = "confluentplatform"
    sku       = "301"
    version   = "1.0.1"
  }

  storage_os_disk {
    name          = "myosdisk1"
    vhd_uri       = "${azurerm_storage_account.test.primary_blob_endpoint}${azurerm_storage_container.test.name}/myosdisk.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
    os_type       = "linux"
  }

  os_profile {
    computer_name  = "terravm01"
    admin_username = "lyearn"
    admin_password = "Welcome!23456"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = "${azurerm_storage_account.test.primary_blob_endpoint}"
  }

  plan {
    name = "301"
    publisher = "confluentinc"
    product = "confluentplatform"
  }

}