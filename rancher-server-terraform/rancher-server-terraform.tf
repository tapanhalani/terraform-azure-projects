provider "azurerm" {
  subscription_id = "22b0e698-1167-4f4f-8318-c6216cf0bcaa"
  client_id       = "82803899-01fd-4fdf-a938-7e655fc0989d"
  client_secret   = "d+mQQpE9ym2yRY2Ql7D434FzbvuyHdx9DrEIQzhqOS4="
  tenant_id       = "32b8703c-8c4b-4847-b935-9108efbf33ed"
}

resource "azurerm_resource_group" "test" {
  name     = "${var.RESOURCE_GROUP_NAME}"
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

resource "azurerm_storage_account" "terrastorageaccnt" {
  name                = "terrastorageaccnt"
  resource_group_name = "${azurerm_resource_group.test.name}"
  location            = "centralus"
  account_type        = "Standard_LRS"
}

resource "azurerm_storage_container" "vhds" {
  name                  = "vhds"
  resource_group_name   = "${azurerm_resource_group.test.name}"
  storage_account_name  = "${azurerm_storage_account.terrastorageaccnt.name}"
  container_access_type = "private"
}





###### config for rancher-server #############


module "rancher-server" {
  source = "./modules/rancher-server"
  RANCHER_SERVER_MACHINE_SIZE = "${var.RANCHER_SERVER_MACHINE_SIZE}"
  RESOURCE_GROUP_TEST_NAME = "${azurerm_resource_group.test.name}"
  SUBNET_TEST_ID = "${azurerm_subnet.test.id}"
  STORAGE_ACCOUNT_PRIMARY_BLOB_ENDPOINT = "${azurerm_storage_account.terrastorageaccnt.primary_blob_endpoint}"
}
# resource "azurerm_network_interface" "rancher-server-nic" {
#   name                = "rancher-server-nic"
#   location            = "Central US"
#   resource_group_name = "${azurerm_resource_group.test.name}"

#   ip_configuration {
#     name                          = "testconfiguration1"
#     subnet_id                     = "${azurerm_subnet.test.id}"
#     private_ip_address_allocation = "dynamic"
#     public_ip_address_id          = "${azurerm_public_ip.rancher-server-ip.id}"
#   }
# }

# resource "azurerm_public_ip" "rancher-server-ip" {
#   name                         = "rancher-server-ip"
#   location                     = "Central US"
#   resource_group_name          = "${azurerm_resource_group.test.name}"
#   public_ip_address_allocation = "static"
# }

# resource "azurerm_virtual_machine" "rancher-server" {
#   name                  = "rancher-server"
#   location              = "Central US"
#   resource_group_name   = "${azurerm_resource_group.test.name}"
#   network_interface_ids = ["${azurerm_network_interface.rancher-server-nic.id}"]
#   vm_size               = "Standard_DS2_v2_Promo"

#   storage_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "16.04-LTS"
#     version   = "latest"
#   }

#   storage_os_disk {
#     name          = "myosdisk-rancher-server"
#     caching       = "ReadWrite"
#     managed_disk_type = "Standard_LRS"
#     create_option = "FromImage"
#     os_type       = "linux"
#     disk_size_gb  = 300
#   }

#   os_profile {
#     computer_name  = "rancher-server"
#     admin_username = "lyearn"
#     admin_password = "Welcome!23456"
#   }

#   os_profile_linux_config {
#     disable_password_authentication = false
#   }

#   boot_diagnostics {
#     enabled     = false
#     storage_uri = "${azurerm_storage_account.terrastorageaccnt.primary_blob_endpoint}"
#   }

# }

# resource "azurerm_virtual_machine_extension" "docker-ext-rancher-server" {
#   name                 = "DockerExtension"
#   location             = "Central US"
#   resource_group_name  = "${azurerm_resource_group.test.name}"
#   virtual_machine_name = "${azurerm_virtual_machine.rancher-server.name}"
#   publisher            = "Microsoft.Azure.Extensions"
#   type                 = "DockerExtension"
#   type_handler_version = "1.1"

#   settings = <<SETTINGS
#     {}
# SETTINGS
  
   
# }

# resource "azurerm_virtual_machine_extension" "custom-script-rancher-server" {
#   name                 = "CustomScriptForLinux"
#   location             = "Central US"
#   resource_group_name  = "${azurerm_resource_group.test.name}"
#   virtual_machine_name = "${azurerm_virtual_machine.rancher-server.name}"
#   publisher            = "Microsoft.Azure.Extensions"
#   type                 = "CustomScript"
#   type_handler_version = "2.0"

#   settings = <<SETTINGS
#     {
#         "commandToExecute": "sh rancher-server-start.sh",
#         "fileUris" : [
#           "https://raw.githubusercontent.com/Lyearn/ARM_templates/master/rancher-server-scripts/rancher-server-start.sh?token=AJu2kb4S3Qn1y7e95Kz8PvfE-VRiJXGvks5ZU5gqwA%3D%3D"
#         ]
#     }
# SETTINGS

#    depends_on         = ["azurerm_virtual_machine_extension.docker-ext-rancher-server"]
# }





#############  config for host-01 ##########

module "rancher-hosts" {
  source = "./modules/rancher-hosts"
  RANCHER_HOST_COUNT = "${var.RANCHER_HOST_COUNT}"
  SUBNET_TEST_ID = "${azurerm_subnet.test.id}"
  RESOURCE_GROUP_TEST_NAME = "${azurerm_resource_group.test.name}"  
  CUSTOM_SCRIPT_SUCCESS_CONFIRMATION = "${module.rancher-server.custom-script-success-confirmation}"  
  RANCHER_SERVER_IP = "${module.rancher-server.rancher-server-ip}"
}
# resource "azurerm_network_interface" "host-nics" {
#   count               = 3
#   name                = "host-${count.index}-nic"
#   location            = "Central US"
#   resource_group_name = "${azurerm_resource_group.test.name}"

#   ip_configuration {
#     name                          = "testconfiguration1"
#     subnet_id                     = "${azurerm_subnet.test.id}"
#     private_ip_address_allocation = "dynamic"
#     public_ip_address_id          = "${element(azurerm_public_ip.host-ips.*.id, count.index)}"
#   }
# }

# resource "azurerm_public_ip" "host-ips" {
#   count                        = 3
#   name                         = "host-${count.index}-ip"
#   location                     = "Central US"
#   resource_group_name          = "${azurerm_resource_group.test.name}"
#   public_ip_address_allocation = "dynamic"
# }

# resource "azurerm_virtual_machine" "host-machines" {
#   count                 = 3
#   name                  = "host-${count.index}"
#   location              = "Central US"
#   resource_group_name   = "${azurerm_resource_group.test.name}"
#   network_interface_ids = ["${element(azurerm_network_interface.host-nics.*.id, count.index)}"]
#   vm_size               = "Standard_D3_V2"

#   storage_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "16.04-LTS"
#     version   = "latest"
#   }

#   storage_os_disk {
#     name          = "host-${count.index}-os-disk"
#     caching       = "ReadWrite"
#     managed_disk_type = "Standard_LRS"
#     create_option = "FromImage"
#     os_type       = "linux"
#     disk_size_gb  = 300
#   }

#   os_profile {
#     computer_name  = "host-${count.index}"
#     admin_username = "lyearn"
#     admin_password = "Welcome!23456"
#   }

#   os_profile_linux_config {
#     disable_password_authentication = false
#   }

#   /*boot_diagnostics {
#     enabled     = true
#     storage_uri = "${azurerm_storage_account.terrastorageaccnt.primary_blob_endpoint}"
#   }*/

# }

# resource "azurerm_virtual_machine_extension" "custom-scripts-for-hosts" {
#   count                = 3
#   name                 = "CustomScriptForLinux"
#   location             = "Central US"
#   resource_group_name  = "${azurerm_resource_group.test.name}"
#   virtual_machine_name = "${element(azurerm_virtual_machine.host-machines.*.name, count.index)}"
#   publisher            = "Microsoft.Azure.Extensions"
#   type                 = "CustomScript"
#   type_handler_version = "2.0"

#   settings = <<SETTINGS
#     {
#         "commandToExecute": "sudo sh rancher-host-start.sh ${azurerm_public_ip.rancher-server-ip.ip_address}",
#         "fileUris" : [
#           "https://raw.githubusercontent.com/Lyearn/ARM_templates/master/rancher-hosts-scripts/rancher-host-start.sh?token=AJu2kTC1CdKVm8hqDxSgeieYYfiJNzYoks5ZU5hCwA%3D%3D"
#         ]
#     }
# SETTINGS

#    depends_on         = ["azurerm_virtual_machine_extension.custom-script-rancher-server"]
# }









