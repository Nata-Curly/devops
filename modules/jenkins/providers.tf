# This module expects the root module to configure the Helm and Kubernetes providers.
# Example (in root/main.tf):
# provider "kubernetes" {
#   config_path = var.kubeconfig
# }
# provider "helm" {
#   kubernetes { config_path = var.kubeconfig }
# }

# If you prefer to configure providers per-module, uncomment and adapt below.

# provider "kubernetes" {
#   alias = "default"
# }
# provider "helm" {
#   alias = "default"
#   kubernetes { }
# }
