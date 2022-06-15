resource "azurerm_resource_group" "az-rg" {
  name     = var.rg_name
  location = var.location
}

resource "azurerm_virtual_network" "az-vn" {
  name                = "sample-virtual-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.az-rg.location
  resource_group_name = azurerm_resource_group.az-rg.name
}

resource "azurerm_subnet" "az-subnet" {
  name                 = "sample-subnet-vn"
  resource_group_name  = azurerm_resource_group.az-rg.name
  virtual_network_name = azurerm_virtual_network.az-vn.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "az-subnetnsgssociation" {
  subnet_id                 = azurerm_subnet.az-subnet.id
  network_security_group_id = azurerm_network_security_group.az-nsg.id
}

resource "azurerm_public_ip" "vm" {
  name                = "sample-public-ip"
  location            = azurerm_resource_group.az-rg.location
  resource_group_name = azurerm_resource_group.az-rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "az-nsg" {
  name                = "sample-nsg-vn"
  location            = azurerm_resource_group.az-rg.location
  resource_group_name = azurerm_resource_group.az-rg.name
}

resource "azurerm_network_security_rule" "RDPRule" {
  name                        = "RDPRule"
  resource_group_name         = azurerm_resource_group.az-rg.name
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 3389
  source_address_prefix       = "0.0.0.0/0"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.az-nsg.name
}

resource "azurerm_network_security_rule" "MSSQLRule" {
  name                        = "MSSQLRule"
  resource_group_name         = azurerm_resource_group.az-rg.name
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 1433
  source_address_prefix       = "0.0.0.0/0"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.az-nsg.name
}

resource "azurerm_network_interface" "az-nic" {
  name                = "sample-nice-vn"
  location            = azurerm_resource_group.az-rg.location
  resource_group_name = azurerm_resource_group.az-rg.name

  ip_configuration {
    name                          = "exampleconfiguration1"
    subnet_id                     = azurerm_subnet.az-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.az-nic.id
  network_security_group_id = azurerm_network_security_group.az-nsg.id
}

resource "azurerm_virtual_machine" "az-vm" {
  name                  = "sample-vm-mssql"
  location              = azurerm_resource_group.az-rg.location
  resource_group_name   = azurerm_resource_group.az-rg.name
  network_interface_ids = [azurerm_network_interface.az-nice.id]
  vm_size               = "Standard_B2s"

  storage_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "SQL2017-WS2016"
    sku       = "SQLDEV"
    version   = "latest"
  }

  storage_os_disk {
    name              = "samples-OSDisk"
    caching           = "ReadOnly"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile_windows_config {
    computer_name  = "winhost01"
    admin_username = "exampleadmin"
    admin_password = "Password1234!"
  }

}

resource "azurerm_mssql_virtual_machine" "example" {
  virtual_machine_id = azurerm_virtual_machine.az-vm.id
  sql_license_type   = "PAYG"
}
