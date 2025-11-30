# RUNBOOK: Final Project (EKS + CI/CD + RDS + ECR + Monitoring)

This runbook describes how to initialize, deploy, verify, and tear down the final project infrastructure implemented with Terraform and Helm.

IMPORTANT: This creates AWS resources that may incur charges. Use a test AWS account and destroy resources after verification.

Prerequisites

- AWS CLI configured with credentials that have permission to create resources (VPC, EKS, IAM, RDS, ECR).
- Terraform >= 1.0 installed
- kubectl installed
- Access to the repo and required Terraform variables (DB password, grafana password)

Set required environment variables before running (example):

```bash
export AWS_REGION=eu-central-1
export TF_VAR_db_password="YourDbPasswordHere"
export TF_VAR_grafana_admin_password="YourGrafanaPassword"
export TF_VAR_vpc_id=""
# If using a fresh run, set TF_VAR_subnet_ids with private subnet IDs or let the vpc module create them.
```

1. Initialize Terraform

```bash
terraform init
```

2. Review and plan

```bash
terraform plan -out=plan.tfplan
```

3. Apply (creates resources)

```bash
terraform apply plan.tfplan
# or interactively
terraform apply
```

4. Verify Kubernetes components

After the apply completes, the EKS cluster and Helm releases will be installed. Use `kubectl` (your kubectl must be able to talk to the created cluster; the Terraform `kubernetes` provider in this repo is configured to use the cluster outputs).

```bash
kubectl get all -n jenkins
kubectl get all -n argocd
kubectl get all -n monitoring
```

5. Port-forward to access UIs

Jenkins (local 8080):

```bash
kubectl -n jenkins port-forward svc/jenkins 8080:8080
# Open http://localhost:8080
```

Argo CD (local 8081):

```bash
kubectl -n argocd port-forward svc/argocd-server 8081:443
# Open https://localhost:8081
```

Grafana (local 3000):

```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
# Open http://localhost:3000
# Login: admin / (value of TF_VAR_grafana_admin_password)
```

6. Verify monitoring

- Grafana should have a Prometheus datasource pre-configured (chart values provision it). If not present, add datasource pointing to `http://kube-prometheus-stack-prometheus:9090`.
- Check sample dashboard: a basic dashboard named "Sample Overview" is provisioned by a ConfigMap created by the module.

7. Verify CI/CD

- Jenkins: create a job/pipeline that builds and pushes an image to the ECR repository exposed by `terraform output ecr_repository_url`.
- Ensure the `kaniko-secret` exists in `jenkins` namespace and is used by your pipeline to authenticate with ECR.
- Argo CD: open UI, add or check the provided example applications (the module includes a sample chart under `modules/argo_cd/charts`). Verify sync status.

8. Verify RDS

- Check outputs: `terraform output rds_instance_endpoint` and `terraform output rds_cluster_endpoint`.
- Confirm security group rules: module accepts `allowed_security_group_ids` for secure access from app SGs.

9. Cleanup (destroy resources)

```bash
terraform destroy
# or selectively destroy
terraform destroy -target=module.rds
```

Notes & Recommendations

- Secrets: do not commit `TF_VAR_db_password` or passwords to Git. Use CI secret stores.
- Jenkins admin password in chart values is for quick testing only — consider using Kubernetes Secret or JCasC.
- IAM: Jenkins agent role is scoped to the ECR ARN when available. Review `modules/jenkins/irsa.tf` and `modules/ecr` repository policy for production hardening.

Troubleshooting

- If `kubectl` cannot reach cluster, ensure `aws eks update-kubeconfig --name <cluster-name>` or verify kubeconfig used by providers.
- If Helm release fails, inspect release logs from `helm`/`kubectl describe` and check chart values in `modules/*/values.yaml`.

Contact

- Repo maintainer: local developer
