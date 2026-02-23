# External Secrets Operator (ESO) - Demo Script Guide

## Overview

This repository now includes `run-demo.sh`, a comprehensive end-to-end demonstration script for the External Secrets Operator. The script handles all aspects of the demo including infrastructure setup, ESO installation, provider configuration, and all four demo scenarios.

## Quick Start

### Prerequisites

Before running the demo script, ensure you have:

- **Kubernetes Cluster**: Configure with `kubectl` (tested with Rancher Desktop, Minikube, etc.)
- **Helm**: For installing ESO and Vault
- **Terraform**: For infrastructure provisioning
- **AWS CLI**: `aws` (if testing AWS providers)
- **Azure CLI**: `az` (if testing Azure provider)
- **jq**: For JSON parsing
- **Environment Variables**: AWS/Azure credentials configured in `.env` file

### Installation

1. **Clone/Navigate to the repository**:
   ```bash
   cd /path/to/eso-demo
   ```

2. **Make scripts executable** (if not already):
   ```bash
   chmod +x run-demo.sh
   chmod +x eso-utils.sh
   ```

3. **Configure `.env` file** with your credentials:
   ```bash
   cp .env.template .env
   # Edit .env with your AWS and Azure credentials
   ```

### Running the Demo

#### 1. **View Help** (Recommended First Step)
```bash
./scripts/run-demo.sh --help
```

This shows all available options and examples.

#### 2. **Preview Mode (Dry-Run)**
```bash
./scripts/run-demo.sh --dry-run
```

This displays all commands that would be executed without actually running them. Perfect for training and understanding the process.

#### 3. **Run Full Demo with Default Provider (Azure)**
```bash
./scripts/run-demo.sh
```

This runs the complete demo with Azure Key Vault as the external provider.

#### 4. **Run with Specific Provider**
```bash
# Using Vault Backend
./scripts/run-demo.sh --provider vault

# Using AWS Secrets Manager
./scripts/run-demo.sh --provider awssm

# Using AWS Parameter Store
./scripts/run-demo.sh --provider awsps

# Using Kubernetes Provider (simulated multi-cluster)
./scripts/run-demo.sh --provider k8s
```

#### 5. **Skip Specific Components**
```bash
# Skip Azure infrastructure setup
./scripts/run-demo.sh --skip-azure

# Skip Vault setup
./scripts/run-demo.sh --skip-vault

# Skip all Terraform-based infrastructure
./scripts/run-demo.sh --skip-tf

# Useful for: Quick testing, no AWS account, no Azure subscription, etc.
```

#### 6. **Just Cleanup Resources**
```bash
./scripts/run-demo.sh --cleanup-only
```

This removes all demo resources without running the demo again.

#### 7. **Preserve Resources After Demo**
```bash
./scripts/run-demo.sh --no-cleanup
```

This runs the full demo but doesn't ask about cleanup at the end, leaving resources in your cluster.

## Demo Scenarios Included

The script runs 4 complete demos:

### Demo 1: Pull Secrets
Demonstrates fetching secrets from external providers via `ExternalSecrets`.

```bash
kubectl get externalsecret -n eso-demo
kubectl get secret -n eso-demo
```

### Demo 2: Switch Providers
Shows how to dynamically switch between providers without modifying the `ExternalSecret` definition.

```bash
# Secrets remain accessible through different backends
kubectl patch externalsecret data-by-name -n eso-demo \
  --type merge -p '{"spec":{"secretStoreRef":{"name":"vault-secret-store"}}}'
```

### Demo 3: Push Secrets
Demonstrates pushing secrets from the cluster to external providers using `PushSecrets`.

```bash
kubectl get pushsecret -n eso-demo
```

### Demo 4: Generators
Shows secret generation using built-in generators (Password, Fake, etc.).

```bash
kubectl get fake,password -n eso-demo
```

## Utility Script: `eso-utils.sh`

A companion utility script for common ESO operations during and after the demo.

### Quick Examples

```bash
# Show overall status
./scripts/eso-utils.sh status

# List all synced secrets
./scripts/eso-utils.sh secrets

# List ClusterSecretStores
./scripts/eso-utils.sh stores

# Inspect a specific secret
./scripts/eso-utils.sh inspect data-by-name

# Decode secret values
./scripts/eso-utils.sh decode data-by-name

# Switch a secret to use a different provider
./scripts/eso-utils.sh switch-provider data-by-name vault-secret-store

# View ExternalSecretes status
./scripts/eso-utils.sh externals

# View Generators
./scripts/eso-utils.sh generators

# Check if syncing is working
./scripts/eso-utils.sh test-sync

# View ESO operator logs
./scripts/eso-utils.sh logs

# Setup port-forward to Vault
./scripts/eso-utils.sh vault

# Full help
./scripts/eso-utils.sh help
```

## Common Use Cases

### Use Case 1: Demo to a Classroom

```bash
# On your presentation machine:
./scripts/run-demo.sh --dry-run

# This shows all commands students should understand.
# Then explain each section and why it's needed.

# In a terminal on the side, run:
./scripts/run-demo.sh

# And use eso-utils to show status live:
watch -n 2 './scripts/eso-utils.sh status'
```

### Use Case 2: Multi-Provider Comparison

```bash
# Setup the demo
./scripts/run-demo.sh --provider azure

# After demo completes, try switching manually:
./scripts/eso-utils.sh switch-provider data-by-name awssm-secret-store

# Check the value changed but ExternalSecret didn't:
./scripts/eso-utils.sh decode data-by-name
```

### Use Case 3: Quick Testing (Skip AWS/Azure)

```bash
# Just test with Vault and Kubernetes providers
./scripts/run-demo.sh --provider vault --skip-aws --skip-azure
```

### Use Case 4: Understand Each Step

```bash
# 1. First, preview all commands:
./scripts/run-demo.sh --dry-run | tee demo-commands.log

# 2. Run the demo slowly (with watches):
./scripts/run-demo.sh

# 3. Monitor effects in real-time:
watch -n 1 './scripts/eso-utils.sh externals'

# 4. Inspect individual resources:
./scripts/eso-utils.sh inspect data-by-name
./scripts/eso-utils.sh logs externalsecret
```

### Use Case 5: Validate Installation Post-Demo

```bash
# Check if everything worked:
./scripts/eso-utils.sh test-sync

# View what was created:
./scripts/eso-utils.sh stores
./scripts/eso-utils.sh externals
./scripts/eso-utils.sh secrets

# View logs for any errors:
./scripts/eso-utils.sh logs
```

## Command Output Explanation

The script prints all commands it executes in YELLOW:

```
$ helm repo add external-secrets https://charts.external-secrets.io
$ helm repo update
$ helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace --set installCRDs=true
```

This allows anyone viewing the terminal to:
- Learn what's being executed
- Copy-paste commands for manual testing
- Understand the ESO setup process
- Create custom variations

## Environment File (`.env`)

The script uses environment variables from a `.env` file in the project root.

### Template (`.env.template`)
```bash
# AWS Configuration
AWS_ACCOUNTID=your_account_id
AWS_DEFAULT_REGION=us-east-1
AWS_PROFILE=your_profile_name
AWS_SHARED_CREDENTIALS_FILE=/path/to/.aws/credentials

# Azure Configuration
ARM_SUBSCRIPTION_ID=your_subscription_id
AZURE_SUBSCRIPTION_ID=your_subscription_id
```

### Creating Your `.env`
```bash
cp .env.template .env
# Edit .env with your actual values
```

## Troubleshooting

### Problem: "Cannot connect to Kubernetes cluster"

**Solution**: Verify `kubectl` is configured:
```bash
kubectl cluster-info
kubectl config current-context
```

### Problem: "Missing required tools"

**Solution**: Check which tool is missing:
```bash
command -v kubectl helm terraform jq
```

Install missing tools using your package manager (brew on macOS, apt on Linux, etc.).

### Problem: "AWS credentials not found"

**Solution**: Ensure `.env` file is configured:
```bash
cat .env
aws configure  # Reconfigure AWS if needed
```

### Problem: "Azure credentials not working"

**Solution**: Login to Azure:
```bash
az login
az account show
```

### Problem: "ExternalSecrets not syncing"

**Solution**: Check status and logs:
```bash
./scripts/eso-utils.sh status
./scripts/eso-utils.sh logs
./scripts/eso-utils.sh test-sync
```

### Problem: "Cleanup failed"

**Solution**: Manual cleanup:
```bash
kubectl delete -n eso-demo externalsecret --all
kubectl delete -n eso-demo password --all
kubectl delete -n eso-demo fake --all
kubectl delete -n eso-demo pushsecret --all
kubectl delete clustersecretstore --all
kubectl delete ns eso-demo cred remote-cluster
```

## Advanced Usage Examples

### Example 1: Run Demo Step-by-Step with Manual Inspection

```bash
# 1. Install just ESO
./scripts/run-demo.sh --dry-run --skip-aws --skip-azure | head -30

# 2. Setup infrastructure
./scripts/run-demo.sh --skip-aws --skip-azure --provider vault

# 3. Inspect what was created
./scripts/eso-utils.sh stores
./scripts/eso-utils.sh externals

# 4. Manually demo switching
kubectl edit externalsecret data-by-name -n eso-demo
```

### Example 2: Compare All Providers

```bash
# Run demo with each provider
for provider in azure awssm vault k8s; do
  echo "Testing with $provider..."
  ./scripts/run-demo.sh --provider $provider --no-cleanup
  ./scripts/eso-utils.sh status
  read -p "Press Enter to continue..."
done
```

### Example 3: Generate Training Documentation

```bash
# Capture all commands to a file
./scripts/run-demo.sh --dry-run > training-commands.txt

# Capture status snapshots
./scripts/eso-utils.sh status > before-demo.txt
./scripts/run-demo.sh
./scripts/eso-utils.sh status > after-demo.txt

# View changes
diff before-demo.txt after-demo.txt
```

## File Structure

```
eso-demo/
├── run-demo.sh              # Main demo script (NEW!)
├── eso-utils.sh             # Utility script for inspection (NEW!)
├── DEMO_GUIDE.md            # This file (NEW!)
├── .env                     # Environment variables (create from template)
├── .env.template            # Template for .env (updated)
├── README.md                # Original project documentation
├── ClusterSecretStores/     # Template YAML for secret stores
├── ExternalSecrets/         # Demo ExternalSecret resources
├── PushSecrets/             # Demo PushSecret resources
├── Generators/              # Demo Generator resources
├── terraform/               # Infrastructure as Code
│   ├── aws/                 # AWS provider infrastructure
│   ├── azure/               # Azure provider infrastructure
│   ├── k8s/                 # Kubernetes provider setup
│   └── vault/               # Vault infrastructure
└── scripts/                 # Utility scripts
```

## Script Features

✅ **Full Automation**: Complete setup from prerequisites to cleanup
✅ **Dry-Run Mode**: Preview commands without executing
✅ **Provider Selection**: Choose which external provider to demo
✅ **Modular Setup**: Skip specific components (AWS, Azure, Vault, Terraform)
✅ **Verbose Output**: Every command printed for education
✅ **Error Handling**: Graceful handling of failures with clear messages
✅ **Color-Coded Output**: Easy to read terminal output with status indicators
✅ **Interactive Cleanup**: Option to preserve resources for further testing
✅ **Utility Functions**: Helper script for common operations
✅ **Demo Scenarios**: Runs all 4 demos automatically

## System Requirements

| Component | Version | Notes |
|-----------|---------|-------|
| kubectl | 1.20+ | Tested with Rancher Desktop latest |
| Kubernetes | 1.20+ | Any cluster (Minikube, EKS, AKS, etc.) |
| Helm | 3.0+ | For package management |
| Terraform | 1.0+ | For infrastructure provisioning |
| jq | 1.6+ | For JSON parsing |
| AWS CLI | Latest | Required only for AWS demos |
| Azure CLI | Latest | Required only for Azure demos |
| Docker/Podman | Latest | Typically already installed |

## Performance Notes

- First run: 5-15 minutes (infrastructure creation + ESO installation)
- Subsequent runs: 2-5 minutes (reuses existing infrastructure)
- Cleanup time: 1-2 minutes

## Additional Resources

- [External Secrets Operator Documentation](https://external-secrets.io)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)
- [Azure Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/)
- [HashiCorp Vault](https://www.vaultproject.io/)

## Next Steps

1. Run `./run-demo.sh --help` to see all options
2. Try `./run-demo.sh --dry-run` to preview everything
3. Run `./run-demo.sh` for the full demo
4. Use `./eso-utils.sh` to inspect results
5. Modify and experiment!

## Support & Feedback

For issues or questions:
1. Check the [README.md](README.md) for the original documentation
2. Review ESO logs: `./eso-utils.sh logs`
3. Check resource status: `./eso-utils.sh status`
4. Inspect resources manually with `kubectl describe`

---

**Happy demonstrating!** 🚀
