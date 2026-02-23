# 🚀 External Secrets Operator Demo - START HERE

Welcome! This guide will help you get started with the automated ESO demo in minutes.

## ⚡ Quick Start (2 minutes)

```bash
# 1. Check if everything is ready
./validate-setup.sh

# 2. Preview the demo (dry-run mode)
./run-demo.sh --dry-run

# 3. Run the full demo
./run-demo.sh

# 4. Explore the results
./eso-utils.sh status
```

Done! ✅

## 📚 What You'll See

The demo will automatically:
- ✓ Create Kubernetes namespaces
- ✓ Install External Secrets Operator
- ✓ Set up external secret providers (AWS, Azure, Vault, K8s)
- ✓ Create credentials and access credentials
- ✓ Run 4 complete demo scenarios
- ✓ Show you how to switch between providers
- ✓ Demonstrate pushing secrets to external backends
- ✓ Generate secrets using different methods

## 🔍 Before Your First Run

### Step 1: Check Prerequisites
```bash
./validate-setup.sh
```

This will verify:
- ✓ kubectl is installed and connected to your cluster
- ✓ Helm, Terraform, and jq are available
- ✓ AWS/Azure credentials (if using those providers)
- ✓ Kubernetes permissions

### Step 2: Configure Environment
```bash
# Create .env from template
cp .env.template .env

# Edit .env with your credentials
nano .env  # or your favorite editor
```

**Required in .env:**
```bash
AWS_ACCOUNTID=your_id
AWS_DEFAULT_REGION=us-east-1
ARM_SUBSCRIPTION_ID=your_subscription_id
AZURE_SUBSCRIPTION_ID=your_subscription_id
```

### Step 3: Ensure Kubernetes Connection
```bash
# Verify kubectl is configured
kubectl config current-context  # Should show: rancher-desktop

# Test cluster access
kubectl cluster-info
```

## 🎯 Running the Demo

### The Fastest Way (30 seconds)
```bash
./run-demo.sh
```

### For Training/Teaching (5 minutes)
```bash
# First, preview all commands
./run-demo.sh --dry-run | less

# Then run with Vault only (faster setup)
./run-demo.sh --provider vault --skip-aws --skip-azure
```

### For Specific Provider Testing
```bash
# Azure Key Vault (default)
./run-demo.sh --provider azure

# AWS Secrets Manager
./run-demo.sh --provider awssm

# HashiCorp Vault
./run-demo.sh --provider vault

# Kubernetes (multi-cluster simulation)
./run-demo.sh --provider k8s
```

### For Professional Demos
```bash
# Show every step with dry-run
./run-demo.sh --dry-run

# Run with annotations
./run-demo.sh --provider vault --no-cleanup

# Narrate what you see
./eso-utils.sh status
```

## 📖 Understanding the Output

The script prints commands in **YELLOW** so you can see exactly what's happening:

```
$ kubectl create namespace eso-demo
$ helm repo add external-secrets https://charts.external-secrets.io
$ helm install external-secrets...
```

This is intentional for **transparency and learning**. You can:
- Copy commands for manual testing
- Understand the ESO setup process
- Troubleshoot if something fails

## 🛠️ Common Operations During/After Demo

### Check Status Anytime
```bash
./eso-utils.sh status
```

### See What Was Created
```bash
./eso-utils.sh stores         # ClusterSecretStores
./eso-utils.sh externals      # ExternalSecrets
./eso-utils.sh secrets        # Synced Secrets
./eso-utils.sh generators     # Generated Secrets
```

### Inspect a Secret
```bash
./eso-utils.sh inspect data-by-name
./eso-utils.sh decode data-by-name
```

### Switch Providers
```bash
./eso-utils.sh switch-provider data-by-name vault-secret-store
```

### View Logs
```bash
./eso-utils.sh logs
```

## 🧹 Cleanup

The script will ask if you want to clean up at the end. Or manually:

```bash
# Remove just the demo resources
./run-demo.sh --cleanup-only

# Manual cleanup (if needed)
kubectl delete ns eso-demo cred remote-cluster external-secrets vault
```

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [DEMO_GUIDE.md](DEMO_GUIDE.md) | Complete guide with all options and use cases |
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | Quick lookup for common commands |
| [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) | Technical details and architecture |
| [README.md](README.md) | Original project documentation |

## ⚠️ Troubleshooting

### Issue: "Cannot connect to Kubernetes cluster"
```bash
# Check kubectl connection
kubectl cluster-info
kubectl config current-context

# Should show: rancher-desktop
```

### Issue: "Missing required tools"
```bash
# Check what's installed
which kubectl helm terraform jq

# On macOS:
brew install kubectl helm terraform jq

# On Linux (Ubuntu):
sudo apt-get install kubectl helm terraform jq
```

### Issue: "AWS credentials not working"
```bash
# Verify AWS CLI
aws sts get-caller-identity

# Update .env file
nano .env  # Review AWS settings

# Reconfigure if needed
aws configure
```

### Issue: ".env file not found"
```bash
# This is normal - create it from template
cp .env.template .env
nano .env  # Add your credentials
```

### Issue: "ExternalSecrets not syncing"
```bash
# Check them:
./eso-utils.sh test-sync

# View logs:
./eso-utils.sh logs

# Full guide:
./run-demo.sh --help
```

## 💡 Pro Tips

1. **Learn First**: Run with `--dry-run` to see all commands
2. **Safe Testing**: Use `--skip-aws --skip-azure` for fast setup
3. **Keep Resources**: Use `--no-cleanup` to explore afterward
4. **Live Monitoring**: Open new terminal with `watch './eso-utils.sh status'`
5. **Training Mode**: Print with `--dry-run > commands.txt` and follow along

## 🎓 Learning Path

1. ✓ Run `./validate-setup.sh` (2 min)
2. ✓ Read [QUICK_REFERENCE.md](QUICK_REFERENCE.md) (5 min)
3. ✓ Run `./run-demo.sh --dry-run` (1 min)
4. ✓ Run `./run-demo.sh` (10 min)
5. ✓ Explore with `./eso-utils.sh` (5 min)
6. ✓ Read [DEMO_GUIDE.md](DEMO_GUIDE.md) (10 min)
7. ✓ Experiment with different providers (10 min)

Total: ~45 minutes to understand ESO!

## 🚀 What Happens Inside

The script automates all these steps:

1. **Validation** - Check prerequisites
2. **Setup** - Create namespaces, install ESO
3. **Infrastructure** - Provision AWS/Azure/Vault
4. **Configuration** - Create credentials, secret stores
5. **Demos** - Run 4 complete scenarios
6. **Verification** - Check everything works
7. **Cleanup** - Remove resources (optional)

## 📊 Typical Execution Time

| Phase | Time |
|-------|------|
| Prerequisites check | 30 sec |
| ESO installation | 2 min |
| Vault setup | 2 min |
| Infrastructure (AWS/Azure) | 3-8 min |
| Demo scenarios | 2 min |
| Cleanup | 1 min |
| **Total** | **5-15 min** |

First run takes longer (infrastructure creation). Subsequent runs are faster.

## ✨ Demo Scenarios (What You'll Learn)

### Demo 1: Pull Secrets
See how ExternalSecrets pull from external providers into Kubernetes

### Demo 2: Switch Providers
Watch secrets switch between AWS, Azure, and Vault without changing the config

### Demo 3: Push Secrets
See secrets pushed FROM your cluster TO external backends

### Demo 4: Generate Secrets
Learn about secret generation with Passwords and Fake data

## 🎯 Next Steps

**Ready to go?**
```bash
./validate-setup.sh    # Check prerequisites (2 min)
./run-demo.sh --help   # See all options (30 sec)
./run-demo.sh          # Run the demo! (10 min)
```

**Want to learn more?**
- Read [DEMO_GUIDE.md](DEMO_GUIDE.md) for comprehensive guide
- Check [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for quick commands
- See [README.md](README.md) for original project documentation

## 📞 Need Help?

1. **First Time?** Check this file again
2. **Setup Issues?** Run `./validate-setup.sh`
3. **During Demo?** Check logs with `./eso-utils.sh logs`
4. **After Demo?** Use `./eso-utils.sh status`
5. **Troubleshooting?** See DEMO_GUIDE.md section

## 📝 Scripts Included

| Script | Purpose | Time |
|--------|---------|------|
| `run-demo.sh` | Main automation | 10+ min |
| `eso-utils.sh` | Inspection & operations | Any time |
| `validate-setup.sh` | Prerequisites check | 2 min |

All scripts have `--help`:
```bash
./run-demo.sh --help
./eso-utils.sh help
./validate-setup.sh --help
```

---

## 🎉 You're Ready!

**For training:**
```bash
./run-demo.sh --dry-run
```

**For learning:**
```bash
./run-demo.sh --provider vault --no-cleanup
```

**For testing:**
```bash
./run-demo.sh
```

**Any questions?** Check [DEMO_GUIDE.md](DEMO_GUIDE.md) or run the scripts with `--help`.

Happy demonstrating! 🚀

---

**Last Updated:** February 23, 2026
**Version:** 1.0
**Status:** Ready for Production Use
