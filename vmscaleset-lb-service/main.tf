provider "azurerm" {
  version = "~> 1.0"
}

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "azurerm" {}
}

module "VirtualNetwork" {
  source              = "Azure/network/azurerm"
  version                                = "2.1.0"
  location            = "${var.az_region}"
  resource_group_name = "${var.resource_group_name}"
  vnet_name           = "${var.name}-VNet"
  address_space       = "10.0.0.0/16"
  subnet_prefixes     = ["10.0.0.0/16"]
  subnet_names        = ["default"]
}

resource "azurerm_subnet" "subnet" {
  name  = "default"
  address_prefix = "10.0.0.0/16"
  resource_group_name = "${var.resource_group_name}"
  virtual_network_name = "${module.VirtualNetwork.vnet_name}"
  network_security_group_id = "${module.NetworkSecurityGroup.network_security_group_id}"
}

module "NetworkSecurityGroup" {
    source = "Azure/network-security-group/azurerm"
    version                                = "2.1.0"
    resource_group_name        = "${var.resource_group_name}"
    location                   = "${var.az_region}"
    security_group_name        = "${var.name}-NSG"

    predefined_rules           = [
      {
        name                   = "HTTPS"
        priority               = "1001"
        source_address_prefix  = ["*"]
      },
      {
        name                   = "HTTP"
        priority               = "1002"
        source_address_prefix  = ["*"]
      }
    ]
}

# Azure Load balancer
module "loadbalancer" {
  source              = "Azure/loadbalancer/azurerm"
  version                                = "2.1.0"
  type = "public"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.az_region}"
  prefix              = "${var.name}"
  frontend_name       =   "${var.name}-frontend"
  allocation_method   =   "static"

  lb_port = {
    http  = ["80", "Tcp", "80"]
    https = ["443", "Tcp", "443"]
  }

  
}

# azure VM scaleset
module "computegroup" {
  source                                 = "Azure/computegroup/azurerm"
  version                                = "2.1.0"
  vmscaleset_name                        = "${var.name}"
  vnet_subnet_id                         = "${azurerm_subnet.subnet.id}"
  network_profile                        = "${var.name}-network-profile"
  # nsg_id                                 = "${module.NetworkSecurityGroup.network_security_group_id}"
  resource_group_name                    = "${var.resource_group_name}"
  location                               = "${var.az_region}"
  vm_size                                = "${var.instance_type}"
  admin_username                         = "azureuser"
  admin_password                         = "ComplexPassword"
  ssh_key                                = "~/.ssh/id_rsa.pub"
  nb_instance                            = 2
  vm_os_publisher                        = "Canonical"
  vm_os_offer                            = "UbuntuServer"
  vm_os_sku                              = "18.04-LTS"
  # vnet_subnet_id                         = "${module.network.vnet_subnets[0]}"
  # load_balancer_backend_address_pool_ids = "${module.loadbalancer.azurerm_lb_backend_address_pool_id}"
  cmd_extension                          = "sudo apt-get -y install nginx"

  tags = {
    environment = "dev"
    costcenter  = "it"
  }
}

output "vmss_id" {
  value = "${module.computegroup.vmss_id}"
}
