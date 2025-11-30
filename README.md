# Final Project — AWS DevOps Infrastructure (EKS + CI/CD + RDS/Aurora + ECR + Monitoring)

This repository implements the final project: a complete DevOps infrastructure on AWS using Terraform and Helm.

Goal: provision a production-like environment that demonstrates Kubernetes (EKS), CI/CD (Jenkins + Argo CD), a managed database (RDS or Aurora), a container registry (ECR), and observability (Prometheus + Grafana). Use `RUNBOOK.md` for exact deploy and verification steps.

Core components included in this repo:

- VPC and networking (private/public subnets)
- ECR (container registry)
- EKS (Kubernetes cluster)
- Jenkins (CI system, installed via Helm + Terraform, with IRSA for Kaniko)
- Argo CD (GitOps for application delivery)
- RDS / Aurora (database module with toggle via `db_use_aurora`)
- Monitoring: Prometheus + Grafana (installed via `kube-prometheus-stack` Helm chart)

Prerequisites

- Local machine: `terraform` (>=1.0), `kubectl`, `aws` CLI configured with credentials that can create IAM/EKS resources.
- An AWS account with rights to create S3, DynamoDB, EKS, IAM, ECR, EC2.

Important: cleanup resources when finished to avoid charges.

Overview of components

- Terraform modules:
  - `modules/s3-backend` — S3 + DynamoDB for remote state
  - `modules/vpc` — network resources
  - `modules/ecr` — ECR repository
  - `modules/eks` — EKS cluster + node group
  - `modules/jenkins` — Helm release for Jenkins + IRSA + Kaniko secret
  - `modules/argo_cd` — Helm release for Argo CD + small chart to create Argo Applications
- Helm charts:
  - `charts/django-app` — Django application chart

Quick flow

1. Terraform provisions infra (VPC, ECR, EKS, Jenkins, ArgoCD).
2. Jenkins pipeline builds image with Kaniko and pushes to ECR, then updates target Helm repo `values.yaml` and pushes commit.
3. Argo CD monitors the Helm chart repo and automatically syncs the chart to the cluster.

DB module overview

This repository now includes a reusable Terraform DB module at `modules/rds` that supports two modes:

- Single-instance RDS (set `use_aurora = false`) — provisions an `aws_db_instance` with an optional parameter group and DB subnet group.
- Amazon Aurora cluster (set `use_aurora = true`) — provisions an `aws_rds_cluster` and an `aws_rds_cluster_instance` (writer) attached to the cluster.

Key module inputs (required):

- `subnet_ids` (list(string)) — private subnet IDs for the DB Subnet Group
- `vpc_id` (string) — VPC ID where the DB will be created
- `db_name` (string) — database name
- `username` (string) — master user name
- `password` (string, sensitive) — master user password
- `use_aurora` (bool) — `true` for Aurora, `false` for single-instance

Selected outputs:

- `instance_endpoint` / `instance_port` — endpoint + port for single-instance DB (null when Aurora is used)
- `cluster_endpoint` / `cluster_reader_endpoint` / `cluster_port` — endpoints + port for Aurora (null when single-instance is used)
- `security_group_id` — security group created for the DB resources

## Runbook & verification

See `RUNBOOK.md` for a step-by-step runbook: how to initialize, deploy (terraform apply), port-forward Jenkins/ArgoCD/Grafana, verify CI/CD and monitoring, and cleanup instructions.

Usage examples

1. Single RDS instance (Postgres example)

```hcl
module "rds" {
  source           = "./modules/rds"
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
  tags = {
    Environment = "prod"
    Project     = "django-app"
  }
}

output "rds_instance_endpoint" {
  value = module.rds.instance_endpoint
}
```

2. Aurora cluster (Postgres-compatible Aurora)

```hcl
module "rds_aurora" {
  source         = "./modules/rds"
  use_aurora     = true
  subnet_ids     = ["subnet-01234567","subnet-89abcdef"]
  vpc_id         = "vpc-0123456789abcdef0"
  db_name        = "myappdb"
  username       = "clusteradmin"
  password       = var.db_password
  engine         = "aurora-postgresql"
  engine_version = "11.13"
  instance_class = "db.r5.large"
  tags = {
    Environment = "prod"
    Project     = "django-app"
  }
}

output "aurora_cluster_endpoint" {
  value = module.rds_aurora.cluster_endpoint
}
```

Notes and recommendations

- `prevent_destroy` is enabled by default in the module to avoid accidental deletion; set it to `false` if you plan to run `terraform destroy` during testing.
- The security group created by the module opens ingress to the `vpc_cidr_block` variable if provided, otherwise a default private CIDR is used — for production restrict ingress to specific app subnet CIDRs or to application security groups.
- Parameter groups created by the module contain a small set of example parameters; extend them as needed for your engine and workload.
- Creating RDS or Aurora resources incurs charges. Test carefully in a non-production account or with minimal instance classes/sizes.

RDS module variables (reference)

Below are the variables exposed by `modules/rds`. Use these in your `module` block or via `terraform.tfvars`.

- `use_aurora` (bool, default: `false`): create Aurora when `true`, otherwise create a single `aws_db_instance`.
- `engine` (string, default: `postgres`): engine identifier (`postgres`, `mysql`, `aurora-postgresql`, `aurora-mysql`).
- `engine_version` (string, default: `""`): engine version (optional).
- `instance_class` (string, default: `db.t3.micro`): instance class for DB instances.
- `allocated_storage` (number, default: `20`): storage (GB) for single RDS instance (ignored for Aurora).
- `storage_type` (string, default: `gp2`): storage type for single RDS instance (`gp2`, `gp3`, etc.).
- `multi_az` (bool, default: `false`): enable Multi-AZ for single RDS instance.
- `db_name` (string, default: `appdb`): initial DB name to create.
- `username` (string, default: `dbadmin`): master DB username.
- `password` (string, sensitive): master DB password (no default — set via tfvars or secure variable input).
- `subnet_ids` (list(string), required): list of private subnet IDs for the DB Subnet Group.
- `vpc_id` (string, required): VPC id where the DB resources will be created.
- `vpc_cidr_block` (string, default: `""`): optional CIDR to restrict DB SG ingress; when empty a default private CIDR is used.
- `publicly_accessible` (bool, default: `false`): whether DB instances should be publicly accessible (avoid in production).
- `use_custom_parameter_group` (bool, default: `true`): create and attach the module-created parameter group for single instances.
- `parameter_group_family_postgres` (string, default: `postgres12`): parameter group family for PostgreSQL single-instance.
- `parameter_group_family_mysql` (string, default: `mysql8.0`): parameter group family for MySQL single-instance.
- `backup_retention_period` (number, default: `7`): backup retention days for instance/cluster.
- `skip_final_snapshot` (bool, default: `false`): when destroying, skip final snapshot if `true`.
- `final_snapshot_identifier` (string, default: `""`): optional snapshot id to use when not skipping final snapshot.
- `prevent_destroy` (bool, default: `true`): lifecycle prevent_destroy to avoid accidental deletions.
- `apply_immediately` (bool, default: `false`): whether to apply parameter changes immediately.
- `tags` (map(string), default: `{}`): tags applied to created resources.
- `port` (number, default: `5432`): DB port.

How to change engine / instance class / behavior

- To switch between Postgres and MySQL, set `engine = "postgres"` or `engine = "mysql"` and (optionally) `engine_version`.
- To enable Aurora use `use_aurora = true` and set `engine` to `aurora-postgresql` or `aurora-mysql`.
- To change instance sizing, set `instance_class` to the desired `db.*` family (for Aurora writer instances this controls the writer instance type).

1. Bootstrap backend & init

---

Before running Terraform ensure your AWS credentials are configured for the account where you will provision resources (for example via `aws configure` or `AWS_PROFILE`, and `AWS_REGION`). These commands are intended to be run in `bash.exe` (WSL or Git Bash) on Windows.

1. Confirm or create the S3 bucket and DynamoDB table used for remote state. See `backend.tf` for backend configuration — if you need to override values, use `-backend-config` flags.

2. Initialize Terraform (this configures the backend and downloads providers):

```bash
# from repo root
export AWS_REGION=us-east-1
terraform init -upgrade
```

3. Create an execution plan and review it:

```bash
terraform plan -out plan.tfplan
```

4. Apply the plan (recommended: review the plan file before applying):

```bash
terraform apply plan.tfplan
```

Quick checklist (before apply):

- Ensure `backend.tf` points to the correct S3 bucket and DynamoDB table (or provide `-backend-config` values).
- Confirm `AWS_REGION` and credentials are set in your shell.
- Confirm any variable overrides you need (via `terraform.tfvars` or `-var` flags).
- If your EKS cluster already exists and you only want to create Jenkins/ArgoCD, be cautious which modules/variables you enable.

Notes:

- Running `terraform apply` will create resources that may incur AWS charges (EKS, EC2, RDS, etc.).
- If your environment already has an OIDC provider for the cluster, call the Jenkins module with `create_oidc_provider = false` to avoid duplicate providers.

2. Apply infrastructure (create VPC, ECR, EKS, Jenkins, Argo CD)

---

Edit `main.tf` variables if you need custom values (node sizes, counts, etc.) then run:

```bash
terraform plan -out plan.tfplan
terraform apply plan.tfplan
```

Notes:

- The root Terraform module configures the `kubernetes` and `helm` providers using outputs from the `eks` module. Terraform will create the EKS cluster, then configure the providers so Kubernetes/Helm resources are created into the cluster.
- If your cluster already has an OIDC provider you should call the Jenkins module with `create_oidc_provider = false` to avoid duplicate provider creation.

3. Verify Jenkins and Argo CD installations

---

After `terraform apply` completes, check the Helm releases and pods:

```bash
kubectl get ns
kubectl get pods -n jenkins
kubectl get pods -n argocd
kubectl get svc -n argocd
```

To retrieve Argo CD server info and initial admin password (if not customized), use the Argo CD outputs or check the Argo CD secret in `argocd` namespace.

4. IRSA, ServiceAccount and Kaniko secret (what Terraform created)

---

- Terraform creates an IAM role trusting the EKS OIDC provider and a Kubernetes `ServiceAccount` annotated with that role ARN. This allows pods using that SA to assume the role and push to ECR without long-lived AWS keys.
- Terraform also creates a Kubernetes secret `kaniko-secret` in the Jenkins namespace that contains `.dockerconfigjson` derived from ECR auth token, which Kaniko can use as fallback/extra auth.

Validate the resources:

```bash
kubectl get sa -n jenkins
kubectl describe sa jenkins-agent -n jenkins
kubectl get secret kaniko-secret -n jenkins -o yaml
aws iam list-roles | grep jenkins-agent
```

5. Configure Jenkins credentials and seed job

---

You need to create Jenkins credentials for:

- Git (username/token) — used by the pipeline to push the `values.yaml` update.
- (Optional) AWS credentials if you prefer not to use IRSA for Kaniko.

Method 1 — Configure manually via Jenkins UI:

1. Open Jenkins UI (service URL from Helm release). Create credentials:
   - `kind: Username with password` for Git (id: `GIT_CREDENTIALS`).
   - (Optional) `kind: AWS Credentials` or `Secret text` for AWS tokens if using them.
2. Create a multibranch or pipeline job pointing at your app repo and use the included `Jenkinsfile` at repo root.

Method 2 — Use Jenkins Configuration as Code (JCasC) or seed jobs to auto-create credentials (not included by default).

6. Jenkins pipeline (what it does)

---

Pipeline is in `Jenkinsfile` (root of this repo). High-level steps:

- Runs on Kubernetes agent pod with Kaniko container
- Builds Docker image using Kaniko and pushes to ECR
- Clones target Helm chart repo, updates `values.yaml` with new image tag using `scripts/update_values.sh`, commits and pushes back to `main` branch

Prerequisites for pipeline to work:

- Jenkins agents must use the `jenkins-agent` ServiceAccount (controller configured by Helm values in Terraform). Kaniko will assume the IRSA role to push to ECR.
- `GIT_CREDENTIALS` must be created in Jenkins and referenced by the pipeline.
- The target Helm chart repo should allow the pipeline to push commits (token with write permission).

7. Argo CD Application & automated sync

---

- The `modules/argo_cd` module installs Argo CD. It also deploys a small Helm chart (`modules/argo_cd/charts`) that creates Argo Application resources configured in `modules/argo_cd/charts/values.yaml`.
- Ensure `applications.repoURL` in that values file points to your Git repo that contains the `charts/django-app` chart.
- Argo CD App is configured with `syncPolicy.automated` (prune + selfHeal). After the Jenkins pipeline pushes a new image tag to the Helm chart repo, Argo CD will detect the change and automatically sync the updated chart to the cluster.

8. How to test the full flow

---

1. Trigger Jenkins pipeline (push to pipeline repo or run job).
2. Pipeline builds image, pushes to ECR, and updates `values.yaml` in the Helm repo.
3. Confirm ECR image exists:

```bash
aws ecr describe-images --repository-name <repo> --image-ids imageTag=<tag>
```

4. Confirm Git commit was pushed to the Helm repo (check repo history).
5. Check Argo CD: the Application should show a new revision and a sync status of `Synced`.
6. Validate that application pods were updated:

```bash
kubectl get deployments -n django
kubectl rollout status deployment/django-deployment -n django
```

9. Cleanup

---

When finished, run:

```bash
terraform destroy -auto-approve
```

10. Troubleshooting hints

---

- If pods stay `Pending`, check node capacity (`kubectl get nodes`) and scale node group.
- If Kaniko fails to push, ensure the ServiceAccount has the IRSA role attached and the role has ECR permissions.
- If Jenkins cannot push to Git, verify `GIT_CREDENTIALS` and repository URL.
- Check Helm release status and logs for Jenkins and Argo CD:

```bash
helm list -n jenkins
kubectl logs -n jenkins deployment/jenkins -c jenkins
kubectl logs -n argocd deployment/argocd-server
```

Project layout (summary)

```
backend.tf
main.tf
variables.tf
outputs.tf
modules/
  s3-backend/
  vpc/
  ecr/
  eks/
  jenkins/
  argo_cd/
charts/
  django-app/
    Chart.yaml
    values.yaml
    templates/
      deployment.yaml
      service.yaml
      hpa.yaml
      configmap.yaml
Jenkinsfile
scripts/update_values.sh
```

Toggle RDS vs Aurora (root variable)

You can switch between creating a single RDS instance and an Aurora cluster without editing `main.tf` by using the root variable `db_use_aurora` (default: `false`). Set it in a `terraform.tfvars` file or pass it on the CLI.

Example `terraform.tfvars`:

```hcl
db_use_aurora = true
db_password    = "SuperSecretPassword123!"
```

Or pass via CLI when planning/applying:

```bash
terraform plan -var 'db_use_aurora=true' -out=plan.tfplan
terraform apply plan.tfplan
```

This allows CI/CD pipelines or environment-specific tfvars to control whether Aurora or single-instance RDS is provisioned.

Monitoring (Prometheus + Grafana)

This repository includes a monitoring module (`modules/monitoring`) which installs `kube-prometheus-stack` (Prometheus + Grafana) into the `monitoring` namespace via Helm.

- Configure the Grafana admin password using `TF_VAR_grafana_admin_password` or `terraform.tfvars`.
- To access Grafana locally use port-forwarding (example):

```bash
# forward Grafana UI
kubectl -n monitoring port-forward svc/$(terraform output -raw grafana_service) 3000:80
# open http://localhost:3000 and login with user 'admin' and the password you configured
```

Prometheus is installed alongside Grafana and will provide cluster and application metrics to Grafana dashboards.
