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

variable "db_name" {
  description = "RDS database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master DB username"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Master DB password (sensitive)"
  type        = string
  sensitive   = true
}

variable "db_engine" {
  description = "DB engine (postgres, mysql, aurora-postgresql, aurora-mysql)"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "DB engine version (optional)"
  type        = string
  default     = ""
}

variable "db_instance_class" {
  description = "Instance class for DB"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Storage for single-instance RDS (GB)"
  type        = number
  default     = 20
}

variable "db_use_aurora" {
  description = "When true, create Aurora cluster(s) instead of a single RDS instance"
  type        = bool
  default     = false
}

variable "grafana_admin_password" {
  description = "Grafana admin password for monitoring module (sensitive)"
  type        = string
  sensitive   = true
  default     = ""
}
