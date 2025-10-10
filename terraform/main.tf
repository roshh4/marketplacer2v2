terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Azure Container Apps Environment
resource "azurerm_container_app_environment" "marketplace" {
  name                       = "cae-marketplace-${var.environment}"
  location                   = azurerm_resource_group.marketplace.location
  resource_group_name        = azurerm_resource_group.marketplace.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.marketplace.id
}

# Resource Group
resource "azurerm_resource_group" "marketplace" {
  name     = "rg-marketplace-${var.environment}"
  location = var.location
}

# Log Analytics Workspace for Container Apps
resource "azurerm_log_analytics_workspace" "marketplace" {
  name                = "law-marketplace-${var.environment}"
  location            = azurerm_resource_group.marketplace.location
  resource_group_name = azurerm_resource_group.marketplace.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Azure Container App
resource "azurerm_container_app" "marketplace_backend" {
  name                         = "ca-marketplace-backend-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.marketplace.id
  resource_group_name          = azurerm_resource_group.marketplace.name
  revision_mode                = "Single"

  template {
    min_replicas = 1
    max_replicas = 3

    container {
      name   = "marketplace-backend"
      image  = "roshh4/marketplace-backend-alpine-amd64:${var.container_image_tag}"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "DB_HOST"
        value = azurerm_postgresql_flexible_server.marketplace.fqdn
      }

      env {
        name  = "DB_PORT"
        value = "5432"
      }

      env {
        name  = "DB_NAME"
        value = var.db_name
      }

      env {
        name  = "DB_USER"
        value = var.db_admin_username
      }

      env {
        name        = "DB_PASSWORD"
        secret_name = "db-password"
      }

      env {
        name  = "PORT"
        value = "8080"
      }

      env {
        name  = "GIN_MODE"
        value = "release"
      }

      env {
        name  = "DB_SSLMODE"
        value = "require"
      }

      env {
        name  = "AZURE_STORAGE_ACCOUNT_NAME"
        value = azurerm_storage_account.marketplace_storage.name
      }

      env {
        name        = "AZURE_STORAGE_CONNECTION_STRING"
        secret_name = "storage-connection-string"
      }
    }
  }

  secret {
    name  = "db-password"
    value = var.db_admin_password
  }

  secret {
    name  = "storage-connection-string"
    value = azurerm_storage_account.marketplace_storage.primary_connection_string
  }

  ingress {
    allow_insecure_connections = false
    external_enabled          = true
    target_port               = 8080
    transport                 = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = {
    environment = var.environment
  }
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "marketplace" {
  name                   = "psql-marketplace-${var.environment}"
  resource_group_name    = azurerm_resource_group.marketplace.name
  location               = azurerm_resource_group.marketplace.location
  version                = "13"
  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password
  zone                   = "1"

  storage_mb = 32768
  sku_name   = "B_Standard_B1ms"

  backup_retention_days = 7
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "marketplace" {
  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.marketplace.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# PostgreSQL Firewall Rule (Allow Azure Services)
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.marketplace.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Azure Storage Account for product images
resource "azurerm_storage_account" "marketplace_storage" {
  name                     = "marketplacestore2024"
  resource_group_name      = azurerm_resource_group.marketplace.name
  location                 = azurerm_resource_group.marketplace.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"

  tags = {
    environment = var.environment
  }
}

# Storage Container for images
resource "azurerm_storage_container" "images" {
  name                  = var.storage_container_name
  storage_account_name  = azurerm_storage_account.marketplace_storage.name
  container_access_type = "blob" # Public access to blobs
}

# Static Web App created manually in Azure Portal
# Name: swa-marketplace-dev
