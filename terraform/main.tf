terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Kubernetes provider will be configured after AKS cluster is created
# provider "kubernetes" {
#   host                   = azurerm_kubernetes_cluster.marketplace.kube_config.0.host
#   client_certificate     = base64decode(azurerm_kubernetes_cluster.marketplace.kube_config.0.client_certificate)
#   client_key             = base64decode(azurerm_kubernetes_cluster.marketplace.kube_config.0.client_key)
#   cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.marketplace.kube_config.0.cluster_ca_certificate)
# }

# Resource Group
resource "azurerm_resource_group" "marketplace" {
  name     = "rg-marketplace-${var.environment}"
  location = var.location
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "marketplace" {
  name                = "aks-marketplace-${var.environment}"
  location            = azurerm_resource_group.marketplace.location
  resource_group_name = azurerm_resource_group.marketplace.name
  dns_prefix          = "marketplace-${var.environment}"
  kubernetes_version  = "1.30.14"
  sku_tier            = "Premium"

  default_node_pool {
    name                        = "default"
    node_count                  = 1
    vm_size                     = "Standard_B2s"
    temporary_name_for_rotation = "defaulttemp"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "kubenet"
  }

  support_plan = "AKSLongTermSupport"

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

# AKS Node Pool for additional capacity if needed
# Commented out due to VM SKU restrictions
# resource "azurerm_kubernetes_cluster_node_pool" "marketplace" {
#   name                  = "marketplace"
#   kubernetes_cluster_id = azurerm_kubernetes_cluster.marketplace.id
#   vm_size              = "Standard_B1s"
#   node_count           = 1
#   mode                 = "User"
# 
#   tags = {
#     environment = var.environment
#   }
# }

# Kubernetes resources will be deployed after AKS cluster is created
# Uncomment these after running the first terraform apply

# # Kubernetes Namespace
# resource "kubernetes_namespace" "marketplace" {
#   metadata {
#     name = "marketplace"
#     labels = {
#       name = "marketplace"
#     }
#   }
# }

# # Kubernetes Secret
# resource "kubernetes_secret" "marketplace_secrets" {
#   metadata {
#     name      = "marketplace-secrets"
#     namespace = kubernetes_namespace.marketplace.metadata[0].name
#   }

#   data = {
#     "db-password"                = var.db_admin_password
#     "storage-connection-string"  = azurerm_storage_account.marketplace_storage.primary_connection_string
#   }

#   type = "Opaque"
# }

# # Kubernetes Deployment
# resource "kubernetes_deployment" "marketplace_backend" {
#   metadata {
#     name      = "marketplace-backend"
#     namespace = kubernetes_namespace.marketplace.metadata[0].name
#     labels = {
#       app = "marketplace-backend"
#     }
#   }

#   spec {
#     replicas = 2

#     selector {
#       match_labels = {
#         app = "marketplace-backend"
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           app = "marketplace-backend"
#         }
#       }

#       spec {
#         container {
#           name  = "marketplace-backend"
#           image = "roshh4/marketplace-backend-alpine-amd64:${var.container_image_tag}"
#           port {
#             container_port = 8080
#           }

#           env {
#             name  = "DB_HOST"
#             value = azurerm_postgresql_flexible_server.marketplace.fqdn
#           }

#           env {
#             name  = "DB_PORT"
#             value = "5432"
#           }

#           env {
#             name  = "DB_NAME"
#             value = var.db_name
#           }

#           env {
#             name  = "DB_USER"
#             value = var.db_admin_username
#           }

#           env {
#             name = "DB_PASSWORD"
#             value_from {
#               secret_key_ref {
#                 name = kubernetes_secret.marketplace_secrets.metadata[0].name
#                 key  = "db-password"
#               }
#             }
#           }

#           env {
#             name  = "PORT"
#             value = "8080"
#           }

#           env {
#             name  = "GIN_MODE"
#             value = "release"
#           }

#           env {
#             name  = "DB_SSLMODE"
#             value = "require"
#           }

#           env {
#             name  = "AZURE_STORAGE_ACCOUNT_NAME"
#             value = azurerm_storage_account.marketplace_storage.name
#           }

#           env {
#             name = "AZURE_STORAGE_CONNECTION_STRING"
#             value_from {
#               secret_key_ref {
#                 name = kubernetes_secret.marketplace_secrets.metadata[0].name
#                 key  = "storage-connection-string"
#               }
#             }
#           }

#           resources {
#             requests = {
#               memory = "256Mi"
#               cpu    = "250m"
#             }
#             limits = {
#               memory = "512Mi"
#               cpu    = "500m"
#             }
#           }

#           liveness_probe {
#             http_get {
#               path = "/health"
#               port = 8080
#             }
#             initial_delay_seconds = 30
#             period_seconds        = 10
#           }

#           readiness_probe {
#             http_get {
#               path = "/health"
#               port = 8080
#             }
#             initial_delay_seconds = 5
#             period_seconds        = 5
#           }
#         }
#       }
#     }
#   }
# }

# # Kubernetes Service
# resource "kubernetes_service" "marketplace_backend" {
#   metadata {
#     name      = "marketplace-backend-service"
#     namespace = kubernetes_namespace.marketplace.metadata[0].name
#     labels = {
#       app = "marketplace-backend"
#     }
#   }

#   spec {
#     type = "ClusterIP"
#     port {
#       port        = 80
#       target_port = 8080
#       protocol    = "TCP"
#     }
#     selector = {
#       app = "marketplace-backend"
#     }
#   }
# }
