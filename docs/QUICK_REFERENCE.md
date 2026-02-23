# ESO Demo Script - Quick Reference

## 📋 Most Common Commands

```bash
# View help
./scripts/run-demo.sh --help
./scripts/eso-utils.sh help

# Preview all commands (no execution)
./scripts/run-demo.sh --dry-run

# Run full demo
./scripts/run-demo.sh

# Just cleanup
./scripts/run-demo.sh --cleanup-only
```

## 🚀 Quick Start by Scenario

### Training / Classroom Demo
```bash
# Option 1: Preview mode (show what will happen)
./scripts/run-demo.sh --dry-run | less

# Option 2: Run and narrate
./scripts/run-demo.sh --provider vault  # Use Vault for simplicity

# Option 3: Live monitoring in another terminal
watch -n 2 './scripts/eso-utils.sh status'
```

### Fast Testing (No AWS/Azure)
```bash
./scripts/run-demo.sh --provider vault --skip-aws --skip-azure
```

### All Providers Demo
```bash
./scripts/run-demo.sh --provider awssm   # AWS Secrets Manager
./scripts/run-demo.sh --provider awsps   # AWS Parameter Store
./scripts/run-demo.sh --provider azure   # Azure Key Vault
./scripts/run-demo.sh --provider vault   # HashiCorp Vault
./scripts/run-demo.sh --provider k8s     # Kubernetes (multi-cluster sim)
```

## 🔍 Inspection Commands

| Command | Purpose |
|---------|---------|
| `./scripts/eso-utils.sh status` | Overall demo status |
| `./scripts/eso-utils.sh stores` | List ClusterSecretStores |
| `./scripts/eso-utils.sh externals` | List ExternalSecrets |
| `./scripts/eso-utils.sh secrets` | List synced Secrets |
| `./scripts/eso-utils.sh inspect SECRET_NAME` | Show secret details |
| `./scripts/eso-utils.sh decode SECRET_NAME` | Decode base64 values |
| `./scripts/eso-utils.sh test-sync` | Check sync status |
| `./scripts/eso-utils.sh logs` | View ESO operator logs |

## 🔄 Advanced Operations

### Switch Providers
```bash
# Manually (quick)
./scripts/eso-utils.sh switch-provider data-by-name vault-secret-store

# Watch the effect
watch 'kubectl get secret data-by-name -n eso-demo -o jsonpath={.data.secret-value} | base64 -d'
```

### Monitor in Real-Time
```bash
# Terminal 1: Run demo
./scripts/run-demo.sh

# Terminal 2: Watch resources
watch -n 1 './scripts/eso-utils.sh externals'

# Terminal 3: Watch logs
kubectl logs -n external-secrets deployment/external-secrets -f
```

### Deploy to Cloud (Vault)
```bash
./scripts/run-demo.sh --provider vault --no-cleanup
./scripts/eso-utils.sh vault  # Opens port-forward to Vault UI
```

## ⚙️ Configuration

### .env File
```bash
# Create from template
cp .env.template .env

# Essential variables:
# AWS_ACCOUNTID, AWS_DEFAULT_REGION, AWS_PROFILE
# ARM_SUBSCRIPTION_ID, AZURE_SUBSCRIPTION_ID
```

### Setup Requirements
```bash
# Check all prerequisites
kubectl cluster-info
kubectl config current-context
aws sts get-caller-identity
az account show
helm version
terraform --version
```

## 🛠️ Troubleshooting

| Issue | Solution |
|-------|----------|
| No cluster connection | `kubectl cluster-info` |
| Missing tools | `brew install helm terraform jq` |
| AWS credentials fail | `aws configure` + update `.env` |
| Azure credentials fail | `az login` + update `.env` |
| ExternalSecrets not syncing | `./scripts/eso-utils.sh test-sync` |
| Need to cleanup | `./run-demo.sh --cleanup-only` |

## 📊 What Each Demo Shows

| Demo | Command | Shows |
|------|---------|-------|
| 1 | `demo_1` (implicit) | Pull secrets from provider |
| 2 | `demo_2` (implicit) | Switch providers dynamically |
| 3 | `demo_3` (implicit) | Push secrets to provider |
| 4 | `demo_4` (implicit) | Generate secrets |

(All run automatically)

## 💡 Pro Tips

1. **For Teaching**: Use `--dry-run` first to show students what will happen
2. **For Testing**: Use `--skip-tf` to skip infrastructure and test ESO only
3. **For Speed**: Use `--provider vault --skip-aws --skip-azure` for fastest run
4. **For Debugging**: Use `eso-utils.sh logs` to see what ESO is doing
5. **For Exploration**: Use `--no-cleanup` and manually inspect resources

## 🔗 Useful Links

- ESO Helm Chart: https://charts.external-secrets.io
- ESO Docs: https://external-secrets.io
- Repo README: [README.md](README.md)
- Full Guide: [DEMO_GUIDE.md](DEMO_GUIDE.md)

## 📝 Command Cheat Sheet

```bash
# Cluster context
kubectl config current-context
kubectl get nodes

# ESO status
kubectl get deployment -n external-secrets
kubectl get crd | grep external-secret

# Demo namespace
kubectl get all -n eso-demo
kubectl get externalsecret -n eso-demo
kubectl get secret -n eso-demo

# Secret inspection
kubectl get secret SECRET_NAME -n eso-demo -o yaml
kubectl get secret SECRET_NAME -n eso-demo -o jsonpath={.data} | jq

# Manual port-forward to Vault
kubectl port-forward -n vault svc/vault 8200:8200

# Manual cleanup
kubectl delete ns eso-demo cred remote-cluster external-secrets vault
```

## 🎯 One-Liners

```bash
# Show everything
./scripts/run-demo.sh --dry-run | tee demo.log

# Quick with Vault only
./scripts/run-demo.sh --provider vault --skip-aws --skip-azure --no-cleanup

# Monitor during run
watch 'kubectl get externalsecret,secret -A | grep -v "^kube-"'

# Cleanup & start fresh
./scripts/run-demo.sh --cleanup-only && ./scripts/run-demo.sh --provider azure

# Export all secret values
kubectl get secret -n eso-demo -o json | jq '.items[] | {name: .metadata.name, keys: .data | keys}'
```

---

**Need help?** Run `./run-demo.sh --help` or check [DEMO_GUIDE.md](DEMO_GUIDE.md)
