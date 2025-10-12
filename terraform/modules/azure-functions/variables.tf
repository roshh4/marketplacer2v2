variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the existing resource group"
  type        = string
}

variable "function_app_name" {
  description = "Name of the Azure Function App"
  type        = string
}

variable "functions_storage_account_name" {
  description = "Name of the storage account for Azure Functions"
  type        = string
}

variable "key_vault_name" {
  description = "Name of the Key Vault for storing secrets"
  type        = string
}

variable "gemini_api_key" {
  description = "Gemini API key for AI description generation"
  type        = string
  sensitive   = true
}

variable "allowed_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
}

variable "enable_staging_slot" {
  description = "Whether to create a staging deployment slot"
  type        = bool
  default     = true
}
