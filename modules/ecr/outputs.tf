output "repository_url" {
  description = "URL of the created ECR repository"
  value       = aws_ecr_repository.repo.repository_url
}

output "repository_arn" {
  value = aws_ecr_repository.repo.arn
}
