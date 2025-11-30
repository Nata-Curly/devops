variable "use_aurora" {
  description = "When true, create an Aurora cluster. When false, create a single RDS instance."
  type        = bool
  default     = false
}

variable "engine" {
  description = "Database engine identifier. Examples: 'postgres', 'mysql', 'aurora-postgresql', 'aurora-mysql'"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Engine version to use (optional). If empty, provider default is used."
  type        = string
  default     = ""
}

variable "instance_class" {
  description = "Instance class for single RDS instance or Aurora instances"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage (GB) for single RDS instance. Ignored for Aurora clusters."
  type        = number
  default     = 20
}

variable "multi_az" {
  description = "Enable Multi-AZ for single RDS instance"
  type        = bool
  default     = false
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "username" {
  description = "Master username for the database"
  type        = string
  default     = "dbadmin"
}

variable "password" {
  description = "Master user password (sensitive)"
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group (private subnets)"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC id where the DB will be deployed"
  type        = string
}

variable "vpc_cidr_block" {
  description = "Optional VPC CIDR to restrict DB SG ingress. If empty, defaults to 10.0.0.0/8"
  type        = string
  default     = ""
}

variable "use_custom_parameter_group" {
  description = "When true, create and attach the module-created parameter group for single instance"
  type        = bool
  default     = true
}

variable "prevent_destroy" {
  description = "Prevent destroy lifecycle on the created DB instance/cluster"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying DB (be careful)"
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "When skip_final_snapshot=false, specify final snapshot id (optional)"
  type        = string
  default     = ""
}



variable "storage_type" {
  description = "Storage type for single RDS instance (gp2, gp3, io1, standard). Ignored for Aurora."
  type        = string
  default     = "gp2"
}

variable "publicly_accessible" {
  description = "Whether the DB instance/cluster should be publicly accessible (not recommended for production)"
  type        = bool
  default     = false
}

variable "parameter_group_family_postgres" {
  description = "Parameter group family for PostgreSQL engines"
  type        = string
  default     = "postgres12"
}

variable "parameter_group_family_mysql" {
  description = "Parameter group family for MySQL engines"
  type        = string
  default     = "mysql8.0"
}

variable "tags" {
  description = "Tags to apply to created resources"
  type        = map(string)
  default     = {}
}

variable "backup_retention_period" {
  description = "Backup retention period in days (applies to RDS instance and cluster)"
  type        = number
  default     = 7
}

variable "apply_immediately" {
  description = "Whether to apply modifications immediately (when changing parameter groups etc)"
  type        = bool
  default     = false
}

variable "port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "allowed_security_group_ids" {
  description = "Optional list of Security Group IDs that are allowed to access the DB (preferred over CIDR). If empty, vpc_cidr_block is used."
  type        = list(string)
  default     = []
}

variable "replica_count" {
  description = "Number of Aurora reader instances to create when use_aurora = true"
  type        = number
  default     = 0
}

variable "parameters_map" {
  description = "Optional map of parameter_name -> value to include in the parameter group"
  type        = map(string)
  default     = {}
}
