output "s3_bucket" {
  description = "S3 bucket for terraform state"
  value       = module.s3_backend.bucket_name
}

output "dynamodb_table" {
  description = "DynamoDB table used for state locking"
  value       = module.s3_backend.table_name
}

output "vpc_id" {
  description = "VPC id created by the vpc module"
  value       = module.vpc.vpc_id
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "rds_instance_endpoint" {
  value       = try(module.rds.instance_endpoint, null)
  description = "Single-instance RDS endpoint (null if Aurora)"
}

output "rds_cluster_endpoint" {
  value       = try(module.rds.cluster_endpoint, null)
  description = "Aurora cluster endpoint (null if single-instance)"
}
