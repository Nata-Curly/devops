# IRSA: create OIDC provider (if requested), IAM role and policy for Jenkins agents, and Kubernetes ServiceAccount

locals {
  sa_namespace = var.service_account_namespace
  sa_name      = var.service_account_name
}

# Fetch EKS cluster info
data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.eks_cluster_name
}

# TLS cert to compute thumbprint for OIDC provider
data "tls_certificate" "oidc" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  count = var.create_oidc_provider ? 1 : 0
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
  url             = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

# IAM role for Jenkins agents
resource "aws_iam_role" "jenkins_agent" {
  name = "jenkins-agent-${var.eks_cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.create_oidc_provider ? aws_iam_openid_connect_provider.eks[0].arn : data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            # subject must match the service account
            "${replace(replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", ""), ":", "")} :sub" = "system:serviceaccount:${local.sa_namespace}:${local.sa_name}"
          }
        }
      }
    ]
  })
}

# Policy for pushing to ECR and reading SSM/secrets if needed
data "aws_iam_policy_document" "ecr_policy" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "jenkins_ecr_policy" {
  name        = "jenkins-ecr-policy-${var.eks_cluster_name}"
  description = "Allow Jenkins agents to push images to ECR and read images"
  policy      = data.aws_iam_policy_document.ecr_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_ecr" {
  role       = aws_iam_role.jenkins_agent.name
  policy_arn = aws_iam_policy.jenkins_ecr_policy.arn
}

# Create Kubernetes ServiceAccount with annotation for IRSA
resource "kubernetes_service_account" "jenkins_agent" {
  metadata {
    name      = local.sa_name
    namespace = local.sa_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.jenkins_agent.arn
    }
  }
}

output "jenkins_agent_role_arn" {
  value = aws_iam_role.jenkins_agent.arn
}

output "jenkins_agent_serviceaccount" {
  value = "${local.sa_namespace}/${local.sa_name}"
}
