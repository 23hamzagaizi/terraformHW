terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id   = "0eea535e-a7c0-4758-bffc-aa9ca2da6765"
  tenant_id         = "5aa79040-afd4-4978-a730-7a278afe0dd2"
  client_id         = "4f41e532-263d-44a7-9b3b-85f1d32c7290"
  client_secret     = "jdg8Q~WxEqjAIOiYaf_O2rjFZs~2S8TUwp7XHaC1"
}


resource "azurerm_resource_group" "rg" {
    name = "myRG-SYKH"  
    location = "westus2"
}

resource "azurerm_virtual_network" "Vnet" {
  name                = "myVNet_SYKH"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "AGSubnet" {
  name                 = "myAGSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.Vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "BackendSubnet" {
  name                 = "myBackendSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.Vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "publicip" {
  name                = "myAGPublicIPAddress"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_application_gateway" "AppGateway" {
  name                = "myAppGateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "myGatewayIPConfiguration"
    subnet_id = azurerm_subnet.AGSubnet.id
  }

  frontend_ip_configuration {
    name                 = "PublicIP"
    public_ip_address_id = azurerm_public_ip.publicip.id
  }

  frontend_port {
    name = "FrontendPort"
    port = 80
  }

  http_listener {
    name                           = "HttpListener"
    frontend_ip_configuration_name = "PublicIP"
    frontend_port_name             = "FrontendPort"
    protocol                       = "Http"
  }

  backend_address_pool {
    name = "BackendPool"
  }

  backend_http_settings {
    name                  = "HttpSettings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  request_routing_rule {
    name                       = "RoutingRule"
    rule_type                  = "Basic"
    http_listener_name         = "HttpListener"
    backend_address_pool_name  = "BackendPool"
    backend_http_settings_name = "HttpSettings"
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Detection"
    rule_set_version = "3.1"
  }
}

resource "azurerm_network_interface" "interface1" {
  name                = "NIC1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.BackendSubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "interface2" {
  name                = "NIC2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.BackendSubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "VM1" {
  name                = "myVM1-SYKH"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [azurerm_network_interface.interface1.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("C:\\Users\\hamza\\terraform\\.ssh\\id_rsa.pub")
  }
}

resource "azurerm_linux_virtual_machine" "VM2" {
  name                = "myVM2-SYKH"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [azurerm_network_interface.interface2.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("C:\\Users\\hamza\\terraform\\.ssh\\id_rsa.pub")
  }
}