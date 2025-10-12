terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

# Data source for existing resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Storage Account for Azure Functions
resource "azurerm_storage_account" "functions_storage" {
  name                     = var.functions_storage_account_name
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = data.azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  tags = {
    environment = var.environment
    purpose     = "azure-functions"
  }
}

# Application Insights for monitoring
resource "azurerm_application_insights" "functions_insights" {
  name                = "appi-functions-${var.environment}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  application_type    = "web"
  retention_in_days   = 30

  tags = {
    environment = var.environment
    purpose     = "azure-functions-monitoring"
  }
}

# Key Vault for secure secret storage
resource "azurerm_key_vault" "functions_kv" {
  name                = var.key_vault_name
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  purge_protection_enabled   = false
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge", "Recover"
    ]
  }

  tags = {
    environment = var.environment
    purpose     = "azure-functions-secrets"
  }
}

# Data source for current client config
data "azurerm_client_config" "current" {}

# Key Vault Secret for Gemini API Key
resource "azurerm_key_vault_secret" "gemini_api_key" {
  name         = "gemini-api-key"
  value        = var.gemini_api_key
  key_vault_id = azurerm_key_vault.functions_kv.id

  tags = {
    environment = var.environment
  }
}

# Service Plan for Azure Functions (Consumption Plan)
resource "azurerm_service_plan" "functions_plan" {
  name                = "asp-functions-${var.environment}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption plan

  tags = {
    environment = var.environment
    purpose     = "azure-functions"
  }
}

# Azure Function App
resource "azurerm_linux_function_app" "ai_description" {
  name                = var.function_app_name
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.functions_plan.id

  storage_account_name       = azurerm_storage_account.functions_storage.name
  storage_account_access_key = azurerm_storage_account.functions_storage.primary_access_key

  functions_extension_version = "~4"
  builtin_logging_enabled     = false

  site_config {
    always_on = false

    application_insights_key               = azurerm_application_insights.functions_insights.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.functions_insights.connection_string

    application_stack {
      python_version = "3.9"
    }

    cors {
      allowed_origins     = var.allowed_origins
      support_credentials = false
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"     = "python"
    "GEMINI_API_KEY"              = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.gemini_api_key.id})"
    "WEBSITE_RUN_FROM_PACKAGE"    = "1"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "ENABLE_ORYX_BUILD"           = "true"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = var.environment
    purpose     = "ai-description-generation"
  }

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

# Key Vault Access Policy for Function App
resource "azurerm_key_vault_access_policy" "function_app_policy" {
  key_vault_id = azurerm_key_vault.functions_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_function_app.ai_description.identity[0].principal_id

  secret_permissions = [
    "Get"
  ]
}

# Function App Slot for staging (optional)
resource "azurerm_linux_function_app_slot" "staging" {
  count                      = var.enable_staging_slot ? 1 : 0
  name                       = "staging"
  function_app_id            = azurerm_linux_function_app.ai_description.id
  storage_account_name       = azurerm_storage_account.functions_storage.name
  storage_account_access_key = azurerm_storage_account.functions_storage.primary_access_key

  site_config {
    always_on = false

    application_insights_key               = azurerm_application_insights.functions_insights.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.functions_insights.connection_string

    application_stack {
      python_version = "3.9"
    }

    cors {
      allowed_origins     = var.allowed_origins
      support_credentials = false
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"     = "python"
    "GEMINI_API_KEY"              = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.gemini_api_key.id})"
    "WEBSITE_RUN_FROM_PACKAGE"    = "1"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "ENABLE_ORYX_BUILD"           = "true"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "${var.environment}-staging"
    purpose     = "ai-description-generation"
  }
}

# Key Vault Access Policy for Staging Slot
resource "azurerm_key_vault_access_policy" "staging_function_app_policy" {
  count        = var.enable_staging_slot ? 1 : 0
  key_vault_id = azurerm_key_vault.functions_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_function_app_slot.staging[0].identity[0].principal_id

  secret_permissions = [
    "Get"
  ]
}
