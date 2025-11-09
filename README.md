# AWS Django EKS Infrastructure — Terraform & Helm

## Overview

This project automates the deployment of a Django application to AWS using Terraform for infrastructure and Helm for Kubernetes application management. It includes:

- S3 backend with DynamoDB locking for Terraform state
- VPC with public/private subnets, NAT, IGW
- ECR repository for Docker images
- EKS cluster with managed node group
- Helm chart for Django app (Deployment, Service, HPA, ConfigMap)

---

## Infrastructure Modules

### 1. S3 Backend & DynamoDB Locking

- **Purpose:** Store Terraform state remotely and enable state locking.
- **Creates:**
  - S3 bucket (versioned, encrypted, public access blocked)
  - DynamoDB table for state locks
- **Variables:**
  - `bucket_name` — S3 bucket name
  - `table_name` — DynamoDB table name
- **Notes:**
  - Bucket must be globally unique. Create manually or bootstrap locally, then migrate state.

### 2. VPC

- **Purpose:** Isolated network for AWS resources.
- **Creates:**
  - VPC with custom CIDR
  - 3 public + 3 private subnets
  - Internet Gateway
  - NAT Gateway (with Elastic IP)
  - Public/private route tables
- **Variables:**
  - `vpc_cidr_block`, `public_subnets`, `private_subnets`, `availability_zones`, `vpc_name`
- **Notes:**
  - NAT Gateway and Elastic IP are billable. Destroy after use to avoid charges.

### 3. ECR Repository

- **Purpose:** Store Docker images for deployment.
- **Creates:**
  - ECR repository
  - Optional image scan-on-push
  - Repository policy for account access
- **Variables:**
  - `ecr_name`, `scan_on_push`
- **Outputs:**
  - `repository_url` — for Docker push/pull

### 4. EKS Cluster & Node Group

- **Purpose:** Managed Kubernetes cluster for app deployment.
- **Creates:**
  - EKS cluster
  - Managed node group (scalable EC2 workers)
  - IAM roles/policies for cluster and nodes
- **Variables:**
  - `cluster_name`, `node_group_name`, `instance_type`, `desired_size`, `max_size`, `min_size`, `subnet_ids`
- **Notes:**
  - Node group scaling controls number of worker nodes for pods.

---

## Application Deployment (Helm)

### Helm Chart Structure

- **Deployment:**
  - Uses Docker image from ECR
  - Connects ConfigMap via `envFrom`
  - Replica count and image settings from `values.yaml`
- **Service:**
  - Type: `LoadBalancer` for external access
  - Port 80 → 8000
- **HPA (Horizontal Pod Autoscaler):**
  - Scales pods from 2 to 6 if CPU > 70%
- **ConfigMap:**
  - Stores Django environment variables (SECRET_KEY, DEBUG, ALLOWED_HOSTS)
- **values.yaml:**
  - Centralized parameters for image, service, config, autoscaler

---

## Usage Guide

### 1. Bootstrap Backend

- Create S3 bucket and DynamoDB table (manually or via module)
- Update `backend.tf` with your bucket name

### 2. Deploy Infrastructure

```bash
terraform init
terraform apply
```

### 3. Build & Push Docker Image

- Build Django image
- Tag and push to ECR using output `repository_url`

### 4. Deploy Django App to EKS

- Update `values.yaml` with ECR image URL and tag
- Install via Helm:

```bash
helm upgrade --install django-app ./charts/django-app --namespace django --create-namespace
```

### 5. Access Application

- Get external address:

```bash
kubectl get svc -n django
```

- Open EXTERNAL-IP in browser

---

## Cleanup

- Destroy resources to avoid charges:

```bash
terraform destroy -auto-approve
```

---

## Notes

- IAM roles must allow ECR access for nodes
- NAT Gateway and Elastic IP incur costs
- Always backup Terraform state before destroy
- For troubleshooting, check pod logs and Helm status

---

## Project Structure

```
backend.tf
main.tf
outputs.tf
modules/
  s3-backend/
  vpc/
  ecr/
  eks/
charts/
  django-app/
    Chart.yaml
    values.yaml
    templates/
      deployment.yaml
      service.yaml
      hpa.yaml
      configmap.yaml
```
