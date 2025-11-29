# Create a Kubernetes secret with Docker config for ECR (used by Kaniko)
# This uses the ECR authorization token to populate .dockerconfigjson.

locals {
  # derive registry host from provided ECR repo URL
  registry = length(var.ecr_repository_url) > 0 ? split("/", replace(var.ecr_repository_url, "https://", ""))[0] : ""
}

# Get ECR authorization token for current account
data "aws_ecr_authorization_token" "token" {}

resource "kubernetes_secret" "kaniko_secret" {
  metadata {
    name      = "kaniko-secret"
    namespace = var.service_account_namespace
  }

  data = {
    ".dockerconfigjson" = base64encode(jsonencode({
      auths = {
        (local.registry) = {
          username = "AWS"
          password = split(":", base64decode(data.aws_ecr_authorization_token.token.authorization_token))[1]
          auth     = data.aws_ecr_authorization_token.token.authorization_token
          email    = "none"
        }
      }
    }))
  }

  type = "kubernetes.io/dockerconfigjson"
}
