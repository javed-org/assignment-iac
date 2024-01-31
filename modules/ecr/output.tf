output "ecr_repo_names" {
  value = aws_ecr_repository.repo[*].name
}