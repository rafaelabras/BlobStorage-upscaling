resource "azurerm_resource_group" "upscaling" {
  name     = "rg-upscaling"
  location = var.location_resource 
}

resource "azurerm_network_security_group" "vnet_upscaling_sg" {
    name                = "nsg-upscaling"
    location            = var.location_resource
    resource_group_name = azurerm_resource_group.upscaling.name

    security_rule {
        name                       = "Allow-HTTP"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }


}

resource "azurerm_virtual_network" "vnet_upscaling"{
  name = "vnet-upscaling"
  location = var.location_resource
  resource_group_name = azurerm_resource_group.upscaling.name
  address_space = ["10.0.0.0/26"]
  

  subnet {
    name = "subnet-upscaling"
    address_prefix = "10.0.1.0/28"
    security_group = azurerm_network_security_group.vnet_upscaling_sg.id
  }

}

resource "azurerm_network_interface" "vm_nic" {
    name                = "nic-upscaling"
    location            = var.location_resource
    resource_group_name = azurerm_resource_group.upscaling.name
    
    ip_configuration {
        name                          = "internal-ip-nic-upscaling"
        subnet_id                     = azurerm_virtual_network.vnet_upscaling.subnet[0].id
        private_ip_address_allocation = "Dynamic"
    }
  
}

resource "azurerm_linux_virtual_machine" "front-back-app" {
  name                = "vm-upscaling"
  resource_group_name = azurerm_resource_group.upscaling.name
  location            = var.location_resource
  size                = "Standard_B1ls"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("C:/Users/rafae/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  custom_data = base64encode(file("${path.module}/../shell-scripts/install_nginx.sh"))

  
}

