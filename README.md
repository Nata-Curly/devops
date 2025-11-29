# AWS Django EKS Infrastructure — Terraform + Helm + CI/CD

This repository provisions AWS infrastructure for a Django application using Terraform, deploys the application to EKS using Helm, and includes CI/CD components: Jenkins (built with Helm via Terraform) and Argo CD (also installed via Helm + Terraform).

This README documents how to bootstrap the infrastructure, install Jenkins and Argo CD, configure IRSA for Jenkins agents (Kaniko), and run the Jenkins pipeline that builds and pushes Docker images to ECR and updates the Helm chart in Git. It also shows how Argo CD will pick up those changes and sync the cluster.

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

1) Bootstrap backend & init

---

Create or confirm S3 bucket and DynamoDB table for Terraform state. Update `backend.tf` if needed.

Initialize Terraform:

```bash
terraform init
```

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

