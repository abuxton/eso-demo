#!/bin/bash

################################################################################
# ESO Utility Functions
#
# Common utility functions for managing External Secrets Operator demonstrations
################################################################################

set -E

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Configuration
DEMO_NS="eso-demo"
CRED_NS="cred"

print_info() { printf "${BLUE}ℹ${NC} %s\n" "$@"; }
print_success() { printf "${GREEN}✓${NC} %s\n" "$@"; }
print_warning() { printf "${YELLOW}⚠${NC} %s\n" "$@"; }
print_error() { printf "${RED}✗${NC} %s\n" "$@"; }

usage() {
    cat << 'EOF'
ESO Utility Functions

USAGE:
  eso-utils.sh COMMAND [OPTIONS]

COMMANDS:

  status              Show ESO and demo status

  secrets [--all]      Show synchronized secrets
                       --all: Show all namespaces

  stores              List ClusterSecretStores and their status

  externals           List ExternalSecrets and their status

  generators          List Generators and their status

  push-secrets        List PushSecrets and their status

  inspect SECRET      Inspect a secret (shows metadata and data)
                       Example: eso-utils.sh inspect data-by-name

  decode SECRET_NAME  Decode all base64 fields in a secret
                       Example: eso-utils.sh decode data-by-name

  switch-provider SECRET PROVIDER
                      Switch an ExternalSecret to a different provider
                       Example: eso-utils.sh switch-provider data-by-name vault-secret-store

  test-sync           Test if ExternalSecrets are syncing

  view-vault           Open port-forward to Vault (requires vault running)

  port-forward        Setup all required port-forwards

  logs [RESOURCE]     Show ESO operator logs
                       Example: eso-utils.sh logs externalsecret

  help                Show this help message

EOF
}

# Show overall status
cmd_status() {
    echo "╔════════════════════════════════════════════╗"
    echo "║          ESO Demo Status Report            ║"
    echo "╚════════════════════════════════════════════╝"
    echo ""

    print_info "Cluster Context"
    kubectl config current-context
    echo ""

    print_info "ESO Operator Status"
    kubectl get deployment -n external-secrets 2>/dev/null || echo "  ESO not installed"
    echo ""

    print_info "Demo Namespaces"
    kubectl get ns | grep -E "$DEMO_NS|$CRED_NS" || echo "  Demo namespaces not created"
    echo ""

    print_info "ClusterSecretStores"
    kubectl get clustersecretstore 2>/dev/null || echo "  No stores created"
    echo ""

    print_info "ExternalSecrets Count"
    local count=$(kubectl get externalsecret -n $DEMO_NS --no-headers 2>/dev/null | wc -l)
    echo "  $count ExternalSecrets in $DEMO_NS namespace"
    echo ""

    print_info "Synced Secrets"
    kubectl get secret -n $DEMO_NS --no-headers 2>/dev/null | wc -l | xargs echo "  Secrets in $DEMO_NS:"
}

# Show secrets
cmd_secrets() {
    local all=false
    [[ "$1" == "--all" ]] && all=true

    if [[ "$all" == true ]]; then
        print_info "Secrets in all namespaces:"
        kubectl get secret --all-namespaces | grep -v "^kube-"
    else
        print_info "Secrets in $DEMO_NS namespace:"
        kubectl get secret -n $DEMO_NS
    fi
}

# List ClusterSecretStores
cmd_stores() {
    print_info "ClusterSecretStores:"
    kubectl get clustersecretstore -o wide
}

# List ExternalSecrets
cmd_externals() {
    print_info "ExternalSecrets in $DEMO_NS:"
    kubectl get externalsecret -n $DEMO_NS -o wide
}

# List Generators
cmd_generators() {
    print_info "Generators in $DEMO_NS:"
    kubectl get fake,password -n $DEMO_NS 2>/dev/null || echo "No generators created"
}

# List PushSecrets
cmd_push_secrets() {
    print_info "PushSecrets in $DEMO_NS:"
    kubectl get pushsecret -n $DEMO_NS 2>/dev/null || echo "No push secrets created"
}

# Inspect a secret
cmd_inspect() {
    local secret="$1"
    [[ -z "$secret" ]] && { print_error "Secret name required"; return 1; }

    print_info "Inspecting secret: $secret"
    echo ""
    print_info "Metadata:"
    kubectl get secret "$secret" -n $DEMO_NS -o yaml | head -20
    echo ""
    print_info "Data keys:"
    kubectl get secret "$secret" -n $DEMO_NS -o jsonpath='{.data}' | jq 'keys[]'
}

# Decode secret values
cmd_decode() {
    local secret="$1"
    [[ -z "$secret" ]] && { print_error "Secret name required"; return 1; }

    print_info "Decoding secret: $secret"
    echo ""

    local keys=$(kubectl get secret "$secret" -n $DEMO_NS -o jsonpath='{.data}' | jq -r 'keys[]')

    for key in $keys; do
        echo "Key: $key"
        kubectl get secret "$secret" -n $DEMO_NS -o jsonpath="{.data.$key}" | base64 -d 2>/dev/null || echo "  [Could not decode]"
        echo ""
    done
}

# Switch provider
cmd_switch_provider() {
    local secret="$1"
    local provider="$2"

    if [[ -z "$secret" || -z "$provider" ]]; then
        print_error "Usage: eso-utils.sh switch-provider SECRET_NAME PROVIDER"
        return 1
    fi

    print_info "Switching $secret to use provider: $provider"

    kubectl patch externalsecret "$secret" -n $DEMO_NS \
        --type merge -p "{\"spec\":{\"secretStoreRef\":{\"name\":\"$provider\"}}}" && \
        print_success "Switched to $provider" || \
        print_error "Failed to switch provider"

    sleep 2

    print_info "New secret value:"
    kubectl get secret "$secret" -n $DEMO_NS -o jsonpath='{.data.secret-value}' | base64 -d 2>/dev/null || echo "[Not available]"
    echo ""
}

# Test sync
cmd_test_sync() {
    print_info "Testing ExternalSecret synchronization..."
    echo ""

    kubectl get externalsecret -n $DEMO_NS -o json | jq -r '.items[] | "\(.metadata.name): \(.status.conditions[0].reason)"' 2>/dev/null || \
        print_warning "No ExternalSecrets found"

    echo ""
    print_info "Secret counts:"
    echo "  External Secrets: $(kubectl get externalsecret -n $DEMO_NS --no-headers 2>/dev/null | wc -l)"
    echo "  Synced Secrets: $(kubectl get secret -n $DEMO_NS --no-headers 2>/dev/null | wc -l)"
}

# Port forward to Vault
cmd_vault() {
    print_info "Setting up Vault port-forward..."
    print_info "Vault will be available at: http://localhost:8200"
    print_info "To stop, press Ctrl+C"
    echo ""

    kubectl port-forward -n vault svc/vault 8200:8200 --address='0.0.0.0'
}

# Setup port-forwards
cmd_port_forward() {
    print_info "Setting up useful port-forwards..."

    # Check what's running
    if kubectl get ns vault &>/dev/null; then
        print_info "Starting Vault port-forward (port 8200)..."
        kubectl port-forward -n vault svc/vault 8200:8200 &
    fi

    print_info "Port-forwards established. Press Ctrl+C to stop."
    wait
}

# Show logs
cmd_logs() {
    local resource="${1:-all}"

    print_info "ESO Operator Logs"

    case "$resource" in
        all)
            kubectl logs -n external-secrets deployment/external-secrets -f --tail=50
            ;;
        externalsecret|pushsecret)
            print_info "Resource type: $resource"
            print_info "Recent resource creations:"
            kubectl get "$resource" -A --sort-by=.metadata.creationTimestamp | tail -10
            echo ""
            print_info "ESO logs (may contain entries for this resource):"
            kubectl logs -n external-secrets deployment/external-secrets --tail=100
            ;;
        *)
            kubectl logs -n external-secrets deployment/external-secrets --tail=50 | grep "$resource" || \
                print_warning "No log entries found for: $resource"
            ;;
    esac
}

# Main
main() {
    local cmd="${1:-help}"

    case "$cmd" in
        status) cmd_status ;;
        secrets) cmd_secrets "$2" ;;
        stores) cmd_stores ;;
        externals) cmd_externals ;;
        generators) cmd_generators ;;
        push-secrets|pushsecrets) cmd_push_secrets ;;
        inspect) cmd_inspect "$2" ;;
        decode) cmd_decode "$2" ;;
        switch-provider) cmd_switch_provider "$2" "$3" ;;
        test-sync) cmd_test_sync ;;
        view-vault|vault) cmd_vault ;;
        port-forward) cmd_port_forward ;;
        logs) cmd_logs "$2" ;;
        help|--help|-h)
            usage
            ;;
        *)
            print_error "Unknown command: $cmd"
            echo ""
            usage
            exit 1
            ;;
    esac
}

main "$@"
