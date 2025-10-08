output "container_app_url" {
  description = "URL of the deployed container app"
  value       = "https://${azurerm_container_app.marketplace_backend.ingress[0].fqdn}"
}

# Static Web App outputs removed - created manually

output "database_host" {
  description = "PostgreSQL server hostname"
  value       = azurerm_postgresql_flexible_server.marketplace.fqdn
}

output "database_name" {
  description = "PostgreSQL database name"
  value       = azurerm_postgresql_flexible_server_database.marketplace.name
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.marketplace.name
}

output "container_app_name" {
  description = "Name of the container app"
  value       = azurerm_container_app.marketplace_backend.name
}

output "storage_account_name" {
  description = "Name of the Azure Storage Account"
  value       = azurerm_storage_account.marketplace_storage.name
}

output "postgresql_server_name" {
  description = "Name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.marketplace.name
}
