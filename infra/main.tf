resource "azurerm_resource_group" "upscaling" {
  name     = "rg-upscaling"
  location = var.location_resource 
}

resource "azurerm_network_security_group" "vnet_upscaling_sg" {
    name                = "nsg-upscaling"
    location            = var.location_resource
    resource_group_name = azurerm_resource_group.upscaling.name

    security_rule = {
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
  

  subnet = {
    name = "subnet-upscaling"
    adress_prefix = ["10.0.1.0/28"]
    security_group = azurerm_network_security_group.vnet_upscaling_sg.id
  }

}

