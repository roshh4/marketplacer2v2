# Development Environment Configuration
environment = "dev"
location    = "Southeast Asia"

# Database Configuration
db_admin_username = "marketplace_admin"
db_name          = "marketplace"

# Storage Configuration
storage_account_name     = "marketplacedevst2024"
storage_container_name   = "images"

# Container Configuration
container_image_tag = "latest"

# Content Safety Configuration
content_safety_endpoint = "https://image-content-moderation.services.ai.azure.com"

# Azure Functions Configuration
function_cors_origins = [
  "http://localhost:3000",
  "http://localhost:5173",
  "https://*.azurestaticapps.net"
]

# Note: Sensitive variables should be set via environment variables or Azure DevOps variables:
# - db_admin_password
# - gemini_api_key
# - content_safety_key
