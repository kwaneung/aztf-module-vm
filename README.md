# aztf-module-vm
Azure Terraform Module for Virtual Machine

Example) Create 2 ubuntu VMs in a subnet
```
module "service1" {
  source                            = "git://github.com/hyundonk/aztf-module-vm.git"

  prefix                            = "exmp"
  vm_num                            = 2

  vm_name                           = "svc1"
  vm_size                           = "Standard_D2s_v3"

  vm_publisher                      = "Canonical"
  vm_offer                          = "UbuntuServer"
  vm_sku                            = "16.04.0-LTS"
  vm_version                        = "latest"

  location                          = "westus"
  resource_group_name               = "testResourceGroup"

  subnet_id                         = azurerm_subnet.example.id
  subnet_prefix                     = azurerm_subnet.example.address_prefix

  subnet_ip_offset                  = 4

  admin_username                    = local.admin_username
  admin_password                    = local.admin_password
}
```
