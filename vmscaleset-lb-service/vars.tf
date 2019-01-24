variable "az_region" {
  default = "eastus"
  description = "The Azure region to deploy to"
}

variable "resource_group_name" {
  default     = "vm-scaleset-lb-service"
  description = "The Azure region to deploy to"
}

variable "name" {
  description = "The name for the VM scaleset. This name is also used to namespace all the other resources created by this module."
}

variable "instance_type" {
  description = "The type of Azure VM Instnaces to run in the VM scaleset"
}

variable "min_size" {
  description = "The minimum number of VM Instances to run in the VM Scaleset"
}

variable "max_size" {
  description = "The maximum number of VM Instnaces to run in the VM Scaleset"
}

variable "server_port" {
  description = "The port number the web server on each VM Instnaces should listen on for HTTP requests"
}

variable "lb_port" {
  description = "The port number the Azure Load Balancer should listen on for HTTP requests"
}
