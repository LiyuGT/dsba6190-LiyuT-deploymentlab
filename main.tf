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

resource "azurerm_resource_group" "rg1" {
  name     = "${var.class_name}-${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}-rg1"
  location = var.location

  tags = local.tags
}



// Storage Account

resource "azurerm_storage_account" "storage" {
  name                     = "${var.class_name}${var.student_name}${var.environment}${random_integer.deployment_id_suffix.result}st"
  resource_group_name      = azurerm_resource_group.rg1.name
  location                 = azurerm_resource_group.rg1.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled = true

  tags = local.tags
}

// Machine Learning Workspace


data "azurerm_client_config" "current" {}

resource "azurerm_application_insights" "rg1" {
  name                = "workspace-rg1-ai"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  application_type    = "web"
}

resource "azurerm_key_vault" "rg1" {
  name                = "workspaceexamplekeyvault"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"
}


resource "azurerm_machine_learning_workspace" "rg1" {
  name                    = "rg1-workspace"
  location                = azurerm_resource_group.rg1.location
  resource_group_name     = azurerm_resource_group.rg1.name
  application_insights_id = azurerm_application_insights.rg1.id
  key_vault_id            = azurerm_key_vault.rg1.id
  storage_account_id      = azurerm_storage_account.storage.id

  identity {
    type = "SystemAssigned"
  }
}

//Cosmos DB

resource "azurerm_cosmosdb_account" "db" {
  name                = "${var.class_name}${var.student_name}${var.environment}${random_integer.deployment_id_suffix.result}db"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  enable_automatic_failover = true

  capabilities {
    name = "EnableAggregationPipeline"
  }

  capabilities {
    name = "mongoEnableDocLevelTTL"
  }

  capabilities {
    name = "MongoDBv3.4"
  }

  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = "eastus"
    failover_priority = 0
  }

}

//Firewall

resource "azurerm_virtual_network" "rg1" {
  name                = "testvnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
}

resource "azurerm_subnet" "rg1" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.rg1.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "rg1" {
  name                = "testpip"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "rg1" {
  name                = "testfirewall"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.rg1.id
    public_ip_address_id = azurerm_public_ip.rg1.id
  }
}

//data factory
resource "azurerm_data_factory" "rg1" {
  name                = "rg1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
}