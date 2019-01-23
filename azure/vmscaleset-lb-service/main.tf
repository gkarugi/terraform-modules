provider "azurerm" {
  region  = "${var.az_region}"
  version = "~> 1.0"
}

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "azurerm" {}
}

module "network" {
  source              = "Azure/network/azurerm"
  location            = "${var.az_region}"
  resource_group_name = "${var.resource_group_name}"
}

# Azure Load balancer
module "loadbalancer" {
  source              = "Azure/loadbalancer/azurerm"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.az_region}"
  prefix              = "${var.name}"

  lb_port = {
    http  = ["80", "Tcp", "80"]
    https = ["443", "Tcp", "443"]
  }
}

# azure VM scaleset
module "computegroup" {
  source                                 = "Azure/computegroup/azurerm"
  resource_group_name                    = "${var.resource_group_name}"
  location                               = "${var.az_region}"
  vm_size                                = "Standard_B1s"
  admin_username                         = "azureuser"
  admin_password                         = "ComplexPassword"
  ssh_key                                = "~/.ssh/id_rsa.pub"
  nb_instance                            = 2
  vm_os_publisher                        = "Canonical"
  vm_os_offer                            = "UbuntuServer"
  vm_os_sku                              = "18.04-LTS"
  vnet_subnet_id                         = "${module.network.vnet_subnets[0]}"
  load_balancer_backend_address_pool_ids = "${module.loadbalancer.azurerm_lb_backend_address_pool_id}"
  cmd_extension                          = "sudo apt-get -y install nginx"

  tags = {
    environment = "dev"
    costcenter  = "it"
  }
}

output "vmss_id" {
  value = "${module.computegroup.vmss_id}"
}
