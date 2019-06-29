resource "azurerm_network_interface" "host-nics" {
  count               = "${var.RANCHER_HOST_COUNT}"
  name                = "host-${count.index}-nic"
  location            = "Central US"
  resource_group_name = "${var.RESOURCE_GROUP_TEST_NAME}"

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${var.SUBNET_TEST_ID}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.host-ips.*.id, count.index)}"
  }
}

resource "azurerm_public_ip" "host-ips" {
  count                        = "${var.RANCHER_HOST_COUNT}"
  name                         = "host-${count.index}-ip"
  location                     = "Central US"
  resource_group_name          = "${var.RESOURCE_GROUP_TEST_NAME}"
  public_ip_address_allocation = "dynamic"
}

resource "azurerm_virtual_machine" "host-machines" {
  count                 = "${var.RANCHER_HOST_COUNT}"
  name                  = "host-${count.index}"
  location              = "Central US"
  resource_group_name   = "${var.RESOURCE_GROUP_TEST_NAME}"
  network_interface_ids = ["${element(azurerm_network_interface.host-nics.*.id, count.index)}"]
  vm_size               = "Standard_D3_V2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "host-${count.index}-os-disk"
    caching       = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option = "FromImage"
    os_type       = "linux"
    disk_size_gb  = 300
  }

  os_profile {
    computer_name  = "host-${count.index}"
    admin_username = "lyearn"
    admin_password = "Welcome!23456"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  /*boot_diagnostics {
    enabled     = true
    storage_uri = "${azurerm_storage_account.terrastorageaccnt.primary_blob_endpoint}"
  }*/

}

resource "azurerm_virtual_machine_extension" "custom-scripts-for-hosts" {
  count                = "${var.RANCHER_HOST_COUNT}"
  name                 = "CustomScriptForLinux"
  location             = "Central US"
  resource_group_name  = "${var.RESOURCE_GROUP_TEST_NAME}"
  virtual_machine_name = "${element(azurerm_virtual_machine.host-machines.*.name, count.index)}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "sudo sh rancher-host-start.sh ${var.RANCHER_SERVER_IP}",
        "fileUris" : [
          "https://raw.githubusercontent.com/Lyearn/ARM_templates/master/rancher-hosts-scripts/rancher-host-start.sh?token=AJu2kYXgx85DfsgNjm0JyWV0AexdIGE2ks5ZZeN1wA%3D%3D"
        ]
    }
SETTINGS

  #  depends_on         = ["${null_resource.dummy-dependency}"]
  tags {
    dependency_id = "${var.CUSTOM_SCRIPT_SUCCESS_CONFIRMATION}"
  }
}