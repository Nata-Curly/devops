variable "jenkins_chart" {
  description = "Chart name for Jenkins"
  type        = string
  default     = "jenkins/jenkins"
}

variable "jenkins_chart_repo" {
  description = "Helm repo for Jenkins"
  type        = string
  default     = "https://charts.jenkins.io"
}

variable "jenkins_chart_version" {
  description = "Jenkins chart version"
  type        = string
  default     = "3.9.0"
}

variable "argocd_chart" {
  description = "Chart name for Argo CD"
  type        = string
  default     = "argo/argo-cd"
}

variable "argocd_chart_repo" {
  description = "Helm repo for Argo CD"
  type        = string
  default     = "https://argoproj.github.io/argo-helm"
}

variable "argocd_chart_version" {
  description = "ArgoCD chart version"
  type        = string
  default     = "5.4.0"
}
