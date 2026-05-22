variable "resource_group_name" {
  type        = string
  description = "Azure Resource Group Name"
}

variable "location" {
  type        = string
  description = "Azure Region"
  default     = "Southeast Asia"
}

variable "cluster_name" {
  type        = string
  description = "AKS Cluster Name"
}

variable "dns_prefix" {
  type        = string
  description = "DNS Prefix for AKS"
}

variable "node_count" {
  type        = number
  description = "Default node pool count"
  default     = 1
}

variable "vm_size" {
  type        = string
  description = "AKS node VM size"
  default     = "Standard_B2s"
}

variable "admin_username" {
  type        = string
  description = "Linux admin username"
  default     = "azureuser"
}