variable "bucket_name" {
  description = "Name of the S3 bucket to create"
  type        = string
}

variable "table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}
