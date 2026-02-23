#!/bin/bash

################################################################################
# ESO Demo Environment Validation Script
#
# Validates that all prerequisites are in place before running the demo
################################################################################

set -E

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Counters
checks_passed=0
checks_failed=0
checks_warned=0

print_header() {
    printf "\n${CYAN}╔════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${CYAN}║${NC} %s\n" "$1"
    printf "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

print_check() {
    printf "%s\n" "$1"
}

check_pass() {
    ((checks_passed++))
    printf "${GREEN}✓${NC} %s\n" "$1"
}

check_fail() {
    ((checks_failed++))
    printf "${RED}✗${NC} %s\n" "$1"
}

check_warn() {
    ((checks_warned++))
    printf "${YELLOW}⚠${NC} %s\n" "$1"
}

separator() {
    printf "\n${BLUE}─────────────────────────────────────────────────────────────${NC}\n"
}

# Check tool availability
check_tool() {
    local tool="$1"
    local name="${2:-$tool}"

    if command -v "$tool" &> /dev/null; then
        local version=$("$tool" --version 2>/dev/null | head -1 || echo "installed")
        check_pass "$name: $version"
    else
        check_fail "$name: NOT FOUND"
    fi
}

# Check kubectl connection
check_kubectl_connection() {
    if kubectl cluster-info &> /dev/null; then
        local context=$(kubectl config current-context)
        local cluster=$(kubectl cluster-info | grep 'Kubernetes master' | head -1)
        check_pass "Kubernetes Cluster Connected: $context"
    else
        check_fail "Kubernetes Cluster: NOT CONNECTED"
    fi
}

# Check .env file
check_env_file() {
    if [[ -f .env ]]; then
        check_pass ".env file: EXISTS"

        # Check for key variables
        if grep -q "AWS_ACCOUNTID" .env; then
            check_warn ".env contains: AWS_ACCOUNTID (verify it's correct)"
        fi
        if grep -q "ARM_SUBSCRIPTION_ID" .env; then
            check_warn ".env contains: ARM_SUBSCRIPTION_ID (verify it's correct)"
        fi
    elif [[ -f .env.template ]]; then
        check_warn ".env file: NOT FOUND (template exists)"
        printf "         ${BLUE}→ Create from template: cp .env.template .env${NC}\n"
    else
        check_fail ".env file: NOT FOUND"
    fi
}

# Check AWS credentials
check_aws() {
    if command -v aws &> /dev/null; then
        if aws sts get-caller-identity &> /dev/null; then
            local identity=$(aws sts get-caller-identity --query Account --output text)
            check_pass "AWS Credentials: VALID (Account: $identity)"
        else
            check_warn "AWS CLI: found but credentials not configured"
        fi
    else
        check_warn "AWS CLI: NOT INSTALLED (optional)"
    fi
}

# Check Azure
check_azure() {
    if command -v az &> /dev/null; then
        if az account show &> /dev/null 2>&1; then
            local account=$(az account show --query 'name' -o tsv 2>/dev/null)
            check_pass "Azure CLI: AUTHENTICATED (Account: $account)"
        else
            check_warn "Azure CLI: installed but not authenticated"
        fi
    else
        check_warn "Azure CLI: NOT INSTALLED (optional)"
    fi
}

# Check Docker/Podman
check_container_runtime() {
    if command -v docker &> /dev/null; then
        check_pass "Docker: FOUND"
    elif command -v podman &> /dev/null; then
        check_pass "Podman: FOUND"
    else
        check_warn "Container runtime (Docker/Podman): NOT FOUND"
    fi
}

# Check disk space
check_disk_space() {
    local available=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ $available -gt 10 ]]; then
        check_pass "Disk Space: ${available}GB available (sufficient)"
    else
        check_warn "Disk Space: ${available}GB available (may need more for VM setup)"
    fi
}

# Check memory
check_memory() {
    local available=$(free -g | awk 'NR==2 {print $7}')
    if [[ "$OSTYPE" == "darwin"* ]]; then
        available=$(vm_stat | grep "Pages free" | awk '{print int($3 * 4096 / 1024 / 1024 / 1024)}')
    fi

    if [[ $available -gt 4 ]]; then
        check_pass "Memory: ${available}GB free (sufficient)"
    else
        check_warn "Memory: ${available}GB free (may be tight)"
    fi
}

# Check script readiness
check_scripts() {
    if [[ -x run-demo.sh ]]; then
        check_pass "run-demo.sh: EXECUTABLE"
    else
        check_fail "run-demo.sh: NOT EXECUTABLE (run: chmod +x run-demo.sh)"
    fi

    if [[ -x eso-utils.sh ]]; then
        check_pass "eso-utils.sh: EXECUTABLE"
    else
        check_fail "eso-utils.sh: NOT EXECUTABLE (run: chmod +x eso-utils.sh)"
    fi
}

# Check Kubernetes capabilities
check_k8s_capabilities() {
    # Check if CRDs can be created
    if kubectl api-resources &> /dev/null; then
        check_pass "Kubernetes API: ACCESSIBLE"
    else
        check_fail "Kubernetes API: NOT ACCESSIBLE"
    fi

    # Check if namespaces can be created
    if kubectl auth can-i create namespaces &> /dev/null 2>&1; then
        check_pass "Kubernetes Permissions: CAN CREATE NAMESPACES"
    else
        check_warn "Kubernetes Permissions: May lack namespace creation rights"
    fi
}

print_summary() {
    separator
    printf "${CYAN}Summary:${NC}\n"
    printf "  ${GREEN}Passed:${NC}  $checks_passed\n"
    printf "  ${YELLOW}Warnings:${NC} $checks_warned\n"
    printf "  ${RED}Failed:${NC}  $checks_failed\n"

    if [[ $checks_failed -eq 0 ]]; then
        printf "\n${GREEN}✓ Ready to run demo!${NC}\n"
        printf "  Next: ./scripts/run-demo.sh --help\n"
        return 0
    elif [[ $checks_warned -eq 0 ]]; then
        printf "\n${YELLOW}⚠ Warning: Some non-critical checks failed${NC}\n"
        printf "  Most features should work, but verify issues first\n"
        return 0
    else
        printf "\n${RED}✗ NOT READY - Fix failures above before running demo${NC}\n"
        printf "  See DEMO_GUIDE.md for troubleshooting\n"
        return 1
    fi
}

main() {
    clear

    cat << 'BANNER'
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║              ESO Demo Environment Validation Checker                       ║
║                                                                            ║
║                 Checking prerequisites for demo readiness                 ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝
BANNER

    print_header "REQUIRED TOOLS"
    print_check "Core Tools:"
    check_tool "kubectl" "kubectl (Kubernetes)"
    check_tool "helm" "helm (Package Manager)"
    check_tool "terraform" "terraform (Infrastructure)"
    check_tool "jq" "jq (JSON Parser)"
    check_tool "git" "git (Version Control)"

    separator
    print_header "OPTIONAL TOOLS"
    print_check "Cloud Providers (for specific demos):"
    check_tool "aws" "AWS CLI"
    check_tool "az" "Azure CLI"

    separator
    print_header "KUBERNETES SETUP"
    check_kubectl_connection
    check_k8s_capabilities

    separator
    print_header "CLOUD CREDENTIALS"
    check_aws
    check_azure

    separator
    print_header "SYSTEM RESOURCES"
    check_container_runtime
    check_disk_space
    check_memory

    separator
    print_header "DEMO SETUP"
    check_env_file
    check_scripts

    separator
    print_summary
}

main "$@"
