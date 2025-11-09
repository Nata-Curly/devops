data "aws_caller_identity" "current" {}

resource "aws_ecr_repository" "repo" {
  name                 = var.ecr_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = {
    Name = var.ecr_name
    Env  = "lesson-7"
  }
}

# Simple repository policy: give full access to the account root (typical for CI/CD flows)
data "aws_iam_policy_document" "repo_policy" {
  statement {
    sid = "AllowAccountFullAccess"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions = [
      "ecr:*"
    ]
  }
}

resource "aws_ecr_repository_policy" "policy" {
  repository = aws_ecr_repository.repo.name
  policy     = data.aws_iam_policy_document.repo_policy.json
}
