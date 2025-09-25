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

# Resource Group (use existing)
data "azurerm_resource_group" "marketplace" {
  name = "rg-marketplace-${var.environment}"
}

# Container Apps Environment (use existing)
data "azurerm_container_app_environment" "marketplace" {
  name                = "cae-marketplace-${var.environment}"
  resource_group_name = data.azurerm_resource_group.marketplace.name
}

# PostgreSQL Flexible Server (use existing)
data "azurerm_postgresql_flexible_server" "marketplace" {
  name                = "psql-marketplace-${var.environment}"
  resource_group_name = data.azurerm_resource_group.marketplace.name
}

# PostgreSQL Database (use existing)
data "azurerm_postgresql_flexible_server_database" "marketplace" {
  name      = var.db_name
  server_id = data.azurerm_postgresql_flexible_server.marketplace.id
}

# Container App
resource "azurerm_container_app" "marketplace_backend" {
  name                         = "ca-marketplace-backend-${var.environment}"
  container_app_environment_id = data.azurerm_container_app_environment.marketplace.id
  resource_group_name          = data.azurerm_resource_group.marketplace.name
  revision_mode                = "Single"

  template {
    container {
      name   = "marketplace-backend"
      image  = "roshh4/marketplace-backend-alpine-amd64:${var.container_image_tag}"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "DB_HOST"
        value = data.azurerm_postgresql_flexible_server.marketplace.fqdn
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
    }

    min_replicas = 0
    max_replicas = 10
  }

  secret {
    name  = "db-password"
    value = var.db_admin_password
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 8080

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}
