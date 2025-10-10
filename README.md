# Campus Marketplace - Full Stack Application

A modern campus marketplace application built with React, Go, and deployed on Azure Container Apps with automated CI/CD pipeline.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend API   │    │   Database      │
│   (React/Vite)  │◄──►│   (Go/Gin)      │◄──►│   (PostgreSQL)  │
│   Static Web App│    │   Container App │    │   Azure Flex    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   CDN/SSL       │    │   Ingress       │    │   Blob Storage  │
│   Azure Static  │    │   NGINX + TLS   │    │   Product Images│
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Features

- **User Authentication**: JWT-based auth with registration/login
- **Product Management**: Create, update, delete products with image uploads
- **AI-Powered Descriptions**: Gemini AI generates product descriptions from images
- **Content Safety**: Azure Content Safety API filters inappropriate content
- **Real-time Chat**: User-to-user messaging system
- **Favorites System**: Save and manage favorite products
- **Purchase Requests**: Buy/sell workflow management
- **Responsive Design**: Modern UI with glass morphism effects
- **HTTPS Security**: Let's Encrypt certificates via cert-manager
- **Auto-scaling**: Horizontal Pod Autoscaler (HPA) for backend

## 🛠️ Tech Stack

### Frontend
- **React 18** with TypeScript
- **Vite** for build tooling
- **Tailwind CSS** for styling
- **Axios** for API calls
- **React Router** for navigation

### Backend
- **Go 1.23** with Gin framework
- **GORM** for database ORM
- **JWT** for authentication
- **Azure Blob Storage** for file uploads
- **Gemini AI** for description generation
- **Azure Content Safety** for content moderation

### Infrastructure
- **Azure Container Apps**
- **Azure PostgreSQL Flexible Server**
- **Azure Blob Storage**
- **Azure Static Web Apps**
- **NGINX Ingress Controller**
- **cert-manager** for TLS certificates
- **Terraform** for infrastructure as code

### DevOps
- **GitHub Actions** for CI/CD
- **Docker** for containerization
- **Container Apps** for serverless container orchestration
- **Let's Encrypt** for SSL certificates

## 📁 Project Structure

```
├── frontend/                 # React frontend application
│   ├── src/
│   │   ├── components/      # Reusable UI components
│   │   ├── routes/          # Page components
│   │   ├── api/             # API client and services
│   │   ├── state/           # Context providers
│   │   └── types.ts         # TypeScript definitions
│   ├── package.json
│   └── vite.config.js
├── backend/                  # Go backend API
│   ├── handlers/            # HTTP request handlers
│   ├── models/              # Database models
│   ├── config/              # Configuration files
│   ├── middleware/          # Custom middleware
│   ├── routes/              # API route definitions
│   ├── main.go              # Application entry point
│   └── go.mod
├── terraform/                # Infrastructure as Code
│   ├── main.tf              # Main Terraform configuration
│   ├── variables.tf         # Terraform variables
│   └── outputs.tf           # Terraform outputs
├── .github/workflows/        # CI/CD pipeline
│   └── main-deploy.yml      # Main deployment workflow
└── README.md                # This file
```

## 🔧 Prerequisites

### Required Accounts & Services
- **Azure Account** with active subscription
- **GitHub Account** with repository access
- **Docker Hub Account** for container registry
- **Google AI Studio** account for Gemini API key
- **Azure AI Services** account for Content Safety

### Required Tools (for local development)
- **Node.js 18+** and npm
- **Go 1.23+**
- **Docker** and Docker Compose
- **Azure CLI** for Azure resource management
- **Terraform** for infrastructure deployment

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone <your-repo-url>
cd rev2-v2
```

### 2. Set Up GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions, and add these secrets:

#### Azure Credentials
- `AZURE_CLIENT_ID` - Azure service principal client ID
- `AZURE_CLIENT_SECRET` - Azure service principal secret
- `AZURE_SUBSCRIPTION_ID` - Your Azure subscription ID
- `AZURE_TENANT_ID` - Your Azure tenant ID

#### Database & Storage
- `DB_PASSWORD` - PostgreSQL database password
- `AZURE_STORAGE_ACCOUNT_NAME` - Azure storage account name
- `AZURE_STORAGE_CONNECTION_STRING` - Azure storage connection string

#### AI Services
- `GEMINI_API_KEY` - Google Gemini API key
- `CONTENT_SAFETY_KEY` - Azure Content Safety API key
- `CONTENT_SAFETY_ENDPOINT` - Azure Content Safety endpoint URL

#### Container Registry
- `DOCKERHUB_USERNAME` - Docker Hub username
- `DOCKERHUB_TOKEN` - Docker Hub access token

#### Frontend Deployment
- `AZURE_STATIC_WEB_APPS_API_TOKEN` - Azure Static Web Apps deployment token

#### Certificate Management
- `CERT_MANAGER_EMAIL` - Your email for Let's Encrypt certificates

### 3. Deploy Infrastructure

Simply push to the `main` branch to trigger the CI/CD pipeline:

```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

## 🚀 **Pipeline Deployment Process**

The CI/CD pipeline is designed to handle both scenarios seamlessly:

### **Fresh Deployment** 
Creates all resources from scratch for new environments

### **Existing Resources** 
Imports and updates existing resources for ongoing deployments

### **What Gets Created Automatically:**

#### **Azure Infrastructure**
- **Resource Group**: `rg-marketplace-dev`
- **Container App Environment**: `cae-marketplace-dev`
- **Container App**: `ca-marketplace-backend-dev`
- **Log Analytics Workspace**: `law-marketplace-dev`
- **PostgreSQL**: `psql-marketplace-dev` with database
- **Storage Account**: For product images

#### **Container Apps Features**
- **Auto-scaling**: Min 1, Max 3 replicas based on traffic
- **Ingress**: Built-in HTTPS endpoint with automatic SSL
- **Secrets Management**: Secure environment variables
- **Health Monitoring**: Built-in health checks and logging
- **Zero-downtime Deployments**: Rolling updates with traffic splitting

#### **Security & Networking**
- **HTTPS by Default**: Automatic SSL certificate management
- **Private Networking**: Secure communication between services
- **Managed Identity**: Secure access to Azure resources

### **Deployment Timeline:**

#### **First Run** (~15-20 minutes total)
1. **Terraform Init** → Downloads providers
2. **Terraform Apply** → Creates all Azure resources (~8-12 minutes)
3. **Container App Deploy** → Deploys your app with built-in ingress
4. **Frontend Deploy** → Builds and deploys to Static Web Apps

#### **Subsequent Runs** (~3-8 minutes)
- Only updates changed resources
- Faster deployment with existing infrastructure
- Rolling updates for zero-downtime deployments
- Container Apps handle scaling and health checks automatically

### **Pipeline Features:**
- ✅ **Idempotent**: Safe to run multiple times
- ✅ **Rolling Updates**: Zero-downtime deployments  
- ✅ **Resource Management**: Automatic scaling and optimization
- ✅ **Security**: Secrets management and secure deployments
- ✅ **Monitoring**: Health checks and deployment verification

**Just push to `main` branch and it will create everything!** 🚀

### 4. Access Your Application

After successful deployment (15-20 minutes), your application will be available at:

- **Frontend**: `https://ashy-coast-049069600.2.azurestaticapps.net`
- **Backend API**: `https://<your-ip>.nip.io/api`

## 🏃‍♂️ Local Development

### Backend Development

1. **Set up environment variables**:
```bash
cd backend
cp .env.example .env
# Edit .env with your local configuration
```

2. **Install dependencies**:
```bash
go mod tidy
```

3. **Run the server**:
```bash
go run main.go
```

The API will be available at `http://localhost:8080`

### Frontend Development

1. **Install dependencies**:
```bash
cd frontend
npm install
```

2. **Start development server**:
```bash
npm run dev
```

The frontend will be available at `http://localhost:5173`

## 🔐 Security Features

### Authentication & Authorization
- JWT-based authentication with secure token storage
- Protected API endpoints with middleware
- User session management

### Content Safety
- Azure Content Safety API integration
- Automatic image content moderation
- Inappropriate content filtering

### Network Security
- HTTPS enforcement with Let's Encrypt certificates
- CORS configuration for secure cross-origin requests
- NGINX ingress with security headers

### Data Protection
- Environment variables for sensitive configuration
- Container Apps secrets for credential management
- Encrypted database connections

## 📊 Monitoring & Observability

### Application Monitoring
- Health check endpoints (`/health`)
- Structured logging with request tracing
- Error handling and reporting

### Infrastructure Monitoring
- Container Apps resource monitoring
- Horizontal Pod Autoscaler (HPA) for automatic scaling
- NGINX ingress metrics

### Performance Optimization
- Docker multi-stage builds for smaller images
- Resource limits and requests in Container Apps
- CDN distribution for static assets

## 🔄 CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/main-deploy.yml`) handles:

### Backend Pipeline
1. **Build**: Create Docker image with version tag
2. **Push**: Upload to Docker Hub registry
3. **Infrastructure**: Deploy Azure resources with Terraform
4. **Container Apps**: Deploy backend to Container Apps
5. **SSL**: Issue Let's Encrypt certificate
6. **Health Check**: Verify deployment success

### Frontend Pipeline
1. **Build**: Create production build with API URL
2. **Deploy**: Upload to Azure Static Web Apps
3. **CDN**: Automatic global distribution

### Key Features
- **Idempotent**: Safe to run multiple times
- **Rolling Updates**: Zero-downtime deployments
- **Resource Management**: Automatic scaling and resource optimization
- **Security**: Secrets management and secure deployments

## 🛠️ Configuration

### Environment Variables

#### Backend Configuration
```bash
# Database
DB_HOST=psql-marketplace-dev.postgres.database.azure.com
DB_PORT=5432
DB_NAME=marketplace
DB_USER=marketplace_admin
DB_PASSWORD=<from-secret>
DB_SSLMODE=require

# Azure Storage
AZURE_STORAGE_ACCOUNT_NAME=marketplacestore2024
AZURE_STORAGE_CONNECTION_STRING=<from-secret>

# AI Services
GEMINI_API_KEY=<from-secret>
CONTENT_SAFETY_KEY=<from-secret>
CONTENT_SAFETY_ENDPOINT=<from-secret>

# Application
PORT=8080
GIN_MODE=release
JWT_SECRET=<generated-secret>
```

#### Frontend Configuration
```bash
# API Configuration
VITE_API_URL=https://<your-ip>.nip.io
VITE_NODE_ENV=production
```

### Container Apps Configuration

#### Resource Configuration
```hcl
template {
  min_replicas = 1
  max_replicas = 3

  container {
    name   = "marketplace-backend"
    image  = "roshh4/marketplace-backend-alpine-amd64:latest"
    cpu    = 0.5
    memory = "1Gi"
  }
}
```

#### Auto-scaling
Container Apps automatically handle scaling based on:
- HTTP requests per second
- CPU utilization
- Memory usage
- Custom metrics

## 🚨 Troubleshooting

### Common Issues

#### Certificate Issues
```bash
# Check Container App status
az containerapp show --name ca-marketplace-backend-dev --resource-group rg-marketplace-dev

# Check Container App logs
az containerapp logs show --name ca-marketplace-backend-dev --resource-group rg-marketplace-dev
```

#### CORS Issues
- Verify frontend domain in backend CORS configuration
- Check Container App ingress configuration
- Ensure HTTPS is properly configured

#### Resource Issues
```bash
# Check Container App status
az containerapp show --name ca-marketplace-backend-dev --resource-group rg-marketplace-dev --query "properties.runningStatus"

# Check resource usage
az monitor metrics list --resource /subscriptions/{subscription-id}/resourceGroups/rg-marketplace-dev/providers/Microsoft.App/containerApps/ca-marketplace-backend-dev --metric "CpuUsage,MemoryUsage"

# Check Container App events
az containerapp logs show --name ca-marketplace-backend-dev --resource-group rg-marketplace-dev --follow
```

#### Database Connection Issues
- Verify PostgreSQL firewall rules
- Check connection string format
- Ensure SSL is properly configured

### Debug Commands

```bash
# Check Container App ingress status
az containerapp show --name ca-marketplace-backend-dev --resource-group rg-marketplace-dev --query "properties.configuration.ingress"

# Check Container App URL
az containerapp show --name ca-marketplace-backend-dev --resource-group rg-marketplace-dev --query "properties.latestRevisionFqdn"

# View application logs
az containerapp logs show --name ca-marketplace-backend-dev --resource-group rg-marketplace-dev --follow

# Check Container App secrets
az containerapp secret list --name ca-marketplace-backend-dev --resource-group rg-marketplace-dev
```

## 📈 Scaling & Performance

### Horizontal Scaling
- **Auto-scaling**: Container Apps automatically scales based on HTTP requests and CPU usage
- **Load Balancing**: Built-in load balancing with automatic traffic distribution
- **Resource Optimization**: Efficient resource allocation with automatic optimization

### Vertical Scaling
- **Container Resources**: Adjustable memory and CPU limits per container
- **Environment Scaling**: Container App Environment scales automatically
- **Storage**: Azure Blob Storage scales automatically

### Performance Optimization
- **CDN**: Azure Static Web Apps provides global CDN
- **Caching**: Container Apps built-in caching for static content
- **Database**: PostgreSQL connection pooling
- **Images**: Optimized image uploads to Azure Blob Storage

## 🔧 Maintenance

### Regular Tasks
- **Certificate Renewal**: Automatic via cert-manager
- **Security Updates**: Regular dependency updates
- **Backup**: Database backups via Azure PostgreSQL
- **Monitoring**: Resource usage and performance monitoring

### Updates
- **Application**: Push to main branch triggers deployment
- **Infrastructure**: Terraform handles infrastructure updates
- **Dependencies**: Update go.mod and package.json as needed

## 📚 API Documentation

### Authentication Endpoints
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/me` - Get current user

### Product Endpoints
- `GET /api/products` - List all products
- `POST /api/products` - Create new product
- `GET /api/products/:id` - Get product by ID
- `PUT /api/products/:id` - Update product
- `DELETE /api/products/:id` - Delete product

### AI Endpoints
- `POST /api/products/generate-description` - Generate AI description
- `POST /api/products/generate-description-with-files` - Generate from files
- `GET /api/ai/status` - Check AI service status

### Chat Endpoints
- `GET /api/chats` - List user chats
- `POST /api/chats` - Create new chat
- `GET /api/chats/:id/messages` - Get chat messages
- `POST /api/chats/:id/messages` - Send message

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue in the GitHub repository
- Check the troubleshooting section above
- Review the application logs for error details

## 🎯 Roadmap

- [ ] Real-time notifications
- [ ] Advanced search and filtering
- [ ] Mobile app development
- [ ] Payment integration
- [ ] Advanced analytics dashboard
- [ ] Multi-language support

---

**Built with ❤️ for campus communities**
