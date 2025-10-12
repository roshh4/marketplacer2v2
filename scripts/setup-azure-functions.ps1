# Azure Functions Setup Script
# This script helps set up the Azure Functions infrastructure and CI/CD pipeline

param(
    [Parameter(Mandatory=$true)]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [switch]$SetupCICD,
    
    [Parameter(Mandatory=$false)]
    [switch]$DeployInfrastructure,
    
    [Parameter(Mandatory=$false)]
    [switch]$DeployFunction
)

# Colors for output
$Red = [System.ConsoleColor]::Red
$Green = [System.ConsoleColor]::Green
$Yellow = [System.ConsoleColor]::Yellow
$Blue = [System.ConsoleColor]::Blue

function Write-ColorOutput {
    param([string]$Message, [System.ConsoleColor]$Color = [System.ConsoleColor]::White)
    Write-Host $Message -ForegroundColor $Color
}

function Test-Prerequisites {
    Write-ColorOutput "🔍 Checking prerequisites..." $Blue
    
    $allGood = $true
    
    # Check Azure CLI
    try {
        $azVersion = az --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Azure CLI is installed" $Green
        } else {
            throw "Azure CLI not found"
        }
    } catch {
        Write-ColorOutput "❌ Azure CLI is not installed" $Red
        $allGood = $false
    }
    
    # Check Terraform
    try {
        $tfVersion = terraform --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Terraform is installed" $Green
        } else {
            throw "Terraform not found"
        }
    } catch {
        Write-ColorOutput "❌ Terraform is not installed" $Red
        $allGood = $false
    }
    
    # Check Azure Functions Core Tools
    try {
        $funcVersion = func --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Azure Functions Core Tools is installed" $Green
        } else {
            throw "Functions Core Tools not found"
        }
    } catch {
        Write-ColorOutput "❌ Azure Functions Core Tools is not installed" $Red
        $allGood = $false
    }
    
    return $allGood
}

function Set-AzureContext {
    Write-ColorOutput "🔐 Setting up Azure context..." $Blue
    
    # Login check
    try {
        $account = az account show 2>$null | ConvertFrom-Json
        if ($account) {
            Write-ColorOutput "✅ Already logged in to Azure as: $($account.user.name)" $Green
        }
    } catch {
        Write-ColorOutput "🔑 Please log in to Azure..." $Yellow
        az login
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "❌ Azure login failed" $Red
            return $false
        }
    }
    
    # Set subscription
    if ($SubscriptionId) {
        Write-ColorOutput "📋 Setting subscription: $SubscriptionId" $Yellow
        az account set --subscription $SubscriptionId
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "❌ Failed to set subscription" $Red
            return $false
        }
    }
    
    return $true
}

function Initialize-Terraform {
    Write-ColorOutput "🏗️ Initializing Terraform..." $Blue
    
    Set-Location "terraform"
    
    # Initialize Terraform
    terraform init
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "❌ Terraform initialization failed" $Red
        return $false
    }
    
    # Select or create workspace
    terraform workspace select $Environment 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "📁 Creating new workspace: $Environment" $Yellow
        terraform workspace new $Environment
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "❌ Failed to create workspace" $Red
            return $false
        }
    }
    
    Write-ColorOutput "✅ Terraform initialized for environment: $Environment" $Green
    return $true
}

function Deploy-Infrastructure {
    Write-ColorOutput "🚀 Deploying infrastructure..." $Blue
    
    # Check if tfvars file exists
    $tfvarsFile = "environments/$Environment.tfvars"
    if (!(Test-Path $tfvarsFile)) {
        Write-ColorOutput "❌ Environment file not found: $tfvarsFile" $Red
        return $false
    }
    
    # Prompt for sensitive variables
    Write-ColorOutput "🔐 Please provide sensitive variables..." $Yellow
    
    $dbPassword = Read-Host "Database admin password" -AsSecureString
    $dbPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbPassword))
    
    $geminiApiKey = Read-Host "Gemini API Key (press Enter to use default from memory)"
    if ([string]::IsNullOrEmpty($geminiApiKey)) {
        $geminiApiKey = "AIzaSyBb3WyVpq3wFzgxbwNLrZkf_6GJyHdYxtA"
    }
    
    $contentSafetyKey = Read-Host "Content Safety API Key" -AsSecureString
    $contentSafetyKeyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($contentSafetyKey))
    
    # Plan deployment
    Write-ColorOutput "📋 Planning deployment..." $Yellow
    terraform plan `
        -var-file="$tfvarsFile" `
        -var="db_admin_password=$dbPasswordPlain" `
        -var="gemini_api_key=$geminiApiKey" `
        -var="content_safety_key=$contentSafetyKeyPlain" `
        -out=tfplan
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "❌ Terraform plan failed" $Red
        return $false
    }
    
    # Confirm deployment
    Write-ColorOutput "⚠️ Review the plan above. Do you want to proceed with deployment? (y/N)" $Yellow
    $confirm = Read-Host
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-ColorOutput "❌ Deployment cancelled" $Yellow
        return $false
    }
    
    # Apply deployment
    Write-ColorOutput "🚀 Applying deployment..." $Blue
    terraform apply -auto-approve tfplan
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ Infrastructure deployed successfully" $Green
        
        # Show outputs
        Write-ColorOutput "📊 Deployment outputs:" $Blue
        terraform output
        
        return $true
    } else {
        Write-ColorOutput "❌ Infrastructure deployment failed" $Red
        return $false
    }
}

function Deploy-FunctionCode {
    Write-ColorOutput "📦 Deploying function code..." $Blue
    
    # Get function app name from Terraform output
    Set-Location "terraform"
    $functionAppName = terraform output -raw function_app_name 2>$null
    
    if ([string]::IsNullOrEmpty($functionAppName)) {
        Write-ColorOutput "❌ Could not get function app name from Terraform output" $Red
        return $false
    }
    
    Write-ColorOutput "🎯 Deploying to function app: $functionAppName" $Yellow
    
    # Navigate to function directory
    Set-Location "../azure-functions/ai-generated-description"
    
    # Deploy function
    func azure functionapp publish $functionAppName --python
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ Function code deployed successfully" $Green
        
        # Test deployment
        Write-ColorOutput "🧪 Testing deployment..." $Yellow
        Start-Sleep -Seconds 10
        
        $functionUrl = "https://$functionAppName.azurewebsites.net"
        
        try {
            $healthResponse = Invoke-RestMethod -Uri "$functionUrl/api/health" -Method Get -TimeoutSec 30
            if ($healthResponse.status -eq "healthy") {
                Write-ColorOutput "✅ Function is healthy and responding" $Green
            }
        } catch {
            Write-ColorOutput "⚠️ Function deployed but health check failed: $($_.Exception.Message)" $Yellow
        }
        
        return $true
    } else {
        Write-ColorOutput "❌ Function deployment failed" $Red
        return $false
    }
}

function Setup-CICD {
    Write-ColorOutput "⚙️ Setting up CI/CD pipeline..." $Blue
    
    Write-ColorOutput "📋 To complete CI/CD setup, you need to configure these GitHub secrets:" $Yellow
    Write-ColorOutput "" $White
    Write-ColorOutput "Required secrets:" $Blue
    Write-ColorOutput "  - AZURE_CREDENTIALS (Service Principal JSON)" $White
    Write-ColorOutput "  - GEMINI_API_KEY" $White
    Write-ColorOutput "  - DB_ADMIN_PASSWORD_DEV" $White
    Write-ColorOutput "  - DB_ADMIN_PASSWORD_STAGING" $White
    Write-ColorOutput "  - DB_ADMIN_PASSWORD_PROD" $White
    Write-ColorOutput "  - CONTENT_SAFETY_KEY_DEV" $White
    Write-ColorOutput "  - CONTENT_SAFETY_KEY_STAGING" $White
    Write-ColorOutput "  - CONTENT_SAFETY_KEY_PROD" $White
    Write-ColorOutput "  - TF_STATE_RESOURCE_GROUP" $White
    Write-ColorOutput "  - TF_STATE_STORAGE_ACCOUNT" $White
    Write-ColorOutput "  - TF_STATE_CONTAINER" $White
    Write-ColorOutput "" $White
    
    # Create service principal
    Write-ColorOutput "🔐 Creating service principal for CI/CD..." $Yellow
    
    $subscriptionId = az account show --query id -o tsv
    $spName = "sp-marketplace-cicd-$(Get-Date -Format 'yyyyMMdd')"
    
    Write-ColorOutput "Creating service principal: $spName" $Yellow
    $spOutput = az ad sp create-for-rbac --name $spName --role contributor --scopes "/subscriptions/$subscriptionId" --sdk-auth
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ Service principal created successfully" $Green
        Write-ColorOutput "" $White
        Write-ColorOutput "🔑 AZURE_CREDENTIALS secret value:" $Blue
        Write-ColorOutput $spOutput $White
        Write-ColorOutput "" $White
        Write-ColorOutput "Copy this JSON and add it as AZURE_CREDENTIALS secret in GitHub" $Yellow
    } else {
        Write-ColorOutput "❌ Failed to create service principal" $Red
        return $false
    }
    
    Write-ColorOutput "📖 CI/CD pipeline is configured in .github/workflows/azure-functions-ci-cd.yml" $Green
    Write-ColorOutput "🔧 Configure the secrets in GitHub repository settings to enable automated deployments" $Yellow
    
    return $true
}

function Show-Summary {
    Write-ColorOutput "" $White
    Write-ColorOutput "🎉 Setup completed!" $Green
    Write-ColorOutput "===================" $Green
    Write-ColorOutput "" $White
    
    if ($DeployInfrastructure -or $DeployFunction) {
        Set-Location "terraform"
        $functionUrl = terraform output -raw function_app_url 2>$null
        
        if (![string]::IsNullOrEmpty($functionUrl)) {
            Write-ColorOutput "🌐 Function App URL: $functionUrl" $Green
            Write-ColorOutput "" $White
            Write-ColorOutput "Available endpoints:" $Blue
            Write-ColorOutput "  - Health: GET $functionUrl/api/health" $White
            Write-ColorOutput "  - AI Status: GET $functionUrl/api/ai-status" $White
            Write-ColorOutput "  - Generate Description: POST $functionUrl/api/generate-description" $White
            Write-ColorOutput "" $White
        }
    }
    
    Write-ColorOutput "Next steps:" $Yellow
    Write-ColorOutput "1. Test your Azure Function endpoints" $White
    Write-ColorOutput "2. Update your frontend to use the new Function URLs" $White
    Write-ColorOutput "3. Configure monitoring and alerting" $White
    Write-ColorOutput "4. Set up automated testing" $White
    
    if ($SetupCICD) {
        Write-ColorOutput "5. Configure GitHub secrets for CI/CD automation" $White
    }
}

# Main execution
Write-ColorOutput "🚀 Azure Functions Setup Script" $Blue
Write-ColorOutput "===============================" $Blue
Write-ColorOutput "Environment: $Environment" $Yellow
Write-ColorOutput "" $White

# Check prerequisites
if (!(Test-Prerequisites)) {
    Write-ColorOutput "❌ Prerequisites check failed. Please install missing tools." $Red
    exit 1
}

# Set Azure context
if (!(Set-AzureContext)) {
    Write-ColorOutput "❌ Failed to set Azure context" $Red
    exit 1
}

# Initialize Terraform
if ($DeployInfrastructure -or $DeployFunction) {
    if (!(Initialize-Terraform)) {
        Write-ColorOutput "❌ Terraform initialization failed" $Red
        exit 1
    }
}

# Deploy infrastructure
if ($DeployInfrastructure) {
    if (!(Deploy-Infrastructure)) {
        Write-ColorOutput "❌ Infrastructure deployment failed" $Red
        exit 1
    }
}

# Deploy function code
if ($DeployFunction) {
    if (!(Deploy-FunctionCode)) {
        Write-ColorOutput "❌ Function deployment failed" $Red
        exit 1
    }
}

# Setup CI/CD
if ($SetupCICD) {
    Setup-CICD
}

# Show summary
Show-Summary

Write-ColorOutput "✅ Setup script completed successfully!" $Green
