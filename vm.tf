

data "azurerm_subscription" "current" {}

locals {
  vm_name = "${var.prefix}-${var.vm_name}"
}

resource "azurerm_availability_set" "avset" {
	count                         = var.vm_num == 1 ? 0 : 1 # create only if multiple instances cases

	name                  	      = "${local.vm_name}-avset"
	location              	      = var.location
	resource_group_name  	        = var.resource_group_name
	
  platform_update_domain_count  = 5 // Korea regions support up to 2 fault domains
	platform_fault_domain_count   = 2 // Korea regions support up to 2 fault domains

	managed                       = true
}


resource "azurerm_network_interface" "nic" {
	count 					                      = var.vm_num

	name           			                  = format("%s-%02d-nic", local.vm_name, count.index + 1)
	location            	                = var.location
	resource_group_name  	                = var.resource_group_name
	
	ip_configuration {
			name = "ipconfig0"
      subnet_id = var.subnet_id
	    private_ip_address_allocation     = var.subnet_ip_offset == null ? "dynamic" : "static"
			private_ip_address                = var.subnet_ip_offset == null ? null : cidrhost(var.subnet_prefix, var.subnet_ip_offset + count.index)
			public_ip_address_id              = var.public_ip_id     == null ? null : var.public_ip_id
	}
}

resource "azurerm_virtual_machine" "vm" {
	count					                        = var.vm_num
	
	name           			                  = var.vm_num == 1 ? local.vm_name: format("%s-%02d", local.vm_name, count.index + 1) 

	location        	   	                = var.location
  resource_group_name 	                = var.resource_group_name
	vm_size               	              = var.vm_size

	availability_set_id                   = var.vm_num == 1 ? null : azurerm_availability_set.avset.0.id
/*
	storage_image_reference {
		publisher             = "MicrosoftWindowsServer"
		offer                 = "WindowsServer"
		sku                   = "2016-Datacenter"
		version               = "latest"
	}
*/
	storage_image_reference {
		publisher             = var.vm_publisher
		offer                 = var.vm_offer
		sku                   = var.vm_sku
		version               = var.vm_version
	}

	storage_os_disk {
		name      			      = format("%s-%02d-osdisk", local.vm_name, count.index + 1)
		caching       		    = "ReadWrite"
		create_option 		    = "FromImage"
		managed_disk_type 	  = "Premium_LRS"
	}

	os_profile {
		computer_name 		    = format("%s-%02d", local.vm_name, count.index + 1)
    admin_username        = var.admin_username
    admin_password        = var.admin_password
	}
  
  dynamic "os_profile_windows_config" {
    for_each = var.vm_offer == "WindowsServer" ? ["WindowsServer"] : []
    content {
		  provision_vm_agent    = true
    }
  }

  dynamic "os_profile_linux_config" {
    for_each = var.vm_offer == "UbuntuServer" ? ["UbuntuServer"] : []
    content {
      disable_password_authentication = false
    }
  }
	
  boot_diagnostics {
		enabled               = var.boot_diagnostics_endpoint != null ? true : false
		storage_uri           = var.boot_diagnostics_endpoint
	}

	#network_interface_ids  = [element(azurerm_network_interface.nic.*.id, count.index)]
	network_interface_ids   = [element(concat(azurerm_network_interface.nic.*.id, list("")), count.index)]
}

locals {
	wadlogs               = file("${path.module}/wadlogs.xml.tpl")
	wadperfcounters1      = file("${path.module}/wadperfcounters1.xml.tpl")
	wadperfcounters2      = file("${path.module}/wadperfcounters2.xml.tpl")
	wadcfgxstart          = "${local.wadlogs}${local.wadperfcounters1}${local.wadperfcounters2}<Metrics resourceId=\""
	wadmetricsresourceid  = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Compute/virtualMachines/"
	wadcfgxend            = file("${path.module}/wadcfgxend.xml.tpl")
}

resource "azurerm_virtual_machine_extension" "diagnostics" {
	count 						            = var.diag_storage_account_name == null ? 0 : var.vm_num
	
	name                          = "Microsoft.Insights.VMDiagnosticsSettings"
	location              	      = var.location
	resource_group_name  	        = var.resource_group_name
	virtual_machine_name   	      = element(azurerm_virtual_machine.vm.*.name, count.index)

	publisher            	        = "Microsoft.Azure.Diagnostics"
	type                 	        = "IaaSDiagnostics"
	type_handler_version 	        = "1.5"

	auto_upgrade_minor_version    = true

	settings = <<SETTINGS
	{
		"xmlCfg"            : "${base64encode("${local.wadcfgxstart}${local.wadmetricsresourceid}${element(azurerm_virtual_machine.vm.*.name, count.index)}${local.wadcfgxend}")}",
		"storageAccount"    : "${var.diag_storage_account_name}"
	}
	SETTINGS
	protected_settings = <<SETTINGS
	{
		"storageAccountName": "${var.diag_storage_account_name}",
		"storageAccountKey" : "${var.diag_storage_account_access_key}"
	}
	SETTINGS
}

resource "azurerm_virtual_machine_extension" "monioring" {
	count 						            = var.log_analytics_workspace_id == null ? 0 : var.vm_num
	
	name 						              = "OMSExtension" 
	location 					            = var.location
	resource_group_name  	        = var.resource_group_name
	virtual_machine_name   		    = element(azurerm_virtual_machine.vm.*.name, count.index)

	publisher 					          = "Microsoft.EnterpriseCloud.Monitoring"
	type 						              = "MicrosoftMonitoringAgent"
	type_handler_version 		      = "1.0"
	auto_upgrade_minor_version 	  = true

	settings = <<SETTINGS
	{
		"workspaceId"               : "${var.log_analytics_workspace_id}"
	}
	SETTINGS
	protected_settings = <<PROTECTED_SETTINGS
	{
		"workspaceKey"              : "${var.log_analytics_workspace_key}"
	}
	PROTECTED_SETTINGS
}



resource "azurerm_virtual_machine_extension" "network_watcher" {
	count 						            = var.enable_network_watcher_extension == true ? var.vm_num : 0
	
	name 						              = "Microsoft.Azure.NetworkWatcher" 
	location 					            = var.location
	resource_group_name  	        = var.resource_group_name
	virtual_machine_name   		    = element(azurerm_virtual_machine.vm.*.name, count.index)
	
	publisher 					          = "Microsoft.Azure.NetworkWatcher"
	type 						              = "NetworkWatcherAgentWindows"
	type_handler_version 		      = "1.4"
	auto_upgrade_minor_version 	  = true
}

resource "azurerm_virtual_machine_extension" "dependency_agent" {
	count 						            = var.enable_dependency_agent == true ? var.vm_num : 0
	
	name 						              = "DependencyAgentWindows" 
	location 					            = var.location
	resource_group_name  	        = var.resource_group_name
	virtual_machine_name   		    = element(azurerm_virtual_machine.vm.*.name, count.index)
	
	publisher 					          = "Microsoft.Azure.Monitoring.DependencyAgent"
	type 						              = "DependencyAgentWindows"
	type_handler_version 		      = "9.5"
	auto_upgrade_minor_version 	  = true
}

/*
resource "azurerm_virtual_machine_extension" "iis" {
	count					                = var.custom_script_path == "" ? 0 : var.vm_num
	
	name 						              = "CustomScriptExtension"
	location 					            = var.location
	resource_group_name  	        = var.resource_group_name
	virtual_machine_name   		    = element(azurerm_virtual_machine.vm.*.name, count.index)
	
	publisher 					          = "Microsoft.Compute"
	type 						              = "CustomScriptExtension"
	type_handler_version 		      = "1.8"
	auto_upgrade_minor_version 	  = true

	settings = <<SETTINGS
  {
    "fileUris"                  : [
			"https://ebaykrtfbackend.blob.core.windows.net/scripts/install_iis.ps1"
		],
		"commandToExecute"          : "powershell -ExecutionPolicy Unrestricted -File \"install_iis.ps1\""
  }
	SETTINGS
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "association" {
	count                     = var.backend_address_pool_id == null ? 0 : var.vm_num
	
	network_interface_id      = element(azurerm_network_interface.nic.*.id, count.index)
	ip_configuration_name     = "ipconfig0"
	backend_address_pool_id   = var.backend_address_pool_id
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "association2" {
	count                     = var.backend_address_pool_id2 == null ? 0 : var.vm_num
	
	network_interface_id      = element(azurerm_network_interface.nic.*.id, count.index)
	ip_configuration_name     = "ipconfig0"
	backend_address_pool_id   = var.backend_address_pool_id2
}

resource "azurerm_network_interface_backend_address_pool_association" "extlb-outbound" {
	count                     = var.backend_outbound_address_pool_id == null ? 0 : var.vm_num

	network_interface_id      = element(azurerm_network_interface.nic.*.id, count.index)
	ip_configuration_name     = "ipconfig0"
	backend_address_pool_id   = var.backend_outbound_address_pool_id
}

output "vm_map" {
	value = azurerm_virtual_machine.vm
}
*/
