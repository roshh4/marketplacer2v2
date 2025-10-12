# Azure Functions Deployment Script for Windows PowerShell
# This script helps deploy the AI Description Azure Function

param(
    [Parameter(Mandatory=$true)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory=$false)]
    [string]$GeminiApiKey,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$false)]
    [switch]$CreateResources,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipTests
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
    
    # Check Azure CLI
    try {
        $azVersion = az --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Azure CLI is installed" $Green
        } else {
            throw "Azure CLI not found"
        }
    } catch {
        Write-ColorOutput "❌ Azure CLI is not installed. Please install it first." $Red
        return $false
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
        Write-ColorOutput "❌ Azure Functions Core Tools is not installed. Please install it first." $Red
        return $false
    }
    
    # Check Python
    try {
        $pythonVersion = python --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Python is installed: $pythonVersion" $Green
        } else {
            throw "Python not found"
        }
    } catch {
        Write-ColorOutput "❌ Python is not installed. Please install Python 3.8 or higher." $Red
        return $false
    }
    
    return $true
}

function Test-AzureLogin {
    Write-ColorOutput "🔍 Checking Azure login status..." $Blue
    
    try {
        $account = az account show 2>$null | ConvertFrom-Json
        if ($account) {
            Write-ColorOutput "✅ Logged in to Azure as: $($account.user.name)" $Green
            Write-ColorOutput "   Subscription: $($account.name)" $Green
            return $true
        }
    } catch {
        Write-ColorOutput "❌ Not logged in to Azure. Please run 'az login' first." $Red
        return $false
    }
    
    return $false
}

function Create-AzureResources {
    Write-ColorOutput "🏗️ Creating Azure resources..." $Blue
    
    # Create resource group
    Write-ColorOutput "Creating resource group: $ResourceGroup" $Yellow
    az group create --name $ResourceGroup --location $Location
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "❌ Failed to create resource group" $Red
        return $false
    }
    
    # Create storage account
    $storageAccount = "$($FunctionAppName.ToLower())storage"
    Write-ColorOutput "Creating storage account: $storageAccount" $Yellow
    az storage account create --name $storageAccount --location $Location --resource-group $ResourceGroup --sku Standard_LRS
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "❌ Failed to create storage account" $Red
        return $false
    }
    
    # Create function app
    Write-ColorOutput "Creating function app: $FunctionAppName" $Yellow
    az functionapp create --resource-group $ResourceGroup --consumption-plan-location $Location --runtime python --runtime-version 3.9 --functions-version 4 --name $FunctionAppName --storage-account $storageAccount
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "❌ Failed to create function app" $Red
        return $false
    }
    
    Write-ColorOutput "✅ Azure resources created successfully" $Green
    return $true
}

function Set-EnvironmentVariables {
    Write-ColorOutput "⚙️ Setting environment variables..." $Blue
    
    if ($GeminiApiKey) {
        Write-ColorOutput "Setting GEMINI_API_KEY..." $Yellow
        az functionapp config appsettings set --name $FunctionAppName --resource-group $ResourceGroup --settings "GEMINI_API_KEY=$GeminiApiKey"
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ GEMINI_API_KEY configured" $Green
        } else {
            Write-ColorOutput "❌ Failed to set GEMINI_API_KEY" $Red
            return $false
        }
    } else {
        Write-ColorOutput "⚠️ No Gemini API key provided. Function will use template fallback only." $Yellow
    }
    
    return $true
}

function Deploy-Function {
    Write-ColorOutput "🚀 Deploying function..." $Blue
    
    # Install dependencies
    Write-ColorOutput "Installing Python dependencies..." $Yellow
    pip install -r requirements.txt
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "❌ Failed to install dependencies" $Red
        return $false
    }
    
    # Deploy to Azure
    Write-ColorOutput "Publishing to Azure..." $Yellow
    func azure functionapp publish $FunctionAppName
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ Function deployed successfully" $Green
        return $true
    } else {
        Write-ColorOutput "❌ Failed to deploy function" $Red
        return $false
    }
}

function Test-Deployment {
    Write-ColorOutput "🧪 Testing deployed function..." $Blue
    
    # Get function URL
    $functionUrl = "https://$FunctionAppName.azurewebsites.net"
    
    # Test health endpoint
    try {
        Write-ColorOutput "Testing health endpoint..." $Yellow
        $response = Invoke-RestMethod -Uri "$functionUrl/api/health" -Method Get -TimeoutSec 30
        if ($response.status -eq "healthy") {
            Write-ColorOutput "✅ Health check passed" $Green
        } else {
            Write-ColorOutput "❌ Health check failed" $Red
            return $false
        }
    } catch {
        Write-ColorOutput "❌ Health check failed: $($_.Exception.Message)" $Red
        return $false
    }
    
    # Test AI status endpoint
    try {
        Write-ColorOutput "Testing AI status endpoint..." $Yellow
        $response = Invoke-RestMethod -Uri "$functionUrl/api/ai-status" -Method Get -TimeoutSec 30
        Write-ColorOutput "✅ AI status check passed" $Green
        Write-ColorOutput "   Gemini configured: $($response.gemini_configured)" $Green
    } catch {
        Write-ColorOutput "❌ AI status check failed: $($_.Exception.Message)" $Red
        return $false
    }
    
    # Test description generation
    try {
        Write-ColorOutput "Testing description generation..." $Yellow
        $testPayload = @{
            title = "Test Laptop"
            category = "Electronics"
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$functionUrl/api/generate-description" -Method Post -Body $testPayload -ContentType "application/json" -TimeoutSec 30
        if ($response.success) {
            Write-ColorOutput "✅ Description generation test passed" $Green
            Write-ColorOutput "   Model used: $($response.model_used)" $Green
            Write-ColorOutput "   Description: $($response.description)" $Green
        } else {
            Write-ColorOutput "❌ Description generation test failed" $Red
            return $false
        }
    } catch {
        Write-ColorOutput "❌ Description generation test failed: $($_.Exception.Message)" $Red
        return $false
    }
    
    Write-ColorOutput "✅ All deployment tests passed!" $Green
    return $true
}

# Main deployment process
Write-ColorOutput "🚀 Azure Functions Deployment Script" $Blue
Write-ColorOutput "====================================" $Blue

# Check prerequisites
if (-not (Test-Prerequisites)) {
    exit 1
}

# Check Azure login
if (-not (Test-AzureLogin)) {
    exit 1
}

# Create resources if requested
if ($CreateResources) {
    if (-not (Create-AzureResources)) {
        exit 1
    }
}

# Set environment variables
if (-not (Set-EnvironmentVariables)) {
    exit 1
}

# Deploy function
if (-not (Deploy-Function)) {
    exit 1
}

# Test deployment
if (-not $SkipTests) {
    Start-Sleep -Seconds 10  # Wait for deployment to complete
    if (-not (Test-Deployment)) {
        Write-ColorOutput "⚠️ Deployment completed but tests failed. Check the function manually." $Yellow
    }
} else {
    Write-ColorOutput "⚠️ Skipping deployment tests as requested." $Yellow
}

# Success message
Write-ColorOutput "" $Green
Write-ColorOutput "🎉 Deployment completed successfully!" $Green
Write-ColorOutput "Function URL: https://$FunctionAppName.azurewebsites.net" $Green
Write-ColorOutput "" $Green
Write-ColorOutput "Available endpoints:" $Green
Write-ColorOutput "  - Health: GET /api/health" $Green
Write-ColorOutput "  - AI Status: GET /api/ai-status" $Green
Write-ColorOutput "  - Generate Description: POST /api/generate-description" $Green
Write-ColorOutput "" $Green
Write-ColorOutput "Next steps:" $Yellow
Write-ColorOutput "1. Update your frontend to use the new Azure Function URL" $Yellow
Write-ColorOutput "2. Test with real product data" $Yellow
Write-ColorOutput "3. Monitor performance in Azure Portal" $Yellow

exit 0
