# aztf-module-vm
Azure Terraform Module for Virtual Machine

Example) Create VM
```
module "service1" {
  source                            = "git://github.com/hyundonk/aztf-module-vm.git"

  prefix                            = "test"
  vm_num                            = 2

  vm_name                           = "svc1"
  vm_size                           = "Standard_D2s_v3"

  vm_publisher                      = "Canonical"
  vm_offer                          = "UbuntuServer"
  vm_sku                            = "16.04.0-LTS"
  vm_version                        = "latest"

  location                          = "westus"
  resource_group_name               = "testResourceGroup"

  subnet_id                         = local.subnet_ids_map[var.services[0].subnet]
  subnet_prefix                     = local.subnet_prefix_map[var.services[0].subnet]

  subnet_ip_offset                  = var.services[0].subnet_ip_offset

  admin_username                    = local.admin_username
  admin_password                    = local.admin_password

  boot_diagnostics_endpoint         = local.diagnostics_map.diags_sa_blob

  diag_storage_account_name         = null
  diag_storage_account_access_key   = null

  log_analytics_workspace_id        = null
  log_analytics_workspace_key       = null

  enable_network_watcher_extension  = false
  enable_dependency_agent           = false
}
```
