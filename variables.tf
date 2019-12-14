
variable "prefix" {
  description = "Prefix for the workspace"
}

variable "vm_num" {
  description = "Number of VMs to create"        
}

variable "vm_name" {
  description = "VM name following 2 digit index"        
}

variable "vm_size" {
  description = "VM size"
}

variable "vm_publisher" {
		default = "MicrosoftWindowsServer"
}

variable "vm_offer" {
		default = "WindowsServer"
}

variable "vm_sku" {
		default = "2016-Datacenter"
}

variable "vm_version" {
		default = "latest"
}

variable "resource_group_name" {
  description = "resource group name"
}

variable "location" {
  description = "resource location"
}

variable "tags" {
  description = "tags"
  default = null
}

variable "subnet_id" {
  description = "subnet ID"
}
 
variable "subnet_prefix" {
  description = "subnet prefix" 
}
        
variable "subnet_ip_offset"	{
  description = "IP offset of starting VM IP" 
  default = null
}

variable "public_ip_id" {
  description = "ID of public IP resource. Optional" 
  default = null
}


variable "admin_username" {
  description = "username for vm admin"
}

variable "admin_password" {
  description = "password for vm admin"
}

variable "boot_diagnostics_endpoint" {
  description = "blob storage URL for boot diagnostics"
  default = null        
}

variable "diag_storage_account_name"        {
  description = "storage account name for diagnostics log"
  default = null      
}

variable "diag_storage_account_access_key"  {
  description = "storage account access key for diagnostics log"
  default = null      
}

variable "log_analytics_workspace_id"  {
  description = "log analytics workspace ID for diagnostics log"
  default = null      
}

variable "log_analytics_workspace_key"  {
  description = "log analytics workspace key for diagnostics log"
  default = null      
}       

variable "enable_network_watcher_extension" {
  description = "true to install network watcher extension" 
  default = false
}

variable "enable_dependency_agent" {
  description = "true to install dependency agent" 
  default = false
}

