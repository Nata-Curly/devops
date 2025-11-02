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
