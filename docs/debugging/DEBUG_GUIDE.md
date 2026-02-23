# 🐛 ESO Demo Debugging Guide

Troubleshooting common issues when running the ESO demo.

## ✅ Recent Fixes Applied

### Fix 1: Kubernetes Terraform Context Error
**Issue**: `Error: Provider configuration: cannot load Kubernetes client config - context "minikube" does not exist`

**Root Cause**: Terraform was hardcoded to use "minikube" context, but you're using "rancher-desktop"

**Fixed**: Updated `terraform/k8s/main.tf` to use the current kubectl context automatically (no longer hardcoded to minikube)

**Files Updated**:
- `terraform/k8s/main.tf` - Now uses current context
- `ClusterSecretStores/kubernetes/k8s-secretstore.template.yaml` - Now uses flexible port
- `run-demo.sh` - Improved CLUSTER_IP and CLUSTER_PORT extraction

---

## 🔍 Common Issues & Solutions

### Issue 1: Terraform Apply Fails with Context Error

```
Error: Provider configuration: cannot load Kubernetes client config
context "minikube" does not exist
```

**Solution**:
```bash
# 1. Verify your current context
kubectl config current-context
# Should show: rancher-desktop (or your cluster name)

# 2. The scripts are now fixed to use the current context
# Just re-run the demo
./scripts/run-demo.sh --provider k8s

# 3. Or specifically test K8s infrastructure setup
cd terraform/k8s
terraform init
terraform apply -auto-approve
```

### Issue 2: Kubernetes ClusterSecretStore Connection Failed

**Symptoms**:
```bash
kubectl describe clustersecretstore k8s-secret-store
# Shows: error connecting to API server
```

**Debugging**:
```bash
# Check if the kubeconfig CA is available
kubectl get configmap kube-root-ca.crt -n eso-demo -o yaml

# Verify the API server URL
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'

# Check if service account has permissions
kubectl get clusterrolebinding | grep remote-sa
kubectl describe serviceaccount my-remote-sa -n eso-demo
```

**Solution**:
```bash
# For localhost clusters (rancher-desktop, minikube), you may need a workaround
# Option 1: Use port-forward
kubectl port-forward -n remote-cluster svc/kubernetes 6443:443 &

# Option 2: Skip K8s provider demo
./scripts/run-demo.sh --provider vault --skip-k8s

# Option 3: For cloud clusters, ensure network connectivity
```

### Issue 3: ExternalSecret Not Syncing

**Symptoms**:
```bash
kubectl get externalsecret -n eso-demo data-by-name
# Shows: status: NotReady or SecretSyncFailed
```

**Debugging**:
```bash
# Check ExternalSecret details
kubectl describe externalsecret data-by-name -n eso-demo

# View SecretStore status
kubectl get clustersecretstore
kubectl describe clustersecretstore azure-secret-store

# Check ESO operator logs
kubectl logs -n external-secrets deployment/external-secrets -f

# Test sync manually
./scripts/eso-utils.sh test-sync
```

**Common Causes & Solutions**:

| Cause | Solution |
|-------|----------|
| Wrong credentials | Verify `.env` file and re-run setup |
| Missing ClusterSecretStore | Check with `kubectl get clustersecretstore` |
| Provider not configured | Check if `--skip-X` flags skipped the setup |
| Secret doesn't exist in provider | Verify Terraform provisioning completed |
| RBAC permissions | Check ServiceAccount permissions |

### Issue 4: AWS Credentials Not Working

```bash
Error: authenticating with AWS: failed to refresh cached credentials
```

**Solution**:
```bash
# 1. Verify AWS credentials
aws sts get-caller-identity

# 2. Check .env file
cat .env | grep AWS

# 3. Reconfigure if needed
aws configure
aws configure --profile YOUR_PROFILE

# 4. Retry demo
./scripts/run-demo.sh --provider awssm
```

### Issue 5: Azure Credentials Not Working

```bash
Error: Azure authentication failed
```

**Solution**:
```bash
# 1. Login to Azure
az login

# 2. Set subscription
az account show
az account set --subscription YOUR_SUBSCRIPTION_ID

# 3. Check .env file
cat .env | grep AZURE

# 4. Verify service principal
az ad app list --filter "startswith(displayName,'External Secret')"

# 5. Retry demo
./scripts/run-demo.sh --provider azure
```

### Issue 6: Terraform State File Issues

```bash
Error: Error reading existing state file in working directory
```

**Solution**:
```bash
# 1. Clean up Terraform state
cd terraform/aws  # or azure, k8s, vault
rm -rf .terraform
rm terraform.tfstate*

# 2. Reinitialize
terraform init
terraform apply -auto-approve

# 3. Or just use the run-demo script which handles this
./scripts/run-demo.sh
```

### Issue 7: Helm Installation Fails

```bash
Error: Helm chart not found or installation timeout
```

**Solution**:
```bash
# 1. Check Helm repo
helm repo list

# 2. Update repos
helm repo update

# 3. Try again
helm install external-secrets external-secrets/external-secrets \
  -n external-secrets \
  --create-namespace \
  --set installCRDs=true

# 4. Or use the demo script
./scripts/run-demo.sh
```

---

## 🔧 Diagnostic Commands

Use these commands to gather information when debugging:

### Kubernetes Status
```bash
# Current context
kubectl config current-context

# Cluster info
kubectl cluster-info

# Nodes
kubectl get nodes

# ESO deployment
kubectl get deployment -n external-secrets
kubectl logs -n external-secrets deployment/external-secrets
```

### Demo Resources
```bash
# All namespaces
kubectl get ns | grep -E "eso-demo|cred|remote-cluster|external-secrets"

# All ClusterSecretStores
kubectl get clustersecretstore -o wide

# All ExternalSecrets
kubectl get externalsecret -A -o wide

# All synced secrets
kubectl get secret -n eso-demo -o wide

# All Generators
kubectl get fake,password -n eso-demo
```

### CloudCredentials
```bash
# AWS
aws sts get-caller-identity
aws configure list

# Azure
az account show
az account list

# Check env variables
env | grep -E "AWS|AZURE|ARM"
```

### Demo-Specific Diagnostics
```bash
# Run utility script
./scripts/eso-utils.sh status
./scripts/eso-utils.sh test-sync
./scripts/eso-utils.sh logs

# Check specific secret
./scripts/eso-utils.sh inspect data-by-name
./scripts/eso-utils.sh decode data-by-name
```

---

## 📋 Debug Workflow

When something fails:

### Step 1: Identify the Phase
```bash
# Check demo progress
kubectl get ns
kubectl get deployment -n external-secrets
kubectl get externalsecret -n eso-demo
```

### Step 2: Get Details
```bash
# Run utility script
./scripts/eso-utils.sh status

# View logs
./scripts/eso-utils.sh logs

# Check specific resources
kubectl describe externalsecret data-by-name -n eso-demo
kubectl describe clustersecretstore azure-secret-store
```

### Step 3: Fix & Retry

**For Kubernetes provider issues**:
```bash
cd terraform/k8s
terraform destroy -auto-approve
terraform init
terraform apply -auto-approve
./scripts/run-demo.sh --provider k8s --skip-aws --skip-azure
```

**For provider credential issues**:
```bash
# Re-run specific provider setup
./scripts/run-demo.sh --provider azure --skip-aws --skip-k8s --skip-vault

# Or skip and try another
./scripts/run-demo.sh --provider vault --skip-aws --skip-azure
```

**For full reset**:
```bash
# Clean everything
./scripts/run-demo.sh --cleanup-only

# Start fresh
./scripts/validate-setup.sh
./scripts/run-demo.sh
```

---

## 🐛 Known Workarounds

### Localhost Kubernetes (Rancher Desktop, Minikube)

**Issue**: K8s provider can't connect to API server via 127.0.0.1

**Workaround 1**: Use port-forward to expose the API
```bash
kubectl port-forward -n kube-system svc/kubernetes 6443:443 &
```

**Workaround 2**: Skip K8s provider and use other providers
```bash
./scripts/run-demo.sh --provider vault --skip-k8s
```

**Workaround 3**: For cloud clusters (EKS, AKS), ensure network policies allow ESO to reach the API server

### Large Objects/Timeouts

**Issue**: Terraform apply times out

**Solution**:
```bash
# Skip infrastructure setup and test ESO only
./scripts/run-demo.sh --skip-tf

# Or increase timeout
cd terraform/aws
terraform apply -auto-approve -lock-timeout=10m
```

### Memory Constraints

**Issue**: Cluster gets OOM, services fail

**Solution**:
```bash
# Check available memory
free -h  # Linux
vm_stat | grep Pages  # macOS

# Skip heavy services
./scripts/run-demo.sh --skip-vault

# Or reduce cluster size
```

---

## 🔄 Reset & Retry Strategy

### Complete Reset
```bash
# 1. Cleanup demo resources
./scripts/run-demo.sh --cleanup-only

# 2. Remove Terraform state
rm -rf terraform/*/terraform.tfstate* terraform/*/.terraform

# 3. Start fresh
./scripts/validate-setup.sh
./scripts/run-demo.sh
```

### Selective Reset
```bash
# Fix just one provider
terraform -chdir=terraform/kubernetes destroy -auto-approve
./scripts/run-demo.sh --provider k8s --skip-aws --skip-azure --skip-vault
```

### Rebuild ESO Only
```bash
# Remove ESO namespace
kubectl delete ns external-secrets

# Reinstall
helm install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace --set installCRDs=true
```

---

## 📝 Gathering Debug Information

When reporting an issue, gather this information:

```bash
# System info
uname -a
kubectl version

# Cluster context
kubectl config current-context
kubectl cluster-info

# Demo status
./scripts/eso-utils.sh status

# Recent logs
kubectl logs -n external-secrets deployment/external-secrets --tail=50

# Failed resource details
kubectl describe externalsecret NAME -n eso-demo
kubectl describe clustersecretstore NAME

# Environment
echo $KUBECONFIG
cat .env | grep -E "AWS|AZURE"
```

---

## 🆘 When All Else Fails

### Option 1: Start Completely Fresh
```bash
# Remove everything
kubectl delete ns eso-demo cred remote-cluster external-secrets vault 2>/dev/null
rm -rf terraform/*/terraform.tfstate* terraform/*/.terraform

# Reboot cluster if possible (Docker Desktop, Rancher Desktop menu)

# Start demo
./scripts/run-demo.sh
```

### Option 2: Use Minimal Provider Setup
```bash
# Use vault only (doesn't require cloud credentials)
./scripts/run-demo.sh --provider vault --skip-aws --skip-azure --skip-k8s
```

### Option 3: Manual Step-Through
```bash
# Run everything manually to see where it fails
./scripts/validate-setup.sh

# Create namespaces
kubectl create ns eso-demo cred

# Install ESO
helm install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace --set installCRDs=true

# Test ESO
kubectl get deployment -n external-secrets

# Add one provider at a time
# ... etc
```

---

## 🎯 Quick Fix Checklist

- [ ] Context is correct: `kubectl config current-context`
- [ ] Cluster is reachable: `kubectl cluster-info`  
- [ ] Credentials configured: `cat .env`
- [ ] AWS auth works: `aws sts get-caller-identity`
- [ ] Azure auth works: `az account show`
- [ ] Disk space: `df -h` (need ~5GB)
- [ ] Memory: `free -h` (need ~4GB)
- [ ] Terraform state clean: `ls terraform/*/terraform.tfstate*`
- [ ] ESO installed: `kubectl get deployment -n external-secrets`
- [ ] Providers created: `kubectl get clustersecretstore`

---

**Need more help?** Run:
```bash
./scripts/eso-utils.sh help
./scripts/run-demo.sh --help
cat DEMO_GUIDE.md
```
