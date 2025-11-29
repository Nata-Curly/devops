# RDS Module

This module provisions database resources on AWS. It supports two modes controlled by `use_aurora`:

- `use_aurora = false` → creates a single `aws_db_instance` (PostgreSQL or MySQL)
- `use_aurora = true` → creates an `aws_rds_cluster` (Aurora) and one writer `aws_rds_cluster_instance`

Location: `modules/rds`

## What the module creates

- `aws_db_subnet_group` for the provided private `subnet_ids`
- `aws_security_group` for DB access (ingress controlled by `vpc_cidr_block` or provided SGs)
- `aws_db_parameter_group` (single-instance) or `aws_rds_cluster_parameter_group` (Aurora)
- `aws_db_instance` (single instance) or `aws_rds_cluster` + `aws_rds_cluster_instance` (Aurora writer)

## Quick usage examples

1. Single RDS instance (Postgres)

```hcl
module "rds" {
  source           = "../modules/rds"
  use_aurora       = false
  subnet_ids       = ["subnet-01234567","subnet-89abcdef"]
  vpc_id           = "vpc-0123456789abcdef0"
  db_name          = "myappdb"
  username         = "dbadmin"
  password         = var.db_password
  engine           = "postgres"
  engine_version   = "13.7"
  instance_class   = "db.t3.medium"
  allocated_storage = 20
  tags = { Environment = "prod" }
}
```

2. Aurora cluster (Postgres-compatible)

```hcl
module "rds_aurora" {
  source         = "../modules/rds"
  use_aurora     = true
  subnet_ids     = ["subnet-01234567","subnet-89abcdef"]
  vpc_id         = "vpc-0123456789abcdef0"
  db_name        = "myappdb"
  username       = "clusteradmin"
  password       = var.db_password
  engine         = "aurora-postgresql"
  engine_version = "11.13"
  instance_class = "db.r5.large"
  tags = { Environment = "prod" }
}
```

## Variables (reference)

All module variables live in `variables.tf`. Key variables (name — type — default — description):

- `use_aurora` — bool — `false` — create Aurora when true, otherwise single instance
- `engine` — string — `postgres` — engine identifier (`postgres`, `mysql`, `aurora-postgresql`, `aurora-mysql`)
- `engine_version` — string — `""` — engine version (optional)
- `instance_class` — string — `db.t3.micro` — instance class for instances
- `allocated_storage` — number — `20` — storage (GB) for single instances (ignored for Aurora)
- `storage_type` — string — `gp2` — storage type for single instance
- `multi_az` — bool — `false` — enable Multi-AZ for single instance
- `db_name` — string — `appdb` — initial DB name
- `username` — string — `dbadmin` — master username
- `password` — string (sensitive) — no default — master password
- `subnet_ids` — list(string) — required — private subnet IDs for DB subnet group
- `vpc_id` — string — required — VPC id
- `vpc_cidr_block` — string — `""` — optional CIDR to allow ingress (defaults used when empty)
- `publicly_accessible` — bool — `false` — whether instances are publicly accessible
- `use_custom_parameter_group` — bool — `true` — create and attach module parameter group for single instance
- `parameter_group_family_postgres` — string — `postgres12` — PG family for single-instance Postgres
- `parameter_group_family_mysql` — string — `mysql8.0` — family for single-instance MySQL
- `backup_retention_period` — number — `7` — backup retention days
- `skip_final_snapshot` — bool — `false` — skip final snapshot on destroy
- `final_snapshot_identifier` — string — `""` — optional final snapshot id
- `prevent_destroy` — bool — `true` — lifecycle prevent_destroy to avoid accidental deletion
- `apply_immediately` — bool — `false` — apply parameter changes immediately
- `tags` — map(string) — `{}` — tags to apply
- `port` — number — `5432` — DB port

See `variables.tf` for full descriptions and defaults.

## Outputs

- `instance_endpoint` — endpoint of single instance (null if Aurora)
- `instance_port` — port for single instance
- `cluster_endpoint` — cluster endpoint (Aurora) (null if single instance)
- `cluster_reader_endpoint` — Aurora reader endpoint
- `cluster_port` — port for Aurora cluster
- `security_group_id` — ID of the Security Group created by module

## Testing / quick plan

1. Provide sensitive values via environment or `terraform.tfvars` (do not commit credentials):

```bash
export TF_VAR_vpc_id="vpc-..."
export TF_VAR_subnet_ids='["subnet-...","subnet-..."]'
export TF_VAR_password="SuperSecret"
```

2. Initialize and plan:

```bash
terraform init
terraform plan -out=plan.tfplan
terraform apply plan.tfplan
```

3. Inspect outputs:

```bash
terraform output instance_endpoint
terraform output cluster_endpoint
```

## Recommendations & notes

- `prevent_destroy = true` by default to protect production databases — set to `false` if running `terraform destroy` during tests.
- The module creates a minimal parameter group; for production workloads, extend and tune parameters for your engine and version.
- Security: by default the module uses `vpc_cidr_block` (or a safe default). For production prefer allowing traffic only from application security groups — consider extending the module to accept `allowed_security_group_ids`.
- Aurora: module currently creates a single writer instance. If you need readers, add a `replica_count` variable and create additional `aws_rds_cluster_instance` resources.
- Costs: RDS/Aurora instances incur charges. Use small instance classes in a test account and always run `terraform destroy` after testing.

If you want, I can:

- add `allowed_security_group_ids` and use it in the SG ingress (more secure),
- add `replica_count` for Aurora readers,
- expand parameter group customization to accept a `map(string)` of parameters.

---
