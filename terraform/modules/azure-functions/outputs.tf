output "function_app_name" {
  description = "Name of the Azure Function App"
  value       = azurerm_linux_function_app.ai_description.name
}

output "function_app_url" {
  description = "URL of the Azure Function App"
  value       = "https://${azurerm_linux_function_app.ai_description.default_hostname}"
}

output "function_app_id" {
  description = "ID of the Azure Function App"
  value       = azurerm_linux_function_app.ai_description.id
}

output "staging_slot_url" {
  description = "URL of the staging deployment slot"
  value       = var.enable_staging_slot ? "https://${azurerm_linux_function_app_slot.staging[0].default_hostname}" : null
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.functions_insights.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.functions_insights.connection_string
  sensitive   = true
}

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.functions_kv.id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.functions_kv.name
}

output "storage_account_name" {
  description = "Name of the Functions storage account"
  value       = azurerm_storage_account.functions_storage.name
}

output "service_plan_id" {
  description = "ID of the Azure Service Plan"
  value       = azurerm_service_plan.functions_plan.id
}

# API Endpoints
output "api_endpoints" {
  description = "Available API endpoints"
  value = {
    generate_description = "https://${azurerm_linux_function_app.ai_description.default_hostname}/api/generate-description"
    ai_status           = "https://${azurerm_linux_function_app.ai_description.default_hostname}/api/ai-status"
    health              = "https://${azurerm_linux_function_app.ai_description.default_hostname}/api/health"
  }
}
