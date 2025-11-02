# lesson-5 — Terraform infra for AWS

This directory contains Terraform modules and configuration for:

- S3 backend with DynamoDB locking (module `s3-backend`)
- VPC with public and private subnets (module `vpc`)
- ECR repository (module `ecr`)

Quick start:

1. Create (or choose) an S3 bucket for Terraform state and a DynamoDB table name for locks.
   - You can bootstrap the bucket/table via AWS Console or run the `s3-backend` module separately.
2. Edit `backend.tf` and replace `REPLACE_WITH_YOUR_BUCKET_NAME` with your bucket name.
3. From `lesson-5` run:

```bash
terraform init
terraform plan
terraform apply
terraform destroy
```

Notes:

- The backend can't create its own bucket in the same `terraform init` run — you must create the bucket first or init with a different (local) backend, then migrate the state.
- Region is set to `eu-central-1` by default; adjust provider settings in `main.tf` if needed.

Module summaries

- `modules/s3-backend`

  - What it creates:
    - S3 bucket for Terraform state
    - S3 bucket versioning enabled
    - Server-side encryption (SSE-S3 / AES256)
    - Public access block settings
    - DynamoDB table for state locking
  - Inputs (important variables):
    - `bucket_name` — name of the S3 bucket to create
    - `table_name` — name of the DynamoDB table to create
  - Outputs:
    - `bucket_name` — S3 bucket name
    - `bucket_arn` — S3 bucket ARN
    - `table_name` — DynamoDB table name
  - Notes: The backend bucket must be globally unique; when using this module to create the bucket you must either use a local backend first and migrate state, or create the bucket manually before enabling the S3 backend.

- `modules/vpc`

  - What it creates:
    - VPC with the provided CIDR block
    - 3 public subnets and 3 private subnets (CIDRs provided by caller)
    - Internet Gateway attached to the VPC
    - Elastic IP and a single NAT Gateway (placed in the first public subnet)
    - Public and private route tables with associations
  - Inputs (important variables):
    - `vpc_cidr_block` — VPC CIDR
    - `public_subnets` — list of 3 public subnet CIDRs
    - `private_subnets` — list of 3 private subnet CIDRs
    - `availability_zones` — list of AZs to place subnets into
    - `vpc_name` — name for tagging
  - Outputs:
    - `vpc_id` — created VPC id
    - `public_subnets` — list of public subnet ids
    - `private_subnets` — list of private subnet ids
    - `public_route_table_id` — id of public route table
  - Notes: NAT Gateway and Elastic IP are billable — destroy resources after testing to avoid charges.

- `modules/ecr`
  - What it creates:
    - ECR repository
    - Optional image scan-on-push configuration
    - Repository policy granting access to the account
  - Inputs (important variables):
    - `ecr_name` — repository name
    - `scan_on_push` — boolean to enable image scanning on push
  - Outputs:
    - `repository_url` — URL for pushing images
    - `repository_arn` — repository ARN
  - Notes: The module creates a simple repository policy scoped to the account root; tighten policy for production use.
