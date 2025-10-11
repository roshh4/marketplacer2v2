variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "Southeast Asia"
}

variable "db_admin_username" {
  description = "PostgreSQL administrator username"
  type        = string
  default     = "marketplace_admin"
}

variable "db_admin_password" {
  description = "PostgreSQL administrator password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "marketplace"
}

variable "storage_account_name" {
  description = "Azure Storage Account name"
  type        = string
}

variable "storage_container_name" {
  description = "Azure Storage Container name for images"
  type        = string
  default     = "images"
}

variable "container_image_tag" {
  description = "Docker image tag for the container"
  type        = string
  default     = "latest"
}

variable "gemini_api_key" {
  description = "Gemini API key for AI description generation"
  type        = string
  sensitive   = true
}

variable "content_safety_endpoint" {
  description = "Azure Content Safety API endpoint"
  type        = string
  default     = "https://image-content-moderation.services.ai.azure.com"
}

variable "content_safety_key" {
  description = "Azure Content Safety API key"
  type        = string
  sensitive   = true
}
