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
}

resource "azurerm_subnet" "subnet_upscaling" {
  name                 = "subnet-upscaling"
  resource_group_name  = azurerm_resource_group.upscaling.name
  virtual_network_name = azurerm_virtual_network.vnet_upscaling.name
  address_prefixes     = ["10.0.1.0/28"]
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
    subnet_id                 = azurerm_subnet.subnet_upscaling.id
    network_security_group_id = azurerm_network_security_group.vnet_upscaling_sg.id
}

resource "azurerm_public_ip" "public_ip_upscaling_vm" {
    name                = "pip-upscaling-vm"
    location            = var.location_resource
    resource_group_name = azurerm_resource_group.upscaling.name
    allocation_method   = "Static"
}

resource "azurerm_network_interface" "vm_nic" {
    name                = "nic-upscaling"
    location            = var.location_resource
    resource_group_name = azurerm_resource_group.upscaling.name
    
    ip_configuration {
        name                          = "internal-ip-nic-upscaling"
        subnet_id                     = azurerm_subnet.subnet_upscaling.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.public_ip_upscaling_vm.id
    }
  
}

resource "azurerm_linux_virtual_machine" "front-back-app" {
  name                = "vm-upscaling"
  resource_group_name = azurerm_resource_group.upscaling.name
  location            = var.location_resource
  size                = "Standard_B1ls"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.vm_nic.id
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


resource "azurerm_storage_account" "upscaling_storage" {
  name                     = "upscalingstorageacc"
  resource_group_name      = azurerm_resource_group.upscaling.name
  location                 = var.location_resource
  account_tier             = "Standard"
  account_replication_type = "LRS"

  network_rules {
    default_action = "Allow"
    ip_rules = ["0.0.0.0/0"]
    virtual_network_subnet_ids = azurerm_subnet.subnet_upscaling.id
  }
  
}

resource "azurerm_storage_container" "image_upload_upscaling" {
  name                  = "container-image-upload"
  storage_account_name  = azurerm_storage_account.upscaling_storage.name
  container_access_type = "blob"
}

resource "azurerm_storage_container" "image_return_upscaled" {
  name                  = "container-image-return"
  storage_account_name  = azurerm_storage_account.upscaling_storage.name
  container_access_type = "private"
}

resource "azurerm_service_plan" "function_app_plan" {
  name                = "plan-function-upscaling"
  location            = var.location_resource
  resource_group_name = azurerm_resource_group.upscaling.name
  os_type             = "Windows"
  sku_name            = "F1"

}


resource "azurerm_windows_function_app" "function_comunicate" {
  name = "func-upscaling-app"
  resource_group_name = azurerm_resource_group.upscaling.name
  location = var.location_resource

  storage_account_name = azurerm_storage_account.upscaling_storage.name
  storage_account_access_key = azurerm_storage_account.upscaling_storage.primary_access_key
  service_plan_id = azurerm_service_plan.function_app_plan.id

  site_config {
    application_stack {
      dotnet_version = "v8"
    }

    ## ip_restriction {
    ##   name       = "Allow vm"
    ##   action     = "Allow"
    ## ip_address = "${azurerm_linux_virtual_machine.front-back-app.private_ip_address}"
    ##  } 
        ## NÃO É POSSÍVEL RESTRINGIR PELO IP DEVIDO AO SERVICE PLAN SER GRATUITO (F1)
  }
}

resource "azurerm_eventgrid_system_topic" "system_topic" {
  name                = "eg-system-topic-upscaling"
  resource_group_name = azurerm_resource_group.upscaling.name
  location            = var.location_resource
  topic_type         = "Microsoft.Storage.Containers"
  source_arm_resource_id = azurerm_storage_container.image_upload_upscaling.id
}

resource "azurerm_eventgrid_system_topic_event_subscription" "trigger_system_topic_blobstorage" {
  name = "eg-subscription-trigger-upscaling"
  resource_group_name = azurerm_resource_group.upscaling.name
  system_topic = azurerm_eventgrid_system_topic.system_topic.id

   azure_function_endpoint {
    function_id = azurerm_windows_function_app.function_comunicate.id
  }

  included_event_types = [
    "Microsoft.Storage.BlobCreated"
  ]
}

resource "azurerm_signalr_service" "signalR" {
  name = "signalr-upscaling"
  location = var.location_resource
  resource_group_name = azurerm_resource_group.upscaling.name
  sku {
    name     = "Free_F1"
    capacity = 1
  }


  cors {
    allowed_origins = ["http://${azurerm_public_ip.public_ip_upscaling_vm.ip_address}", 
    "https://${azurerm_public_ip.public_ip_upscaling_vm.ip_address}"]
  }

  connectivity_logs_enabled = true
  messaging_logs_enabled = true
  service_mode = "Default"

}
