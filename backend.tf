/*
  Remote S3 backend for Terraform state. This will store the state file in S3
  and use DynamoDB for state locking. Make sure the bucket exists before
  running `terraform init -migrate-state` (it should have been created by the
  local apply), or create it manually.
*/

terraform {
  backend "s3" {
    bucket         = "go-it-hw-devops-lesson7-20251108"
    key            = "final-project/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
