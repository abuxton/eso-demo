#!/bin/bash

################################################################################
# External Secrets Operator (ESO) Complete Demo Script
#
# This script runs the complete ESO demo end-to-end with the following demos:
# 1. Get secrets from external providers
# 2. Switch between providers dynamically
# 3. Push secrets to external providers
# 4. Generate secrets using Generators (Password & Fake)
#
# Usage:
#   ./run-demo.sh [OPTIONS]
#
# Options:
#   --help                Show this help message
#   --dry-run             Print all commands without executing them
#   --provider PROVIDER   Specify provider (awssm|awsps|azure|vault|k8s) - default: azure
#   --cleanup-only        Run only cleanup (skip demo creation)
#   --skip-tf             Skip Terraform infrastructure creation
#   --skip-vault          Skip Vault/HashiCorp Vault setup
#   --skip-aws            Skip AWS setup
#   --skip-azure          Skip Azure setup
#   --skip-k8s            Skip Kubernetes provider setup
#   --no-cleanup          Don't run cleanup at the end
#
# Examples:
#   ./run-demo.sh                          # Run full demo with Azure (default)
#   ./run-demo.sh --dry-run                # Preview all commands
#   ./run-demo.sh --provider vault         # Run with Vault provider
#   ./run-demo.sh --dry-run --provider aws # Preview AWS commands
#
# Prerequisites:
#   - kubectl configured and connected to a cluster (rancher-desktop, minikube, etc.)
#   - AWS CLI configured (for AWS demos)
#   - Azure CLI configured (for Azure demos)
#   - Terraform installed
#   - Helm installed
#   - jq installed for JSON parsing
#   - .env file with AWS_ACCOUNTID, AWS_REGION, etc.
#
################################################################################

set -E

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Global configuration
DRY_RUN=false
PROVIDER="azure"
CLEANUP_ENABLED=true
SKIP_TF=false
SKIP_VAULT=false
SKIP_AWS=false
SKIP_AZURE=false
SKIP_K8S=false
CLEANUP_ONLY=false

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEMO_NAMESPACE="eso-demo"
CRED_NAMESPACE="cred"
REMOTE_K8S_NAMESPACE="remote-cluster"
ESO_NAMESPACE="external-secrets"

################################################################################
# Utility Functions
################################################################################

print_help() {
    cat << 'EOF'

╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║           External Secrets Operator (ESO) Complete Demo Script            ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝

USAGE:
  ./run-demo.sh [OPTIONS]

OPTIONS:
  --help              Show this help message
  --dry-run           Print all commands without executing them
  --provider PROVIDER Specify provider (awssm|awsps|azure|vault|k8s)
                      Default: azure
  --cleanup-only      Run cleanup only (skip demo recreation)
  --skip-tf           Skip Terraform infrastructure creation
  --skip-vault        Skip Vault/HashiCorp Vault setup
  --skip-aws          Skip AWS setup
  --skip-azure        Skip Azure setup
  --skip-k8s          Skip Kubernetes provider setup
  --no-cleanup        Don't run cleanup at the end

EXAMPLES:

  # Run full demo with Azure provider (default)
  ./run-demo.sh

  # Preview all commands with --dry-run
  ./run-demo.sh --dry-run

  # Run demo with Vault backend
  ./run-demo.sh --provider vault

  # Preview AWS commands with dry-run
  ./run-demo.sh --dry-run --provider awssm

  # Just cleanup resources
  ./run-demo.sh --cleanup-only

PREREQUISITES:
  ✓ kubectl configured and connected to a Kubernetes cluster
  ✓ AWS CLI configured (for AWS demos)
  ✓ Azure CLI configured (for Azure demos)
  ✓ Terraform installed
  ✓ Helm installed
  ✓ jq installed for JSON parsing
  ✓ .env file with configuration variables

DEMOS INCLUDED:
  Demo 1: ✓ Pull secrets from external providers via ExternalSecrets
  Demo 2: ✓ Switch providers dynamically
  Demo 3: ✓ Push secrets to external providers via PushSecrets
  Demo 4: ✓ Generate secrets using different Generators

MORE INFO:
  For detailed information, see README.md

EOF
    exit 0
}

print_info() {
    printf "${BLUE}ℹ${NC} %s\n" "$@"
}

print_success() {
    printf "${GREEN}✓${NC} %s\n" "$@"
}

print_warning() {
    printf "${YELLOW}⚠${NC} %s\n" "$@"
}

print_error() {
    printf "${RED}✗${NC} %s\n" "$@"
}

print_step() {
    printf "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    printf "${CYAN}STEP: %s${NC}\n" "$1"
    printf "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_demo_section() {
    printf "\n${CYAN}╔════════════════════════════════════════════════╗${NC}\n"
    printf "${CYAN}║${NC} %s\n" "$1"
    printf "${CYAN}╚════════════════════════════════════════════════╝${NC}\n"
}

# Execute command with dry-run support and verbose output
run_command() {
    local cmd="$1"
    local description="${2:-}"

    if [[ -n "$description" ]]; then
        print_info "$ $description"
    fi

    printf "${YELLOW}$ ${cmd}${NC}\n"

    if [[ "$DRY_RUN" == true ]]; then
        return 0
    fi

    # Execute the command
    eval "$cmd" || {
        print_error "Command failed: $cmd"
        return 1
    }
}

# Source environment variables from .env file
load_env() {
    if [[ ! -f "$SCRIPT_DIR/.env" ]]; then
        print_warning "No .env file found at $SCRIPT_DIR/.env"
        print_info "Creating template .env file..."
        cat > "$SCRIPT_DIR/.env.template" << 'ENVEOF'
# AWS Configuration
AWS_ACCOUNTID=your_account_id
AWS_DEFAULT_REGION=us-east-1
AWS_PROFILE=your_profile_name
AWS_SHARED_CREDENTIALS_FILE=/path/to/.aws/credentials

# Azure Configuration
ARM_SUBSCRIPTION_ID=your_subscription_id
AZURE_SUBSCRIPTION_ID=your_subscription_id
ENVEOF
        print_info "Template created at .env.template"
        return 1
    fi

    # Source the .env file
    set -a
    source "$SCRIPT_DIR/.env"
    set +a

    print_success ".env file loaded"
}

# Check prerequisites
check_prerequisites() {
    print_step "Checking Prerequisites"

    local missing_tools=()

    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    else
        print_success "kubectl found"
    fi

    # Check helm
    if ! command -v helm &> /dev/null; then
        missing_tools+=("helm")
    else
        print_success "helm found"
    fi

    # Check terraform
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    else
        print_success "terraform found"
    fi

    # Check jq
    if ! command -v jq &> /dev/null; then
        missing_tools+=("jq")
    else
        print_success "jq found"
    fi

    # Check AWS CLI (not always needed)
    if ! command -v aws &> /dev/null; then
        print_warning "aws CLI not found (optional if not using AWS)"
    else
        print_success "aws CLI found"
    fi

    # Check Azure CLI (not always needed)
    if ! command -v az &> /dev/null; then
        print_warning "az CLI not found (optional if not using Azure)"
    else
        print_success "az CLI found"
    fi

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_info "Please install the missing tools and try again."
        exit 1
    fi

    # Check kubectl connection
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        print_info "Current context: $(kubectl config current-context 2>/dev/null || echo 'none')"
        exit 1
    fi

    print_success "Connected to cluster: $(kubectl config current-context)"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                print_help
                ;;
            --dry-run)
                DRY_RUN=true
                print_info "DRY-RUN mode enabled - no commands will be executed"
                shift
                ;;
            --provider)
                PROVIDER="$2"
                shift 2
                ;;
            --cleanup-only)
                CLEANUP_ONLY=true
                shift
                ;;
            --skip-tf)
                SKIP_TF=true
                shift
                ;;
            --skip-vault)
                SKIP_VAULT=true
                shift
                ;;
            --skip-aws)
                SKIP_AWS=true
                shift
                ;;
            --skip-azure)
                SKIP_AZURE=true
                shift
                ;;
            --skip-k8s)
                SKIP_K8S=true
                shift
                ;;
            --no-cleanup)
                CLEANUP_ENABLED=false
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                echo ""
                print_help
                ;;
        esac
    done

    # Validate provider
    case "$PROVIDER" in
        awssm|awsps|azure|vault|k8s)
            ;;
        *)
            print_error "Invalid provider: $PROVIDER"
            print_info "Valid options: awssm, awsps, azure, vault, k8s"
            exit 1
            ;;
    esac
}

# Create required namespaces
create_namespaces() {
    print_step "Creating Kubernetes Namespaces"

    # Demo namespace
    run_command \
        "kubectl create namespace $DEMO_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -" \
        "Create $DEMO_NAMESPACE namespace"

    # Credentials namespace
    run_command \
        "kubectl create namespace $CRED_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -" \
        "Create $CRED_NAMESPACE namespace"

    # Remote cluster namespace (for K8s provider demo)
    run_command \
        "kubectl create namespace $REMOTE_K8S_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -" \
        "Create $REMOTE_K8S_NAMESPACE namespace for K8s provider demo"

    print_success "Namespaces created"
}

# Install External Secrets Operator via Helm
install_eso() {
    print_step "Installing External Secrets Operator"

    # Add Helm repository
    run_command \
        "helm repo add external-secrets https://charts.external-secrets.io" \
        "Add External Secrets Helm repository"

    # Update Helm repo
    run_command \
        "helm repo update" \
        "Update Helm repositories"

    # Check if ESO is already installed
    if kubectl get ns $ESO_NAMESPACE &> /dev/null; then
        print_info "ESO namespace already exists, skipping installation"
        print_info "To reinstall, run: kubectl delete ns $ESO_NAMESPACE"
    else
        # Install ESO Helm chart
        run_command \
            "helm install external-secrets external-secrets/external-secrets \
                --namespace $ESO_NAMESPACE \
                --create-namespace \
                --set installCRDs=true" \
            "Install External Secrets Operator Helm chart"
    fi

    # Wait for ESO to be ready
    print_info "Waiting for ESO deployment to be ready..."
    if [[ "$DRY_RUN" == false ]]; then
        kubectl rollout status deployment/external-secrets \
            -n $ESO_NAMESPACE --timeout=300s || {
            print_error "ESO deployment failed to be ready"
            return 1
        }
    fi

    print_success "External Secrets Operator installed and ready"
}

# Setup credentials namespace secret
setup_credentials_namespace() {
    print_step "Setting up Credentials Namespace"

    # Check if credentials secret already exists
    if kubectl get secret aws-credentials -n $CRED_NAMESPACE &> /dev/null; then
        print_warning "aws-credentials secret already exists, skipping"
    else
        if [[ "$SKIP_AWS" == false ]]; then
            print_info "AWS credentials will be created during AWS terraform apply"
        fi
    fi

    if kubectl get secret azure-credentials -n $CRED_NAMESPACE &> /dev/null; then
        print_warning "azure-credentials secret already exists, skipping"
    else
        if [[ "$SKIP_AZURE" == false ]]; then
            print_info "Azure credentials will be created during Azure terraform apply"
        fi
    fi
}

# Setup Vault
setup_vault() {
    if [[ "$SKIP_VAULT" == true ]]; then
        print_warning "Skipping Vault setup (--skip-vault)"
        return 0
    fi

    print_step "Setting Up HashiCorp Vault"

    # Check if Vault is already installed
    if kubectl get ns vault &> /dev/null; then
        print_warning "Vault namespace already exists"
        print_info "Vault is already running"
    else
        # Install Vault via Helm
        print_info "Installing HashiCorp Vault..."

        run_command \
            "helm repo add hashicorp https://helm.releases.hashicorp.com" \
            "Add HashiCorp Helm repository"

        run_command \
            "helm repo update" \
            "Update Helm repositories"

        run_command \
            "helm install vault hashicorp/vault \
                --namespace vault \
                --create-namespace \
                --set \"server.dev.enabled=true\" \
                --set \"injector.enabled=false\" \
                --set \"csi.enabled=false\"" \
            "Install HashiCorp Vault"

        # Wait for Vault to be ready
        if [[ "$DRY_RUN" == false ]]; then
            print_info "Waiting for Vault to be ready..."
            kubectl rollout status statefulset/vault -n vault --timeout=300s
        fi
    fi

    print_success "HashiCorp Vault setup complete"
}

# Setup AWS infrastructure via Terraform
setup_aws() {
    if [[ "$SKIP_AWS" == true || "$SKIP_TF" == true ]]; then
        print_warning "Skipping AWS setup (--skip-aws or --skip-tf)"
        return 0
    fi

    print_step "Setting Up AWS Infrastructure with Terraform"

    local tf_dir="$SCRIPT_DIR/terraform/aws"

    if [[ ! -d "$tf_dir" ]]; then
        print_error "AWS terraform directory not found: $tf_dir"
        return 1
    fi

    # Check AWS CLI is configured
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is required for AWS setup but not found"
        return 1
    fi

    run_command \
        "cd $tf_dir && terraform init" \
        "Initialize Terraform for AWS"

    run_command \
        "cd $tf_dir && terraform apply -auto-approve" \
        "Apply AWS Terraform configuration"

    if [[ "$DRY_RUN" == false ]]; then
        # Extract credentials from Terraform state
        print_info "Extracting AWS credentials from Terraform state..."

        local AWS_KEY=$(cat "$tf_dir/terraform.tfstate" | jq '.resources[1].instances[0].attributes.id' --raw-output 2>/dev/null || echo "")
        local AWS_SECRET=$(cat "$tf_dir/terraform.tfstate" | jq '.resources[1].instances[0].attributes.secret' --raw-output 2>/dev/null || echo "")

        if [[ -n "$AWS_KEY" && -n "$AWS_SECRET" ]]; then
            run_command \
                "kubectl create secret generic aws-credentials \
                    --namespace $CRED_NAMESPACE \
                    --from-literal=access-key=$AWS_KEY \
                    --from-literal=secret=$AWS_SECRET \
                    --dry-run=client -o yaml | kubectl apply -f -" \
                "Create AWS credentials secret"

            # Export for later use
            export AWS_KEY AWS_SECRET
        else
            print_warning "Could not extract AWS credentials from Terraform state"
        fi
    fi

    local AWS_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
    export AWS_REGION

    print_success "AWS infrastructure setup complete"
}

# Setup Azure infrastructure via Terraform
setup_azure() {
    if [[ "$SKIP_AZURE" == true || "$SKIP_TF" == true ]]; then
        print_warning "Skipping Azure setup (--skip-azure or --skip-tf)"
        return 0
    fi

    print_step "Setting Up Azure Infrastructure with Terraform"

    local tf_dir="$SCRIPT_DIR/terraform/azure"

    if [[ ! -d "$tf_dir" ]]; then
        print_error "Azure terraform directory not found: $tf_dir"
        return 1
    fi

    # Check Azure CLI is configured
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is required for Azure setup but not found"
        return 1
    fi

    run_command \
        "cd $tf_dir && terraform init" \
        "Initialize Terraform for Azure"

    run_command \
        "cd $tf_dir && terraform apply -auto-approve" \
        "Apply Azure Terraform configuration"

    if [[ "$DRY_RUN" == false ]]; then
        # Extract credentials from Terraform state
        print_info "Extracting Azure credentials from Terraform state..."

        local APP_ID=$(cat "$tf_dir/terraform.tfstate" | \
            jq '.resources | .[] | select(.type=="azuread_application") | .instances[0].attributes.application_id' --raw-output 2>/dev/null || echo "")
        local APP_PASSWORD=$(cat "$tf_dir/terraform.tfstate" | \
            jq '.resources | .[] | select(.type=="azuread_application_password") | .instances[0].attributes.value' --raw-output 2>/dev/null || echo "")
        local VAULT_URL=$(cat "$tf_dir/terraform.tfstate" | \
            jq '.resources | .[] | select(.type=="azurerm_key_vault") | .instances[0].attributes.vault_uri' --raw-output 2>/dev/null || echo "")
        local TENANT_ID=$(cat "$tf_dir/terraform.tfstate" | \
            jq '.resources | .[] | select(.type=="azurerm_client_config") | .instances[0].attributes.tenant_id' --raw-output 2>/dev/null || echo "")

        if [[ -n "$APP_ID" && -n "$APP_PASSWORD" ]]; then
            run_command \
                "kubectl create secret generic azure-credentials \
                    --namespace $CRED_NAMESPACE \
                    --from-literal=clientid=$APP_ID \
                    --from-literal=clientsecret=$APP_PASSWORD \
                    --dry-run=client -o yaml | kubectl apply -f -" \
                "Create Azure credentials secret"

            export APP_ID APP_PASSWORD VAULT_URL TENANT_ID
        else
            print_warning "Could not extract Azure credentials from Terraform state"
        fi
    fi

    print_success "Azure infrastructure setup complete"
}

# Setup Kubernetes provider infrastructure
setup_kubernetes_provider() {
    if [[ "$SKIP_K8S" == true || "$SKIP_TF" == true ]]; then
        print_warning "Skipping Kubernetes provider setup (--skip-k8s or --skip-tf)"
        return 0
    fi

    print_step "Setting Up Kubernetes Provider Infrastructure"

    local tf_dir="$SCRIPT_DIR/terraform/k8s"

    if [[ ! -d "$tf_dir" ]]; then
        print_error "K8s terraform directory not found: $tf_dir"
        return 1
    fi

    run_command \
        "cd $tf_dir && terraform init" \
        "Initialize Terraform for Kubernetes provider"

    run_command \
        "cd $tf_dir && terraform apply -auto-approve" \
        "Apply Kubernetes Terraform configuration"

    if [[ "$DRY_RUN" == false ]]; then
        # Get cluster IP
        local CLUSTER_IP=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' | sed 's|.*://||;s|:.*||')
        export CLUSTER_IP
        print_info "Cluster IP: $CLUSTER_IP"
    fi

    print_success "Kubernetes provider infrastructure setup complete"
}

# Create ClusterSecretStores
create_clustersecretstores() {
    print_step "Creating ClusterSecretStores"

    # Azure
    if [[ "$SKIP_AZURE" == false ]]; then
        print_info "Creating Azure ClusterSecretStore..."
        if [[ "$DRY_RUN" == false ]]; then
            VAULT_URL="${VAULT_URL:-}" TENANT_ID="${TENANT_ID:-}" \
            eval "echo \"$(cat $SCRIPT_DIR/ClusterSecretStores/azure-key-vault/azure_secretstore.template.yaml)\"" | \
            kubectl apply -f - 2>/dev/null || print_warning "Azure ClusterSecretStore creation skipped (credentials missing)"
        else
            print_info "$ kubectl apply -f ClusterSecretStores/azure-key-vault/azure_secretstore.template.yaml"
        fi
    fi

    # AWS Secrets Manager
    if [[ "$SKIP_AWS" == false ]]; then
        print_info "Creating AWS Secrets Manager ClusterSecretStore..."
        if [[ "$DRY_RUN" == false ]]; then
            AWS_REGION="${AWS_REGION:-us-east-1}" \
            eval "echo \"$(cat $SCRIPT_DIR/ClusterSecretStores/aws/awssm_secretstore.template.yaml)\"" | \
            kubectl apply -f - 2>/dev/null || print_warning "AWS SM ClusterSecretStore creation skipped (credentials missing)"
        else
            print_info "$ kubectl apply -f ClusterSecretStores/aws/awssm_secretstore.template.yaml"
        fi
    fi

    # AWS Parameter Store
    if [[ "$SKIP_AWS" == false ]]; then
        print_info "Creating AWS Parameter Store ClusterSecretStore..."
        if [[ "$DRY_RUN" == false ]]; then
            AWS_REGION="${AWS_REGION:-us-east-1}" \
            eval "echo \"$(cat $SCRIPT_DIR/ClusterSecretStores/aws/awsps_secretstore.template.yaml)\"" | \
            kubectl apply -f - 2>/dev/null || print_warning "AWS PS ClusterSecretStore creation skipped (credentials missing)"
        else
            print_info "$ kubectl apply -f ClusterSecretStores/aws/awsps_secretstore.template.yaml"
        fi
    fi

    # Vault
    if [[ "$SKIP_VAULT" == false ]]; then
        print_info "Creating Vault ClusterSecretStore..."
        run_command \
            "kubectl apply -f $SCRIPT_DIR/ClusterSecretStores/hashicorp-vault/vault-secretstore.yaml" \
            "Create Vault ClusterSecretStore"
    fi

    # Kubernetes
    if [[ "$SKIP_K8S" == false ]]; then
        print_info "Creating Kubernetes ClusterSecretStore..."
        if [[ "$DRY_RUN" == false ]]; then
            CLUSTER_IP="${CLUSTER_IP:-}" \
            eval "echo \"$(cat $SCRIPT_DIR/ClusterSecretStores/kubernetes/k8s-secretstore.template.yaml)\"" | \
            kubectl apply -f - 2>/dev/null || print_warning "K8s ClusterSecretStore creation skipped (cluster IP missing)"
        else
            print_info "$ kubectl apply -f ClusterSecretStores/kubernetes/k8s-secretstore.template.yaml"
        fi
    fi

    if [[ "$DRY_RUN" == false ]]; then
        print_info "Waiting for ClusterSecretStores to be valid..."
        sleep 2
        kubectl get clustersecretstore || true
    fi

    print_success "ClusterSecretStores created"
}

# Demo 1: Pull secrets from external providers
run_demo_1_pull_secrets() {
    print_demo_section "DEMO 1: Pull Secrets from External Provider ($PROVIDER)"

    print_info "This demo shows how ExternalSecrets can pull secrets from various providers"
    print_info "Provider: $PROVIDER"

    run_command \
        "cd $SCRIPT_DIR && for file in ./ExternalSecrets/*; do
    if [ -f \"\$file\" ]; then
        provider_store=\"\${PROVIDER}-secret-store\"
        eval \"echo \\\"\\$(cat \$file)\\\"; echo 'spec.secretStoreRef.name: '\$provider_store\" | \
        sed \"s|\\\$provider-secret-store|\$provider_store|g\" | kubectl apply -f - 2>/dev/null
    fi
done" \
        "Apply ExternalSecrets for $PROVIDER provider"

    if [[ "$DRY_RUN" == false ]]; then
        print_info "Waiting for ExternalSecrets to sync..."
        sleep 3

        run_command \
            "kubectl get externalsecret -n $DEMO_NAMESPACE" \
            "List ExternalSecrets"

        print_info "Check secret values:"
        run_command \
            "kubectl get secret -n $DEMO_NAMESPACE" \
            "List synchronized secrets"

        # Display a sample secret value
        print_info "Sample secret value from one of the synced secrets:"
        run_command \
            "kubectl get secret data-by-name -n $DEMO_NAMESPACE -o jsonpath='{.data.secret-value}' | base64 -d 2>/dev/null || echo 'Secret value not available'" \
            "Decode and display a secret value"
    fi

    print_success "Demo 1 complete: Secrets have been pulled from $PROVIDER"
}

# Demo 2: Switch providers dynamically
run_demo_2_switch_providers() {
    print_demo_section "DEMO 2: Switch Providers Dynamically"

    print_info "This demo shows how to switch between providers without changing the ExternalSecret definition"

    # Only run if we have more than one provider available
    local providers=()
    [[ "$SKIP_AZURE" == false ]] && providers+=("azure-secret-store")
    [[ "$SKIP_AWS" == false ]] && providers+=("awssm-secret-store" "awsps-secret-store")
    [[ "$SKIP_VAULT" == false ]] && providers+=("vault-secret-store")
    [[ "$SKIP_K8S" == false ]] && providers+=("k8s-secret-store")

    if [[ ${#providers[@]} -lt 2 ]]; then
        print_warning "Skipping Demo 2: Need at least 2 providers"
        return 0
    fi

    if [[ "$DRY_RUN" == false ]]; then
        print_info "Available ClusterSecretStores:"
        kubectl get clustersecretstore

        # Switch the data-by-name ExternalSecret to use different providers
        local first_provider="${providers[0]}"
        print_info "Switching data-by-name ExternalSecret to use $first_provider..."

        kubectl patch externalsecret data-by-name -n $DEMO_NAMESPACE \
            --type merge -p "{\"spec\":{\"secretStoreRef\":{\"name\":\"$first_provider\"}}}" 2>/dev/null || \
            print_warning "Could not patch ExternalSecret"

        sleep 2

        run_command \
            "kubectl get secret data-by-name -n $DEMO_NAMESPACE -o jsonpath='{.data.secret-value}' | base64 -d 2>/dev/null || echo 'Secret value not available'" \
            "Display secret value from first provider"

        # Switch to another provider if available
        if [[ ${#providers[@]} -gt 1 ]]; then
            local second_provider="${providers[1]}"
            print_info "Now switching to $second_provider..."

            kubectl patch externalsecret data-by-name -n $DEMO_NAMESPACE \
                --type merge -p "{\"spec\":{\"secretStoreRef\":{\"name\":\"$second_provider\"}}}" 2>/dev/null || \
                print_warning "Could not patch ExternalSecret"

            sleep 2

            run_command \
                "kubectl get secret data-by-name -n $DEMO_NAMESPACE -o jsonpath='{.data.secret-value}' | base64 -d 2>/dev/null || echo 'Secret value not available'" \
                "Display secret value from second provider"
        fi
    else
        print_info "$ kubectl get clustersecretstore"
        print_info "$ kubectl patch externalsecret data-by-name -n $DEMO_NAMESPACE --type merge -p '{\"spec\":{\"secretStoreRef\":{\"name\":\"NEW_PROVIDER\"}}'"
    fi

    print_success "Demo 2 complete: Provider switching demonstrated"
}

# Demo 3: Push secrets to external providers
run_demo_3_push_secrets() {
    if [[ "$SKIP_VAULT" == true ]]; then
        print_warning "Skipping Demo 3: Vault not available"
        return 0
    fi

    print_demo_section "DEMO 3: Push Secrets to External Providers"

    print_info "This demo shows how PushSecrets can push Secrets from the cluster to external providers"

    run_command \
        "kubectl apply -f $SCRIPT_DIR/PushSecrets/data-by-name.yaml" \
        "Apply PushSecret and Secret resources"

    if [[ "$DRY_RUN" == false ]]; then
        print_info "Waiting for PushSecret to sync..."
        sleep 3

        run_command \
            "kubectl get pushsecret -n $DEMO_NAMESPACE" \
            "List PushSecrets"

        run_command \
            "kubectl get secret my-own-secret -n $DEMO_NAMESPACE -o jsonpath='{.data.key}' | base64 -d" \
            "Display the pushed secret content"

        print_info "The secret has been pushed to Vault. To verify, check Vault UI or use:"
        print_info "  kubectl port-forward -n vault svc/vault 8200:8200"
        print_info "  Then navigate to Vault and look for 'my-pushed-secret'"
    fi

    print_success "Demo 3 complete: Secrets have been pushed to Vault"
}

# Demo 4: Generate secrets using Generators
run_demo_4_generators() {
    print_demo_section "DEMO 4: Generate Secrets Using Generators"

    print_info "This demo shows how to use Generators (Password and Fake) to create secrets"

    run_command \
        "kubectl apply -f $SCRIPT_DIR/Generators/" \
        "Apply Generator resources"

    if [[ "$DRY_RUN" == false ]]; then
        print_info "Waiting for Generators to create secrets..."
        sleep 3

        run_command \
            "kubectl get fake,password -n $DEMO_NAMESPACE" \
            "List Generators"

        run_command \
            "kubectl get secret -n $DEMO_NAMESPACE | grep -E 'fake|password'" \
            "List generated secrets"

        print_info "Display generated password:"
        run_command \
            "kubectl get secret my-password -n $DEMO_NAMESPACE -o jsonpath='{.data.password}' | base64 -d" \
            "Display generated password"

        print_info "Display fake data:"
        run_command \
            "kubectl get secret fake -n $DEMO_NAMESPACE -o jsonpath='{.data}' | jq '.' | base64 -d" \
            "Display fake generator data"
    fi

    print_success "Demo 4 complete: Secrets have been generated"
}

# Verify all demos
verify_demos() {
    print_step "Verifying Demo Results"

    if [[ "$DRY_RUN" == true ]]; then
        print_info "Skipping verification in dry-run mode"
        return 0
    fi

    print_info "Checking ExternalSecrets status:"
    kubectl get externalsecret -n $DEMO_NAMESPACE -o wide || true

    print_info "Checking synchronized secrets:"
    kubectl get secret -n $DEMO_NAMESPACE || true

    print_info "Checking ClusterSecretStores:"
    kubectl get clustersecretstore || true
}

# Cleanup resources
cleanup_demo() {
    print_step "Cleaning Up Demo Resources"

    if [[ "$DRY_RUN" == true ]]; then
        print_info "Preview cleanup commands:"
        print_info "$ kubectl delete -n $DEMO_NAMESPACE externalsecret --all"
        print_info "$ kubectl delete -n $DEMO_NAMESPACE password --all"
        print_info "$ kubectl delete -n $DEMO_NAMESPACE fake --all"
        print_info "$ kubectl delete -n $DEMO_NAMESPACE pushsecret --all"
        print_info "$ kubectl delete clustersecretstore --all"
        print_info "$ kubectl delete ns $DEMO_NAMESPACE $CRED_NAMESPACE"
        return 0
    fi

    print_info "Deleting ExternalSecrets..."
    kubectl delete -n $DEMO_NAMESPACE externalsecret --all || true

    print_info "Deleting Password generators..."
    kubectl delete -n $DEMO_NAMESPACE password --all || true

    print_info "Deleting Fake generators..."
    kubectl delete -n $DEMO_NAMESPACE fake --all || true

    print_info "Deleting PushSecrets..."
    kubectl delete -n $DEMO_NAMESPACE pushsecret --all || true

    print_info "Deleting ClusterSecretStores..."
    kubectl delete clustersecretstore --all || true

    print_info "Deleting namespaces..."
    kubectl delete ns $DEMO_NAMESPACE $CRED_NAMESPACE $REMOTE_K8S_NAMESPACE || true

    print_success "Cleanup complete"
}

# Main execution flow
main() {
    clear

    cat << 'BANNER'
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║      External Secrets Operator (ESO) Complete End-to-End Demo Script      ║
║                                                                            ║
║                         Ready to demonstrate ESO                          ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝
BANNER

    echo ""

    # Parse arguments
    parse_args "$@"

    # Load environment
    if ! load_env; then
        print_warning "Continuing without .env file..."
    fi

    # Check prerequisites
    check_prerequisites

    # Handle cleanup-only mode
    if [[ "$CLEANUP_ONLY" == true ]]; then
        cleanup_demo
        exit 0
    fi

    # Installation and setup phase
    print_info "Configuration: Provider=$PROVIDER, DRY_RUN=$DRY_RUN, Cleanup=$CLEANUP_ENABLED"
    echo ""

    create_namespaces
    install_eso
    setup_credentials_namespace
    setup_vault
    setup_aws
    setup_azure
    setup_kubernetes_provider
    create_clustersecretstores

    # Demo phase
    echo ""
    print_demo_section "RUNNING DEMOS"
    echo ""

    run_demo_1_pull_secrets
    run_demo_2_switch_providers
    run_demo_3_push_secrets
    run_demo_4_generators
    verify_demos

    # Cleanup phase
    echo ""
    if [[ "$CLEANUP_ENABLED" == true ]]; then
        read -p "$(echo -e "${YELLOW}Do you want to clean up demo resources? (y/n)${NC} ")" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cleanup_demo
        else
            print_warning "Skipping cleanup. Resources remain in your cluster."
            print_info "To clean up later, run: ./run-demo.sh --cleanup-only"
        fi
    fi

    # Final summary
    echo ""
    print_demo_section "DEMO COMPLETE"
    echo ""
    print_success "External Secrets Operator demo has completed successfully!"
    echo ""
    print_info "For more information:"
    print_info "  - README.md: Project overview and manual instructions"
    print_info "  - ./run-demo.sh --help: This script's help message"
    echo ""
}

# Trap errors and cleanup
trap 'print_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"
