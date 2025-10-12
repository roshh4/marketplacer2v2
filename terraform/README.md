# Terraform Infrastructure for Marketplace with Azure Functions

This Terraform configuration manages the complete infrastructure for the college marketplace application, including the new Azure Functions for AI-powered product descriptions.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     Azure Resource Group                        │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Container App │  │ Azure Functions │  │   PostgreSQL    │ │
│  │   (Go Backend)  │  │ (AI Description)│  │   Database      │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│           │                     │                     │         │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ Blob Storage    │  │   Key Vault     │  │ App Insights    │ │
│  │ (Images)        │  │   (Secrets)     │  │ (Monitoring)    │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Components

### Core Infrastructure
- **Resource Group**: Container for all resources
- **Container Apps Environment**: Hosts the Go backend
- **PostgreSQL Flexible Server**: Database for marketplace data
- **Azure Storage Account**: Blob storage for product images

### Azure Functions (New)
- **Function App**: Hosts AI description generation functions
- **Key Vault**: Secure storage for API keys and secrets
- **Application Insights**: Monitoring and logging
- **Service Plan**: Consumption-based hosting

## Directory Structure

```
terraform/
├── main.tf                          # Main configuration
├── variables.tf                     # Input variables
├── outputs.tf                       # Output values
├── modules/
│   └── azure-functions/
│       ├── main.tf                  # Function App resources
│       ├── variables.tf             # Module variables
│       └── outputs.tf               # Module outputs
└── environments/
    ├── dev.tfvars                   # Development configuration
    ├── staging.tfvars               # Staging configuration
    └── prod.tfvars                  # Production configuration
```

## Prerequisites

1. **Azure CLI** installed and logged in
2. **Terraform** v1.5.0 or higher
3. **Azure Storage Account** for Terraform state (recommended)
4. **Service Principal** with appropriate permissions

## Setup Instructions

### 1. Configure Terraform Backend (Recommended)

Create a storage account for Terraform state:

```bash
# Create resource group for Terraform state
az group create --name rg-terraform-state --location "Southeast Asia"

# Create storage account
az storage account create \
  --name terraformstate$(date +%s) \
  --resource-group rg-terraform-state \
  --location "Southeast Asia" \
  --sku Standard_LRS

# Create container
az storage container create \
  --name tfstate \
  --account-name <storage-account-name>
```

### 2. Initialize Terraform

```bash
cd terraform

# Initialize with backend configuration
terraform init \
  -backend-config="resource_group_name=rg-terraform-state" \
  -backend-config="storage_account_name=<your-storage-account>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=<environment>.tfstate"
```

### 3. Configure Variables

Create a `terraform.tfvars` file or use environment-specific files:

```hcl
# Required variables
db_admin_password    = "your-secure-password"
gemini_api_key      = "AIzaSyBb3WyVpq3wFzgxbwNLrZkf_6GJyHdYxtA"
content_safety_key  = "your-content-safety-key"
storage_account_name = "marketplacedevst2024"
```

### 4. Deploy Infrastructure

```bash
# Plan deployment
terraform plan -var-file="environments/dev.tfvars"

# Apply changes
terraform apply -var-file="environments/dev.tfvars"
```

## Environment Management

### Development
```bash
terraform workspace select dev || terraform workspace new dev
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
```

### Staging
```bash
terraform workspace select staging || terraform workspace new staging
terraform plan -var-file="environments/staging.tfvars"
terraform apply -var-file="environments/staging.tfvars"
```

### Production
```bash
terraform workspace select prod || terraform workspace new prod
terraform plan -var-file="environments/prod.tfvars"
terraform apply -var-file="environments/prod.tfvars"
```

## Azure Functions Deployment

The Terraform configuration creates the infrastructure for Azure Functions, but the function code is deployed separately via CI/CD or manual deployment.

### Manual Function Deployment

```bash
# Navigate to function directory
cd ../azure-functions/ai-generated-description

# Deploy using Azure Functions Core Tools
func azure functionapp publish <function-app-name>
```

### CI/CD Deployment

The GitHub Actions workflow automatically deploys functions when code changes are pushed to the repository.

## Outputs

After successful deployment, Terraform provides these outputs:

```bash
# Get all outputs
terraform output

# Specific outputs
terraform output function_app_url
terraform output function_api_endpoints
terraform output container_app_url
```

## Security Considerations

### Secrets Management
- All sensitive values stored in Azure Key Vault
- Function App uses Managed Identity to access Key Vault
- No secrets in Terraform state or configuration files

### Network Security
- Container Apps and Functions use HTTPS only
- Database requires SSL connections
- Storage accounts use secure transfer

### Access Control
- Minimal required permissions for service principals
- Resource-level access controls
- Environment isolation

## Monitoring and Logging

### Application Insights
- Function execution metrics
- Error tracking and alerting
- Performance monitoring
- Custom telemetry

### Log Analytics
- Centralized logging
- Query and analysis capabilities
- Integration with Azure Monitor

## Cost Optimization

### Azure Functions
- Consumption plan for cost-effective scaling
- Pay-per-execution model
- Automatic scaling based on demand

### Container Apps
- Scale-to-zero capability
- Resource-based pricing
- Efficient resource utilization

## Troubleshooting

### Common Issues

1. **Function App deployment fails**
   ```bash
   # Check function app status
   az functionapp show --name <function-app-name> --resource-group <rg-name>
   
   # View logs
   az functionapp log tail --name <function-app-name> --resource-group <rg-name>
   ```

2. **Key Vault access denied**
   ```bash
   # Check access policies
   az keyvault show --name <key-vault-name> --resource-group <rg-name>
   
   # Grant access to managed identity
   az keyvault set-policy --name <key-vault-name> --object-id <managed-identity-id> --secret-permissions get
   ```

3. **Terraform state lock**
   ```bash
   # Force unlock (use with caution)
   terraform force-unlock <lock-id>
   ```

### Validation Commands

```bash
# Validate Terraform configuration
terraform validate

# Format Terraform files
terraform fmt -recursive

# Check for security issues
terraform plan -out=tfplan
terraform show -json tfplan | jq > tfplan.json
# Use tools like tfsec or checkov for security scanning
```

## Migration from Manual Deployment

If you have existing resources deployed manually:

1. **Import existing resources**
   ```bash
   terraform import azurerm_resource_group.marketplace /subscriptions/<sub-id>/resourceGroups/<rg-name>
   ```

2. **Gradual migration**
   - Start with new Azure Functions module
   - Gradually import existing resources
   - Update configurations to match Terraform state

## Support and Maintenance

### Regular Tasks
- Update Terraform provider versions
- Review and rotate secrets
- Monitor resource costs
- Update function dependencies

### Backup and Recovery
- Terraform state is backed up in Azure Storage
- Database automated backups enabled
- Key Vault soft delete protection

## Integration with Existing CI/CD

The Azure Functions CI/CD pipeline integrates with your existing infrastructure:

1. **Shared secrets**: Uses same Azure credentials and Key Vault
2. **Environment consistency**: Follows same dev/staging/prod pattern
3. **Monitoring integration**: Uses existing Application Insights setup
4. **Security alignment**: Follows same security policies and access controls

## Next Steps

1. **Deploy the infrastructure** using the provided configurations
2. **Set up CI/CD pipeline** by configuring GitHub secrets
3. **Test the deployment** using the provided test scripts
4. **Monitor and optimize** based on usage patterns
5. **Scale horizontally** by adding more Azure Functions as needed

For questions or issues, refer to the troubleshooting section or check the Azure documentation.
