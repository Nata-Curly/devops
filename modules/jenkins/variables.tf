variable "release_name" {
  description = "Helm release name for Jenkins"
  type        = string
  default     = "jenkins"
}

variable "chart" {
  description = "Helm chart name"
  type        = string
  default     = "jenkins/jenkins"
}

variable "chart_repo" {
  description = "Helm chart repository URL"
  type        = string
  default     = "https://charts.jenkins.io"
}

variable "chart_version" {
  description = "Chart version (optional)"
  type        = string
  default     = "3.9.0"
}

variable "namespace" {
  description = "Namespace to install Jenkins into"
  type        = string
  default     = "jenkins"
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster (used to find OIDC provider for IRSA)"
  type        = string
  default     = ""
}

variable "service_account_name" {
  description = "Name of the Kubernetes ServiceAccount to create for Jenkins agents"
  type        = string
  default     = "jenkins-agent"
}

variable "service_account_namespace" {
  description = "Namespace for the Kubernetes ServiceAccount"
  type        = string
  default     = "jenkins"
}

variable "create_oidc_provider" {
  description = "If true, create an IAM OIDC provider for the EKS cluster (only if one doesn't exist)"
  type        = bool
  default     = true
}

variable "ecr_repository_url" {
  description = "ECR repository URL used for creating the kaniko secret"
  type        = string
  default     = ""
}

variable "ecr_repository_arn" {
  description = "ECR repository ARN to scope IAM permissions (optional). If empty, permissions will use '*'."
  type        = string
  default     = ""
}
