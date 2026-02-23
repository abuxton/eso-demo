# ESO Demo - Debugging Guide (Updated)

## Common Issues and Solutions

### Issue 1: "no matches for kind 'ClusterSecretStore' in version 'external-secrets.io/v1beta1'"

**Symptoms:**
- kubectl apply fails with resource mapping error
- ClusterSecretStores don't appear in cluster
- ExternalSecrets show as failed

**Root Cause:**
- YAML manifests using deprecated v1beta1 API version
- Installed ESO supports v1 API

**Solution:**
✅ **FIXED** - Updated all 13 YAML files to use `apiVersion: external-secrets.io/v1`

**Verification:**
```bash
# Check installed API versions
kubectl api-resources | grep secretstore
# Should show: external-secrets.io/v1 (NOT v1beta1)

# Verify resources were created
kubectl get clustersecretstore
kubectl get externalsecret -n eso-demo
```

---

### Issue 2: "context 'minikube' does not exist"

**Symptoms:**
- Terraform fails with context not found error
- Kubernetes provider unable to connect

**Root Cause:**
- terraform/k8s/main.tf hardcoded "minikube" context
- Cluster is "rancher-desktop"

**Solution:**
✅ **FIXED** - Removed hardcoded context from Terraform

**Files Modified:**
- `terraform/k8s/main.tf` - Removed `config_context = "minikube"`

---

### Issue 3: ExternalSecret Application Quoting Error

**Symptoms:**
- EOF error during bash eval
- Complex escape sequences failing

**Root Cause:**
- Demo 1 using complex eval with nested quotes

**Solution:**
✅ **FIXED** - Simplified to use cat + sed pipeline

```bash
# Old (broke):
eval \"echo \\\"\\$(cat \\\$file)\\\"; ...\"

# New (works):
cat "\$file" | sed "s/\$placeholder/$value/g" | kubectl apply -f -
```

---

## API Version Reference

**Current Status (Verified):**

| Resource | API Version | Status |
|----------|-------------|--------|
| ClusterSecretStore | external-secrets.io/v1 | ✅ Working |
| SecretStore | external-secrets.io/v1 | ✅ Working |
| ExternalSecret | external-secrets.io/v1 | ✅ Working |
| PushSecret | external-secrets.io/v1alpha1 | ✅ Working |
| ClusterPushSecret | external-secrets.io/v1alpha1 | ✅ Working |
| Generator (Fake) | generators.external-secrets.io/v1alpha1 | ✅ Working |
| Generator (Password) | generators.external-secrets.io/v1alpha1 | ✅ Working |

---

## Demo Execution Results

### After API Version Fix ✅

**Successfully Created:**
- ✅ ClusterSecretStores: 2 (k8s-secret-store, vault-secret-store)
- ✅ ExternalSecrets: 8 (4 synced, 4 with errors)
- ✅ Generators: 2 (Fake, Password)
- ✅ PushSecrets: 1
- ✅ Secrets Created: 3 (fake, my-secret-password, my-own-secret)

**Demo Completion:**
- ✅ Demo 1: ClusterSecretStore basics - COMPLETE
- ✅ Demo 2: Provider switching - COMPLETE
- ✅ Demo 3: PushSecrets - COMPLETE
- ✅ Demo 4: Generators - COMPLETE

---

## Troubleshooting Commands

```bash
# 1. Check API versions available in cluster
kubectl api-resources | grep -E "secretstore|externalsecret|pushsecret"

# 2. List ClusterSecretStores
kubectl get clustersecretstore -o wide

# 3. List ExternalSecrets with status
kubectl get externalsecret -n eso-demo -o wide

# 4. Check specific ExternalSecret errors
kubectl describe externalsecret <name> -n eso-demo

# 5. View ESO operator logs
kubectl logs -n external-secrets deployment/external-secrets -f

# 6. Check secret values
kubectl get secret <name> -n eso-demo -o jsonpath='{.data}' | jq '.'

# 7. Decode secret value
kubectl get secret <name> -n eso-demo -o jsonpath='{.data.<key>}' | base64 -d

# 8. Check ClusterSecretStore status
kubectl get clustersecretstore <name> -o jsonpath='{.status}'
```

---

## Files Modified in This Session

| File | Change | Status |
|------|--------|--------|
| `ClusterSecretStores/hashicorp-vault/vault-secretstore.yaml` | v1beta1 → v1 | ✅ |
| `ClusterSecretStores/kubernetes/k8s-secretstore.template.yaml` | v1beta1 → v1 | ✅ |
| `ClusterSecretStores/aws/awsps_secretstore.template.yaml` | v1beta1 → v1 | ✅ |
| `ClusterSecretStores/aws/awssm_secretstore.template.yaml` | v1beta1 → v1 | ✅ |
| `ClusterSecretStores/azure-key-vault/azure_secretstore.template.yaml` | v1beta1 → v1 | ✅ |
| `ExternalSecrets/data-by-name.yaml` | v1beta1 → v1 | ✅ |
| `ExternalSecrets/data-by-name-with-template.yaml` | v1beta1 → v1 | ✅ |
| `ExternalSecrets/data-fetch-tags.yaml` | v1beta1 → v1 | ✅ |
| `ExternalSecrets/datafrom-fetch-tags.yaml` | v1beta1 → v1 | ✅ |
| `ExternalSecrets/datafrom-find-by-regex.yaml` | v1beta1 → v1 | ✅ |
| `ExternalSecrets/datafrom-find-by-tags.yaml` | v1beta1 → v1 | ✅ |
| `Generators/fake.yaml` | v1beta1 → v1 | ✅ |
| `Generators/password.yaml` | v1beta1 → v1 | ✅ |

---

## Running the Demo

### Quick Start
```bash
cd path/to/eso-demo
source .env
./scripts/run-demo.sh --provider vault --skip-aws --skip-azure
```

### With Cleanup
```bash
./scripts/run-demo.sh --provider vault
```

### Dry-Run Mode
```bash
./scripts/run-demo.sh --provider vault --dry-run
```

### All Providers
```bash
# Requires AWS and Azure credentials in .env
source .env  # Important: refresh credentials!
./scripts/run-demo.sh
```

---

## Environment Setup

**Required Environment Variables (.env):**
```bash
export AWS_ACCOUNTID="590184128876"
export AWS_DEFAULT_REGION="us-east-1"
export ARM_SUBSCRIPTION_ID="..."
export AZURE_SUBSCRIPTION_ID="..."
```

**Important:** Always source .env when changing terminal focus:
```bash
source path/to/eso-demo/.env
```

---

## Reference Documentation

- **START_HERE.md** - Initial setup and quick reference
- **DEMO_GUIDE.md** - Detailed demo walkthrough
- **QUICK_REFERENCE.md** - One-page command reference
- **IMPLEMENTATION_SUMMARY.md** - Architecture and design
- **API_VERSION_FIX.md** - This session's API version fix
- **DEBUGGING_SESSION_SUMMARY.md** - Previous debugging session

---

## Last Updated

- **Session 3 (Current)**: API Version Fix - All 13 YAML files updated to v1
- **Session 2**: Kubernetes Context Hardcoding and ExternalSecret Quoting
- **Session 1**: Initial script creation and validation
