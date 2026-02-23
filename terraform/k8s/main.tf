terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~>3"
    }
  }
}

provider "kubernetes" {
  # Use the current kubectl context from ~/.kube/config
  # This works with any cluster (minikube, rancher-desktop, EKS, AKS, etc.)
  config_path = "~/.kube/config"
  # Removed config_context to use current context by default
}
