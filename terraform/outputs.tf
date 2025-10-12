output "container_app_name" {
  description = "Name of the Container App"
  value       = azurerm_container_app.marketplace_backend.name
}

output "container_app_url" {
  description = "URL of the Container App"
  value       = "https://${azurerm_container_app.marketplace_backend.ingress[0].fqdn}"
}

output "container_app_environment_name" {
  description = "Name of the Container App Environment"
  value       = azurerm_container_app_environment.marketplace.name
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

output "storage_account_name" {
  description = "Name of the Azure Storage Account"
  value       = azurerm_storage_account.marketplace_storage.name
}

output "postgresql_server_name" {
  description = "Name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.marketplace.name
}

# Azure Functions Outputs
output "function_app_name" {
  description = "Name of the Azure Function App"
  value       = module.azure_functions.function_app_name
}

output "function_app_url" {
  description = "URL of the Azure Function App"
  value       = module.azure_functions.function_app_url
}

output "function_staging_url" {
  description = "URL of the Function App staging slot"
  value       = module.azure_functions.staging_slot_url
}

output "function_api_endpoints" {
  description = "Available Function API endpoints"
  value       = module.azure_functions.api_endpoints
}

output "function_key_vault_name" {
  description = "Name of the Functions Key Vault"
  value       = module.azure_functions.key_vault_name
}
