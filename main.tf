terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
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
  vpc_name           = "lesson-7-vpc"
}

# ECR module
module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-7-ecr"
  scan_on_push = true
}

# EKS module
module "eks" {
  source          = "./modules/eks"          
  cluster_name    = "lesson7-eks-cluster"            
  subnet_ids      = module.vpc.private_subnets     
  instance_type   = "t3.micro"                    
  desired_size    = 1                             
  max_size        = 2                             
  min_size        = 1                             
}
