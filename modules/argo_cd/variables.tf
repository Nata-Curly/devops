variable "release_name" {
  description = "Argo CD Helm release name"
  type        = string
  default     = "argo-cd"
}

variable "chart" {
  description = "Argo CD chart name"
  type        = string
  default     = "argo/argo-cd"
}

variable "chart_repo" {
  description = "Helm repo for Argo CD"
  type        = string
  default     = "https://argoproj.github.io/argo-helm"
}

variable "chart_version" {
  description = "Chart version (optional)"
  type        = string
  default     = "5.4.0"
}

variable "namespace" {
  description = "Namespace for Argo CD"
  type        = string
  default     = "argocd"
}
