resource "azurerm_network_interface" "rancher-server-nic" {
  name                = "rancher-server-nic"
  location            = "Central US"
  resource_group_name = "${var.RESOURCE_GROUP_TEST_NAME}"

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${var.SUBNET_TEST_ID}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.rancher-server-ip.id}"
  }
}

resource "azurerm_public_ip" "rancher-server-ip" {
  name                         = "rancher-server-ip"
  location                     = "Central US"
  resource_group_name          = "${var.RESOURCE_GROUP_TEST_NAME}"
  public_ip_address_allocation = "static"
}

resource "azurerm_virtual_machine" "rancher-server" {
  name                  = "rancher-server"
  location              = "Central US"
  resource_group_name   = "${var.RESOURCE_GROUP_TEST_NAME}"
  network_interface_ids = ["${azurerm_network_interface.rancher-server-nic.id}"]
  vm_size               = "${var.RANCHER_SERVER_MACHINE_SIZE}"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "myosdisk-rancher-server"
    caching       = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option = "FromImage"
    os_type       = "linux"
    disk_size_gb  = 300
  }

  os_profile {
    computer_name  = "rancher-server"
    admin_username = "lyearn"
    admin_password = "Welcome!23456"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled     = false
    storage_uri = "${var.STORAGE_ACCOUNT_PRIMARY_BLOB_ENDPOINT}"
  }

}

# resource "azurerm_virtual_machine_extension" "docker-ext-rancher-server" {
#   name                 = "DockerExtension"
#   location             = "Central US"
#   resource_group_name  = "${var.RESOURCE_GROUP_TEST_NAME}"
#   virtual_machine_name = "${azurerm_virtual_machine.rancher-server.name}"
#   publisher            = "Microsoft.Azure.Extensions"
#   type                 = "DockerExtension"
#   type_handler_version = "1.1"

#   settings = <<SETTINGS
#     {}
# SETTINGS
  
   
# }

resource "azurerm_virtual_machine_extension" "custom-script-rancher-server" {
  name                 = "CustomScriptForLinux"
  location             = "Central US"
  resource_group_name  = "${var.RESOURCE_GROUP_TEST_NAME}"
  virtual_machine_name = "${azurerm_virtual_machine.rancher-server.name}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "sh rancher-server-start.sh",
        "fileUris" : [
          "https://raw.githubusercontent.com/Lyearn/ARM_templates/master/rancher-server-scripts/rancher-server-start.sh?token=AJu2kaiD8oXlVEolRkkPi0u8XGQWaexMks5ZZeOWwA%3D%3D"
        ]
    }
SETTINGS

  #  depends_on         = ["azurerm_virtual_machine_extension.docker-ext-rancher-server"]
}

output "custom-script-success-confirmation" {
  value = "${azurerm_virtual_machine_extension.custom-script-rancher-server.id}"
  depends_on = ["${azurerm_virtual_machine_extension.custom-script-rancher-server}"]
}

output "rancher-server-ip" {
  value = "${azurerm_public_ip.rancher-server-ip.ip_address}"
}