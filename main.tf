// Tags
locals {
  tags = {
    owner       = var.tag_department
    region      = var.tag_region
    environment = var.environment
  }
}

// Existing Resources

/// Subscription ID

data "azurerm_subscription" "current" {
}

// Random Suffix Generator

resource "random_integer" "deployment_id_suffix" {
  min = 100
  max = 999
}

// Resource Group

resource "azurerm_resource_group" "rg" {
  name     = "${var.class_name}-${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}-rg"
  location = var.location

  tags = local.tags
}



// Storage Account

resource "azurerm_storage_account" "storage" {
  name                     = "${var.class_name}${var.student_name}${var.environment}${random_integer.deployment_id_suffix.result}st"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  //is_hns_enabled           = true

  tags = local.tags
}


//Container app
resource "azurerm_log_analytics_workspace" "laws" {
  name                = "${var.class_name}${var.student_name}${var.environment}${random_integer.deployment_id_suffix.result}laws"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "capp" {
  name                       = "${var.class_name}${var.student_name}${var.environment}${random_integer.deployment_id_suffix.result}capp"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.laws.id
}
resource "azurerm_container_app" "ca" {
  name                         = "${var.class_name}${var.student_name}${var.environment}${random_integer.deployment_id_suffix.result}ca"
  container_app_environment_id = azurerm_container_app_environment.capp.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "${var.class_name}${var.student_name}${var.environment}${random_integer.deployment_id_suffix.result}"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }
}

