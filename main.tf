terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

# After EKS cluster is created we configure kubernetes/helm providers using the cluster info.
# Data sources below reference outputs from the `eks` module defined further down.
data "aws_eks_cluster" "cluster" {
  name = module.eks.eks_cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.eks_cluster_name
}

provider "kubernetes" {
  host                   = module.eks.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = module.eks.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# S3-Backend module
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "go-it-hw-devops-lesson7-20251108"
  table_name  = "terraform-locks"
}

# VPC module
module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  vpc_name           = "lesson-8-9-vpc"
}

# ECR module
module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-8-9-ecr"
  scan_on_push = true
}

# EKS module
module "eks" {
  source          = "./modules/eks"          
  cluster_name    = "lesson7-eks-cluster"            
  subnet_ids      = module.vpc.private_subnets     
  instance_type   = "t3.micro"                    
  desired_size    = 3                             
  max_size        = 4                             
  min_size        = 1                             
}

# Install Jenkins into the cluster via Helm (module uses root providers)
module "jenkins" {
  source       = "./modules/jenkins"
  release_name = "jenkins"
  namespace    = "jenkins"
  chart        = var.jenkins_chart
  chart_repo   = var.jenkins_chart_repo
  chart_version = var.jenkins_chart_version
  eks_cluster_name = module.eks.eks_cluster_name
  service_account_name = "jenkins-agent"
  service_account_namespace = "jenkins"
  ecr_repository_url = module.ecr.repository_url
}

# Install Argo CD via Helm and create Argo Applications
module "argo_cd" {
  source        = "./modules/argo_cd"
  release_name  = "argo-cd"
  namespace     = "argocd"
  chart         = var.argocd_chart
  chart_repo    = var.argocd_chart_repo
  chart_version = var.argocd_chart_version
}
