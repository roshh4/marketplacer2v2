# Marketplace Deployment Guide

This guide covers the complete deployment of the marketplace application including the backend, database, storage, and Azure Functions.

## 🏗️ Infrastructure Overview

The application consists of:
- **Container App**: Go backend API
- **PostgreSQL**: Database
- **Azure Storage**: Product images
- **Azure Functions**: AI description generation
- **Static Web App**: Frontend (deployed separately)

## 📋 Prerequisites

1. **Azure CLI**: `az login`
2. **Terraform**: Version 1.0+
3. **Docker**: For container builds
4. **Azure Functions Core Tools**: For function deployment
5. **Python 3.9+**: For Azure Functions

## 🚀 Deployment Steps

### 1. Infrastructure Deployment

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Create terraform.tfvars file with your values
cat > terraform.tfvars << EOF
db_admin_password = "your-secure-password"
storage_account_name = "yourstorageaccount"
gemini_api_key = "AIzaSyBb3WyVpq3wFzgxbwNLrZkf_6GJyHdYxtA"
content_safety_key = "your-content-safety-key"
container_image_tag = "latest"
EOF

# Plan and apply
terraform plan
terraform apply
```

### 2. Azure Functions Deployment

**Automatic (CI/CD)**:
Azure Functions are deployed automatically via GitHub Actions when you push to main branch.

**Manual (Development)**:
```bash
cd azure-functions\ai-generated-description
func azure functionapp publish func-marketplace-ai-dev
```

### 3. Backend Container Deployment

The backend container is automatically deployed via Terraform. To update:

```bash
# Build and push new container image
docker build -t roshh4/marketplace-backend-alpine-amd64:latest .
docker push roshh4/marketplace-backend-alpine-amd64:latest

# Update Terraform with new image tag
terraform apply -var="container_image_tag=new-tag"
```

## 🔧 Configuration

### Environment Variables

The following variables are configured via Terraform:

| Variable | Description | Source |
|----------|-------------|---------|
| `GEMINI_API_KEY` | Google Gemini API key | terraform.tfvars |
| `CONTENT_SAFETY_KEY` | Azure Content Safety key | terraform.tfvars |
| `DB_*` | Database connection details | Terraform outputs |
| `AZURE_STORAGE_*` | Storage account details | Terraform outputs |

### Terraform Variables

Create `terraform/terraform.tfvars`:

```hcl
# Required variables
db_admin_password = "your-secure-password"
storage_account_name = "youruniquestorageaccount"
gemini_api_key = "your-gemini-api-key"
content_safety_key = "your-content-safety-key"

# Optional variables
environment = "dev"
location = "Southeast Asia"
container_image_tag = "latest"
```

## 📱 Service URLs

After deployment, you'll have:

- **Backend API**: `https://ca-marketplace-backend-dev.{region}.azurecontainerapps.io`
- **AI Functions**: `https://func-marketplace-ai-dev.azurewebsites.net`
- **Database**: `psql-marketplace-dev.postgres.database.azure.com`

Get exact URLs with:
```bash
cd terraform
terraform output
```

## 🧪 Testing

### Test Backend
```bash
curl https://your-backend-url/health
```

### Test Azure Functions
```bash
curl https://your-function-url/api/health

# Test AI description
curl -X POST https://your-function-url/api/generate-description \
  -H "Content-Type: application/json" \
  -d '{"title": "Gaming Laptop", "category": "Electronics"}'
```

### Run Function Tests Locally
```bash
cd azure-functions\ai-generated-description
func start
python test_function.py
```

## 🔄 CI/CD Integration

The infrastructure supports automated deployments:

1. **Infrastructure**: Use Terraform in CI/CD pipeline
2. **Backend**: Build and push container images
3. **Functions**: Use `func azure functionapp publish` in pipeline

## 📊 Monitoring

Monitor your deployment:

- **Azure Portal**: Resource health and metrics
- **Application Insights**: Function performance
- **Container Apps**: Backend logs and scaling
- **PostgreSQL**: Database performance

## 🛠️ Troubleshooting

### Common Issues

1. **Function deployment fails**:
   ```bash
   # Check function app exists
   az functionapp list --query "[?name=='func-marketplace-ai-dev']"
   
   # Restart function app
   az functionapp restart --name func-marketplace-ai-dev --resource-group rg-marketplace-dev
   ```

2. **Backend container not starting**:
   ```bash
   # Check container logs
   az containerapp logs show --name ca-marketplace-backend-dev --resource-group rg-marketplace-dev
   ```

3. **Database connection issues**:
   ```bash
   # Check firewall rules
   az postgres flexible-server firewall-rule list --name psql-marketplace-dev --resource-group rg-marketplace-dev
   ```

### Useful Commands

```bash
# Get all resource names
terraform output

# Check function app status
az functionapp show --name func-marketplace-ai-dev --resource-group rg-marketplace-dev

# View container app logs
az containerapp logs show --name ca-marketplace-backend-dev --resource-group rg-marketplace-dev --follow

# Test database connection
psql "host=psql-marketplace-dev.postgres.database.azure.com port=5432 dbname=marketplace user=marketplace_admin sslmode=require"
```

## 🔐 Security Notes

- All sensitive values are stored as Terraform variables
- Database uses SSL connections
- Storage account uses HTTPS only
- Function app has CORS configured
- Container app uses managed identity where possible

## 💰 Cost Optimization

- Container Apps: Scale to zero when not in use
- Azure Functions: Consumption plan (pay per execution)
- PostgreSQL: Basic tier for development
- Storage: Standard LRS for cost efficiency

## 🚀 Production Considerations

For production deployment:

1. Use separate Terraform workspaces/state files
2. Enable backup for PostgreSQL
3. Configure custom domains and SSL certificates
4. Set up monitoring and alerting
5. Implement proper CI/CD pipelines
6. Use Azure Key Vault for secrets
7. Configure network security groups
8. Enable diagnostic logging
