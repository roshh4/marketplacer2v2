# CI/CD Pipeline Migration to AKS

## ✅ **Changes Made to GitHub Actions Pipeline**

### **Updated `.github/workflows/main-deploy.yml`:**

1. **Added kubectl Installation:**
   ```yaml
   - name: Install kubectl
     uses: azure/setup-kubectl@v3
     with:
       version: 'v1.30.0'
   ```

2. **Removed Container Apps Imports:**
   - Removed `azurerm_container_app_environment.marketplace`
   - Removed `azurerm_container_app.marketplace_backend`
   - Kept PostgreSQL and Storage imports

3. **Added AKS Deployment Step:**
   ```yaml
   - name: Deploy Kubernetes resources
     run: |
       # Get AKS credentials
       # Deploy k8s resources
       # Update image tag
       # Wait for rollout
       # Verify deployment
   ```

4. **Updated Backend URL Output:**
   - Now uses AKS cluster FQDN instead of Container Apps URL

## 🚀 **How the Updated Pipeline Works:**

### **Backend Deployment Flow:**
1. **Build & Push Docker Image** → Docker Hub with version tag
2. **Terraform Apply** → Creates/updates AKS infrastructure
3. **Get AKS Credentials** → Configures kubectl
4. **Deploy K8s Resources** → Applies namespace, secrets, deployment, service
5. **Update Image Tag** → Rolling update with new image
6. **Verify Deployment** → Checks pods and services status

### **Frontend Deployment:**
- Unchanged - still deploys to Azure Static Web Apps
- Gets backend URL from AKS cluster FQDN

## 🔧 **Required GitHub Secrets:**

Make sure these secrets are set in your GitHub repository:

- `DOCKERHUB_USERNAME` - Your Docker Hub username
- `DOCKERHUB_TOKEN` - Your Docker Hub access token
- `AZURE_CLIENT_ID` - Azure service principal client ID
- `AZURE_CLIENT_SECRET` - Azure service principal secret
- `AZURE_SUBSCRIPTION_ID` - Your Azure subscription ID
- `AZURE_TENANT_ID` - Your Azure tenant ID
- `DB_PASSWORD` - PostgreSQL database password
- `AZURE_STORAGE_ACCOUNT_NAME` - Storage account name
- `AZURE_STATIC_WEB_APPS_API_TOKEN` - Static Web App deployment token

## 🎯 **Pipeline Benefits:**

- ✅ **Zero-Downtime Deployments:** Rolling updates with kubectl
- ✅ **Version Tracking:** Each deployment gets a unique version tag
- ✅ **Infrastructure as Code:** Terraform manages all resources
- ✅ **Health Checks:** Waits for rollout completion
- ✅ **Verification:** Checks pod and service status
- ✅ **Rollback Capability:** Can easily rollback to previous image

## 🔄 **Deployment Process:**

1. **Push to main branch** → Triggers pipeline
2. **Build new image** → With timestamp + commit hash version
3. **Update infrastructure** → Terraform apply
4. **Deploy to AKS** → kubectl apply + rolling update
5. **Verify deployment** → Health checks and status verification
6. **Deploy frontend** → Static Web App with new backend URL

## 🚨 **Important Notes:**

- **First Run:** May take longer due to AKS cluster creation
- **Subsequent Runs:** Only image updates, much faster
- **Rollback:** Use `kubectl rollout undo deployment/marketplace-backend -n marketplace`
- **Monitoring:** Check GitHub Actions logs for deployment status

## 🔧 **Optional Improvements:**

1. **Add Health Checks:**
   ```yaml
   - name: Health Check
     run: |
       kubectl wait --for=condition=ready pod -l app=marketplace-backend -n marketplace --timeout=300s
   ```

2. **Add Slack Notifications:**
   ```yaml
   - name: Notify Slack
     uses: 8398a7/action-slack@v3
     with:
       status: ${{ job.status }}
       text: 'Deployment to AKS completed!'
   ```

3. **Add Database Migrations:**
   ```yaml
   - name: Run Database Migrations
     run: |
       kubectl exec -n marketplace deployment/marketplace-backend -- /app/migrate
   ```

Your CI/CD pipeline is now fully configured for AKS! 🎉
