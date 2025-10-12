# Production Environment Configuration
environment = "prod"
location    = "Southeast Asia"

# Database Configuration
db_admin_username = "marketplace_admin"
db_name          = "marketplace"

# Storage Configuration
storage_account_name     = "marketplaceprodst2024"
storage_container_name   = "images"

# Container Configuration
container_image_tag = "stable"

# Content Safety Configuration
content_safety_endpoint = "https://image-content-moderation.services.ai.azure.com"

# Azure Functions Configuration
function_cors_origins = [
  "https://marketplace.yourdomain.com",
  "https://www.yourdomain.com"
]

# Note: Sensitive variables should be set via environment variables or Azure DevOps variables:
# - db_admin_password
# - gemini_api_key
# - content_safety_key
