output "container_app_url" {
  description = "URL of the deployed container app"
  value       = "https://${azurerm_container_app.marketplace_backend.latest_revision_fqdn}"
}

output "static_web_app_url" {
  description = "URL of the static web app"
  value       = "https://${azurerm_static_web_app.marketplace_frontend.default_host_name}"
}

output "static_web_app_deployment_token" {
  description = "Deployment token for Static Web App"
  value       = azurerm_static_web_app.marketplace_frontend.api_key
  sensitive   = true
}

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

output "postgresql_server_name" {
  description = "Name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.marketplace.name
}
