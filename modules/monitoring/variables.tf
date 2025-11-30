variable "namespace" {
  description = "Namespace to install monitoring stack into"
  type        = string
  default     = "monitoring"
}

variable "chart" {
  description = "Helm chart name for the monitoring stack"
  type        = string
  default     = "kube-prometheus-stack"
}

variable "chart_repo" {
  description = "Helm chart repository URL"
  type        = string
  default     = "https://prometheus-community.github.io/helm-charts"
}

variable "chart_version" {
  description = "Helm chart version to install"
  type        = string
  default     = "45.0.0"
}

variable "grafana_admin_password" {
  description = "Grafana admin password (sensitive)"
  type        = string
  sensitive   = true
  default     = ""
}
