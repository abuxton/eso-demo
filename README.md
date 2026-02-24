# 🔐 External Secrets Operator (ESO) - Complete Automated Demo

[![ESO](https://img.shields.io/badge/ESO-v0.9+-blue)](https://external-secrets.io)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.20%2B-blue)](https://kubernetes.io)
[![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-blue)](https://terraform.io)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

A **production-ready, fully automated demo** of the [External Secrets Operator](https://external-secrets.io) with multiple secret providers, comprehensive documentation, and hands-on examples.

- [🔐 External Secrets Operator (ESO) - Complete Automated Demo](#-external-secrets-operator-eso---complete-automated-demo)
	- [✨ What This Demo Includes](#-what-this-demo-includes)
		- [🎯 4 Complete Demo Scenarios](#-4-complete-demo-scenarios)
		- [🚀 Supported Providers](#-supported-providers)
		- [🛠️ Complete Automation](#️-complete-automation)
	- [📋 Prerequisites](#-prerequisites)
	- [🚀 Quick Start (5 minutes)](#-quick-start-5-minutes)
		- [1. Validate Your Setup](#1-validate-your-setup)
		- [2. Configure Environment Variables (if using AWS/Azure)](#2-configure-environment-variables-if-using-awsazure)
		- [3. Preview the Demo (Dry-Run)](#3-preview-the-demo-dry-run)
		- [4. Run the Full Demo](#4-run-the-full-demo)
		- [5. Monitor the Demo](#5-monitor-the-demo)
	- [📖 Documentation Guide](#-documentation-guide)
		- [🎯 Where to Start](#-where-to-start)
		- [🔍 Deep Dives](#-deep-dives)
	- [📁 Project Structure](#-project-structure)
	- [🎮 Using the Demo Scripts](#-using-the-demo-scripts)
		- [Main Script: `./scripts/run-demo.sh`](#main-script-scriptsrun-demosh)
		- [Utility Script: `./scripts/eso-utils.sh`](#utility-script-scriptseso-utilssh)
		- [Setup Validation: `./scripts/validate-setup.sh`](#setup-validation-scriptsvalidate-setupsh)
		- [Additional Provider Manager: `./scripts/manage-providers.sh`](#additional-provider-manager-scriptsmanage-providerssh)
	- [🔄 Demo Workflow](#-demo-workflow)
	- [📊 Understanding the Demos](#-understanding-the-demos)
		- [Demo 1: Pull Secrets from External Providers ✅](#demo-1-pull-secrets-from-external-providers-)
		- [Demo 2: Switch Providers Dynamically ✅](#demo-2-switch-providers-dynamically-)
		- [Demo 3: Push Secrets to External Providers ✅](#demo-3-push-secrets-to-external-providers-)
		- [Demo 4: Generate Secrets ✅](#demo-4-generate-secrets-)
	- [✅ Success: Verify Demo Results](#-success-verify-demo-results)
	- [🐛 Troubleshooting](#-troubleshooting)
		- [Common Issues](#common-issues)
		- [Debug Commands](#debug-commands)
	- [📚 Additional Resources](#-additional-resources)
		- [External Docs](#external-docs)
		- [Related Demos](#related-demos)
	- [📝 Project History](#-project-history)
	- [👨‍💻 Contributing](#-contributing)
	- [📄 License](#-license)
	- [🎯 Quick Links](#-quick-links)


## ✨ What This Demo Includes

This repository provides an **end-to-end automated demo** that showcases:

![run-demo](docs/_assets/demo-k8s-only.gif)

### 🎯 4 Complete Demo Scenarios

1. **Demo 1: Pull Secrets from External Providers**
   - Retrieve secrets from AWS Secrets Manager, AWS Parameter Store, Azure Key Vault, HashiCorp Vault, or Kubernetes
   - Show real-time syncing with `ExternalSecrets`

2. **Demo 2: Switch Providers Dynamically**
   - Change backend providers without modifying `ExternalSecret` definitions
   - Demonstrate multi-provider flexibility

3. **Demo 3: Push Secrets to External Providers**
   - Use `PushSecrets` to push cluster secrets to external backends
   - Show secure secret distribution

4. **Demo 4: Generate Secrets Using Generators**
   - Create passwords using generators
   - Generate fake/test data
   - Demonstrate dynamic secret generation

### 🚀 Supported Providers

**Core Providers** (seamlessly integrated):
- **AWS**: Secrets Manager (SecretsManager) & Parameter Store (ParameterStore)
- **Azure**: Key Vault
- **HashiCorp Vault**: Local or remote instances
- **Kubernetes**: Multi-cluster secret synchronization

**Additional Providers** (use `--additional-provider` flag):
- **Conjur**: CyberArk Conjur Open Source (via Docker Compose)

See [PROVIDER_INTEGRATION.md](docs/PROVIDER_INTEGRATION.md) for how to add new providers.

### 🛠️ Complete Automation

- ✅ **One-command demo execution** - `./scripts/run-demo.sh`
- ✅ **Dry-run mode** - Preview all commands before running
- ✅ **Provider selection** - Choose specific providers or run all
- ✅ **Prerequisites validation** - `./scripts/validate-setup.sh`
- ✅ **Inspection utilities** - `./scripts/eso-utils.sh` for monitoring
- ✅ **Automatic cleanup** - Remove all resources when done

## 📋 Prerequisites

- **Kubernetes cluster** (1.20+): rancher-desktop, minikube, EKS, GKE, or any K8s cluster
- **kubectl**: Configured and connected to your cluster
- **Helm** (3.0+): For installing ESO
- **Terraform** (1.5+): For provisioning infrastructure
- **jq**: For JSON parsing
- **AWS CLI & credentials** (optional): For AWS provider demos
- **Azure CLI & credentials** (optional): For Azure provider demos

## 🚀 Quick Start (5 minutes)

### 1. Validate Your Setup
```bash
cd path/to/eso-demo
./scripts/validate-setup.sh
```

### 2. Configure Environment Variables (if using AWS/Azure)
```bash
# Copy template and edit with your credentials
cp .env.template .env
# Edit AWS_ACCOUNTID, ARM_SUBSCRIPTION_ID, etc. if needed
```

### 3. Preview the Demo (Dry-Run)
```bash
./scripts/run-demo.sh --dry-run
```

### 4. Run the Full Demo

**Option A: With Vault (simplest - no cloud credentials needed)**
```bash
./scripts/run-demo.sh --provider vault --skip-aws --skip-azure
```

**Option B: Full demo with all providers**
```bash
source .env  # Load AWS/Azure credentials
./scripts/run-demo.sh
```

**Option C: With additional provider (Conjur)**
```bash
./scripts/run-demo.sh --provider vault --additional-provider conjur --skip-aws --skip-azure
```

**Option D: Local-only demo**
```bash
./scripts/run-demo.sh --provider k8s --skip-tf --skip-azure --skip-aws
```

### 5. Monitor the Demo
```bash
# In a new terminal, watch the demo progress
watch -n 2 './scripts/eso-utils.sh status'
```

## 📖 Documentation Guide

We've created comprehensive documentation to help you get the most out of this demo:

### 🎯 Where to Start

| Document | Purpose | Time |
|----------|---------|------|
| **[START_HERE.md](docs/START_HERE.md)** | 👈 **Begin here!** Complete guide | 10 min |
| **[QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)** | Command cheat sheet | 5 min |
| **[DEMO_GUIDE.md](docs/DEMO_GUIDE.md)** | Detailed walkthrough of each demo | 15 min |
| **[IMPLEMENTATION_SUMMARY.md](docs/IMPLEMENTATION_SUMMARY.md)** | How the automation works | 10 min |

### 🔍 Deep Dives

| Document | Purpose |
|----------|---------|
| **[PROJECT_SUMMARY.md](docs/PROJECT_SUMMARY.md)** | Full project inventory & architecture |
| **[PROVIDER_INTEGRATION.md](docs/PROVIDER_INTEGRATION.md)** | How to add new optional providers (standardized guide) |
| **[DEBUG_GUIDE_UPDATED.md](docs/debugging/DEBUG_GUIDE_UPDATED.md)** | Troubleshooting guide & error solutions |
| **[API_VERSION_FIX.md](docs/fixes/API_VERSION_FIX.md)** | API compatibility details |
| **[FIXES_APPLIED.md](docs/fixes/FIXES_APPLIED.md)** | Session fixes & improvements |

## 📁 Project Structure

```
eso-demo/
├── docs/                          # 📚 Comprehensive documentation
│   ├── START_HERE.md              # ➡️ BEGIN HERE!
│   ├── QUICK_REFERENCE.md         # Command cheat sheet
│   ├── DEMO_GUIDE.md              # Detailed walkthrough
│   ├── IMPLEMENTATION_SUMMARY.md   # Technical architecture
│   ├── PROJECT_SUMMARY.md         # Project overview
│   ├── debugging/                 # Troubleshooting & fixes
│   └── fixes/                     # Applied fixes
├── scripts/                       # 🚀 Main automation scripts
│   ├── run-demo.sh                # Main demo orchestrator (1000+ lines)
│   ├── eso-utils.sh               # Inspection & debugging utilities
│   ├── validate-setup.sh          # Prerequisites validation
│   ├── aws_cred.sh                # AWS credential helper
│   └── azure_cred.sh              # Azure credential helper
├── terraform/                     # 🏗️ Infrastructure as Code
│   ├── aws/                       # AWS provider setup (IAM, secrets)
│   ├── azure/                     # Azure provider setup (Key Vault)
│   ├── k8s/                       # Kubernetes provider setup
│   └── vault/                     # HashiCorp Vault setup
├── ClusterSecretStores/           # 🔐 Provider SecretStore templates
│   ├── aws/                       # AWS Secrets Manager & Parameter Store
│   ├── azure-key-vault/           # Azure Key Vault
│   ├── hashicorp-vault/           # Vault SecretStore
│   └── kubernetes/                # Kubernetes SecretStore
├── ExternalSecrets/               # 📦 Demo ExternalSecret resources
│   ├── data-by-name.yaml
│   ├── data-fetch-tags.yaml
│   └── ... (6 demo variations)
├── Generators/                    # 🔧 Secret generators
│   ├── fake.yaml                  # Fake data generator
│   └── password.yaml              # Random password generator
├── PushSecrets/                   # ⬆️ Push demo - push to external backends
└── README.md                      # This file
```

## 🎮 Using the Demo Scripts

### Main Script: `./scripts/run-demo.sh`

Fully automated end-to-end demo with all infrastructure setup and cleanup.

**Usage:**
```bash
./scripts/run-demo.sh [OPTIONS]

Options:
  --help              Show all available options
  --dry-run           Preview commands without executing
  --provider PROV     Specify provider: vault|awssm|awsps|azure|k8s
                      (default: azure)
  --skip-aws          Skip AWS setup
  --skip-azure        Skip Azure setup
  --skip-vault        Skip Vault setup
  --skip-k8s          Skip Kubernetes provider setup
  --cleanup-only      Run cleanup only
  --no-cleanup        Don't cleanup at end
```

**Common Examples:**
```bash
# Check what will happen (don't run anything)
./scripts/run-demo.sh --provider vault --dry-run

# Run with Vault (no cloud creds needed, ~5 minutes)
./scripts/run-demo.sh --provider vault --skip-aws --skip-azure

# Full demo with all providers (~10 minutes)
./scripts/run-demo.sh

# Just clean up resources
./scripts/run-demo.sh --cleanup-only
```

### Utility Script: `./scripts/eso-utils.sh`

Inspect, debug, and monitor ESO resources in real-time.

**Commands:**
```bash
./scripts/eso-utils.sh status        # Overall demo status
./scripts/eso-utils.sh stores        # List ClusterSecretStores
./scripts/eso-utils.sh externals     # List ExternalSecrets
./scripts/eso-utils.sh secrets       # List synced secrets
./scripts/eso-utils.sh generators    # List generators
./scripts/eso-utils.sh inspect NAME  # Show secret details
./scripts/eso-utils.sh decode NAME   # Decode base64 values
./scripts/eso-utils.sh logs          # Show ESO operator logs
./scripts/eso-utils.sh help          # See all commands
```

**Live Monitoring:**
```bash
# Watch ESO sync in real-time
watch -n 2 './scripts/eso-utils.sh status'

# Monitor ExternalSecrets as they sync
watch -n 1 './scripts/eso-utils.sh externals'
```

### Setup Validation: `./scripts/validate-setup.sh`

Verify all prerequisites are installed and configured.

```bash
./scripts/validate-setup.sh

# Shows:
# ✓ kubectl connectivity
# ✓ Helm, Terraform, jq installation
# ✓ AWS/Azure CLI availability
# ✓ Cluster permissions
# ⚠ Warnings for disk/memory constraints
```

### Additional Provider Manager: `./scripts/manage-providers.sh`

Manage optional secret providers (like Conjur) that extend the core demo.

**Commands:**
```bash
./scripts/manage-providers.sh list                    # List available providers
./scripts/manage-providers.sh setup conjur            # Start Conjur
./scripts/manage-providers.sh status conjur           # Check Conjur status
./scripts/manage-providers.sh cleanup conjur          # Stop Conjur
./scripts/manage-providers.sh setup conjur --dry-run  # Preview commands
```

**Integration with run-demo.sh:**
```bash
# Include Conjur in the main demo
./scripts/run-demo.sh --provider vault --additional-provider conjur

# Skip a provider
./scripts/run-demo.sh --skip-conjur
```

See [PROVIDER_INTEGRATION.md](docs/PROVIDER_INTEGRATION.md) for how to add new providers.

## 🔄 Demo Workflow

The demo automates this complete workflow:

1. **Validation** - Check prerequisites
2. **Namespace Creation** - Create `eso-demo`, `cred`, `remote-cluster`
3. **ESO Installation** - Install via Helm (3 deployments)
4. **Provider Setup** - Initialize infrastructure via Terraform
5. **Demo 1** - Pull secrets from external providers
6. **Demo 2** - Switch between providers dynamically
7. **Demo 3** - Push secrets to external providers
8. **Demo 4** - Generate secrets using Generators
9. **Verification** - Display created resources
10. **Cleanup** - Remove all resources (optional)

**Estimated Time:**
- With `--provider vault --skip-aws --skip-azure`: ~5-7 minutes
- Full demo with all providers: ~10-15 minutes

## 📊 Understanding the Demos

### Demo 1: Pull Secrets from External Providers ✅

Demonstrates how ESO retrieves secrets from different backends automatically.

**What happens:**
- Creates `ClusterSecretStore` resources for each provider
- Creates `ExternalSecret` resources that reference these stores
- ESO syncs secrets from external backends into Kubernetes `Secret` resources
- Displays real-time status and secret content

**Key Resources Created:**
- 2+ ClusterSecretStores
- 6+ ExternalSecrets
- 3+ Synced Kubernetes Secrets

### Demo 2: Switch Providers Dynamically ✅

Shows flexibility - change the backend provider without modifying the ExternalSecret.

**What happens:**
- Takes existing ExternalSecret (data-by-name)
- Patches `secretStoreRef` to point to different provider
- Secrets update automatically from new backend

**Result:** Same secret definition, different backend! No restart required.

### Demo 3: Push Secrets to External Providers ✅

Demonstrates `PushSecret` - push cluster secrets to external backends.

**What happens:**
- Creates a regular Kubernetes Secret (my-own-secret)
- Creates PushSecret pointing to Vault backend
- ESO automatically pushes the secret to Vault

**Result:** Cluster secrets backed up to external providers

### Demo 4: Generate Secrets ✅

Shows dynamic secret generation using Generators.

**What happens:**
- Applies Password generator - creates random password
- Applies Fake generator - creates test/fake data
- ESO creates corresponding Secret resources

**Result:** Auto-generated secrets without manual intervention

## ✅ Success: Verify Demo Results

After running the demo, verify with:

```bash
# Check ClusterSecretStores (should show 2+)
kubectl get clustersecretstore

# Check ExternalSecrets (should show 8+)
kubectl get externalsecret -n eso-demo

# Check synced secrets (should show 3+)
kubectl get secret -n eso-demo

# Decode and display a secret
kubectl get secret datafrom-find-by-tags -n eso-demo \
  -o jsonpath='{.data.secret_one}' | base64 -d

# Real-time status monitoring
./scripts/eso-utils.sh status
```

## 🐛 Troubleshooting

### Common Issues

**"Connection refused"**
```bash
# Check if ESO is running
kubectl get pods -n external-secrets

# Check operator logs
./scripts/eso-utils.sh logs
```

**"ClusterSecretStore not ready"**
```bash
# Check store configuration
kubectl describe clustersecretstore <name>

# Review ESO operator logs for specific errors
kubectl logs -n external-secrets deployment/external-secrets -f | grep -E "store|error"
```

**"ExternalSecret sync failed"**
```bash
# Check the ExternalSecret status
kubectl describe externalsecret <name> -n eso-demo

# Verify the backend provider has the secret
./scripts/eso-utils.sh test-sync
```

### Debug Commands

See **[DEBUG_GUIDE_UPDATED.md](docs/debugging/DEBUG_GUIDE_UPDATED.md)** for comprehensive troubleshooting.

```bash
# View all available commands
./scripts/eso-utils.sh help

# Get full status
./scripts/eso-utils.sh status

# Test end-to-end sync
./scripts/eso-utils.sh test-sync

# View operator logs
./scripts/eso-utils.sh logs
```

## 📚 Additional Resources

### External Docs
- [ESO Official Documentation](https://external-secrets.io)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)
- [Azure Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/)
- [HashiCorp Vault](https://www.vaultproject.io/docs)

### Related Demos
- ESO GitHub: https://github.com/external-secrets/external-secrets
- Original repo: https://github.com/sebagomez/eso-demo

## 📝 Project History

This repository evolved through multiple improvements:

- **Session 1**: Initial automation scripts created
- **Session 2**: Fixed Kubernetes context hardcoding & quoting issues
- **Session 3**: Fixed API version compatibility (v1beta1 → v1)
- **Session 4**: Moved scripts to `/scripts` folder
- **Current**: Updated README with full documentation

See **[FIXES_APPLIED.md](docs/fixes/FIXES_APPLIED.md)** for detailed fix history.

## 👨‍💻 Contributing

Found an issue? Want to improve the demo?
1. Check [DEBUG_GUIDE_UPDATED.md](docs/debugging/DEBUG_GUIDE_UPDATED.md)
2. Review [FIXES_APPLIED.md](docs/fixes/FIXES_APPLIED.md)
3. Submit PR or issue

## 📄 License

This repository is part of the ESO community and follows the same license as the main project.

---

## 🎯 Quick Links

- Start Here: [docs/START_HERE.md](docs/START_HERE.md)
- Run Demo: `./scripts/run-demo.sh`
- Get Help: `./scripts/run-demo.sh --help`
- Validate Setup: `./scripts/validate-setup.sh`
- Monitor: `./scripts/eso-utils.sh status`

---

> ✅ ***This demo is tested, documented, and production-ready***
>
> Every command shown works as documented. All edge cases have been handled.
> Comprehensive debugging guides are included for any issues.
