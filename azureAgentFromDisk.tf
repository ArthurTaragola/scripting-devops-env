######### variables ##############

locals{
region = ""
user = ""
password = ""
rgName = "agents-rg"

#disks
rgDisk = "Disk-rg"
diskImage = "finalDisk"
}

##################################

# Configure the Microsoft Azure Provider
provider "azurerm" {
    version = "~>2.0"
    features {}
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "main" {
    name     = local.rgName
    location = local.region
}

resource "azurerm_virtual_network" "main" {
  name                = "network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "outside" {
  name                    = "publicIp"
  resource_group_name     = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
}

resource "azurerm_network_interface" "main" {
  name                = "nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "static"
    private_ip_address            = "10.0.2.10"
    public_ip_address_id          = azurerm_public_ip.outside.id
  }
}

#managed disk to start from
data "azurerm_managed_disk" "source" {
  name = local.diskImage
  resource_group_name = local.rgDisk
}

#copy disk to use
resource "azurerm_managed_disk" "copy" {
  name                 = "usingImage"
  location             = local.region
  resource_group_name  = local.rgName
  storage_account_type = "Standard_LRS"
  create_option        = "Copy"
  source_resource_id   = data.azurerm_managed_disk.source.id
  #wachten tot rg gemaakt is
  depends_on = [ azurerm_resource_group.main ]
}

resource "azurerm_virtual_machine" "main" {
  name                = "Windows-agent"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_F2"
  
  storage_os_disk {
    os_type = "Windows"
    name = "usingImage"
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "Attach"
    managed_disk_id   = azurerm_managed_disk.copy.id
  }

}

output "public_ip_address" {
  value = azurerm_public_ip.outside.*.ip_address
}

#full automate
resource "null_resource" "startScript" {
  provisioner "local-exec" {
    command = ".\\webapp-pipelines.ps1"
    interpreter = ["PowerShell", "-Command"]
  }
}
