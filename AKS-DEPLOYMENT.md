# AKS Deployment Guide

This guide explains how to deploy the Marketplace application to Azure Kubernetes Service (AKS) instead of Azure Container Apps.

## Prerequisites

- Azure CLI installed and configured
- kubectl installed
- Terraform installed
- Docker (for building images)

## Architecture
deploy-aks
The AKS setup includes:
- **AKS Cluster**: Simple 2-node cluster with Standard_B2s VMs
- **PostgreSQL**: Azure Database for PostgreSQL Flexible Server
- **Storage**: Azure Blob Storage for images
- **Frontend**: Azure Static Web App (unchanged)

## Quick Start

1. **Set up your environment variables**:
   ```bash
   export TF_VAR_db_admin_password="your-secure-password"
   export TF_VAR_storage_account_name="your-unique-storage-name"
   ```

2. **Deploy using the script**:
   ```bash
   ./.sh
   ```

3. **Or deploy manually**:
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

## Configuration

### Terraform Variables

Update `terraform/variables.tf` or set environment variables:

- `db_admin_password`: PostgreSQL admin password
- `storage_account_name`: Unique Azure Storage account name
- `environment`: Environment name (default: "dev")
- `location`: Azure region (default: "Southeast Asia")

### Kubernetes Manifests

The `k8s/` directory contains:
- `namespace.yaml`: Marketplace namespace
- `secret.yaml`: Database and storage secrets
- `deployment.yaml`: Backend application deployment
- `service.yaml`: Internal service
- `ingress.yaml`: External access configuration

## Accessing Your Application

### Internal Access
```bash
# Port forward to access locally
kubectl port-forward service/marketplace-backend-service 8080:80 -n marketplace
```

### External Access

1. **Get the external IP**:
   ```bash
   kubectl get service -n ingress-nginx
   ```

2. **Update DNS**: Point your domain to the external IP

3. **Update ingress**: Edit `k8s/ingress.yaml` with your domain

4. **Apply ingress**:
   ```bash
   kubectl apply -f k8s/ingress.yaml
   ```

## Monitoring and Management

### Useful Commands

```bash
# View all resources
kubectl get all -n marketplace

# View pod logs
kubectl logs -f deployment/marketplace-backend -n marketplace

# Scale deployment
kubectl scale deployment marketplace-backend --replicas=3 -n marketplace

# Update image
kubectl set image deployment/marketplace-backend marketplace-backend=roshh4/marketplace-backend-alpine-amd64:new-tag -n marketplace
```

### Health Checks

The application includes:
- **Liveness Probe**: `/health` endpoint every 10 seconds
- **Readiness Probe**: `/health` endpoint every 5 seconds

## Cost Optimization

The current setup uses:
- **AKS**: 2 nodes × Standard_B2s (2 vCPU, 4GB RAM)
- **PostgreSQL**: B_Standard_B1ms (1 vCPU, 2GB RAM)
- **Storage**: Standard LRS

To reduce costs:
1. Scale down node count: `kubectl scale deployment marketplace-backend --replicas=1`
2. Use smaller VM sizes in `terraform/main.tf`
3. Enable cluster autoscaler

## Security Considerations

- Secrets are stored in Kubernetes secrets (not in plain text)
- Database requires SSL connections
- Ingress uses HTTPS with Let's Encrypt certificates
- Network policies can be added for additional security

## Troubleshooting

### Common Issues

1. **Pods not starting**:
   ```bash
   kubectl describe pod <pod-name> -n marketplace
   kubectl logs <pod-name> -n marketplace
   ```

2. **Database connection issues**:
   - Check firewall rules in PostgreSQL
   - Verify connection string in secrets

3. **Image pull errors**:
   - Ensure Docker image exists and is accessible
   - Check image tag in deployment

### Cleanup

To remove all resources:
```bash
cd terraform
terraform destroy
```

## Migration from Container Apps

If migrating from Container Apps:

1. **Backup data**: Export database and storage
2. **Deploy AKS**: Use this configuration
3. **Update DNS**: Point to new AKS endpoint
4. **Verify**: Test all functionality
5. **Cleanup**: Remove old Container Apps resources

## Support

For issues:
1. Check Kubernetes events: `kubectl get events -n marketplace`
2. Review application logs
3. Verify Terraform state: `terraform show`
