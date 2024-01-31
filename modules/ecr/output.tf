output "ecr_repo_names" {
  value = aws_ecr_repository.repo[*].name
}
output "ecr_repo_arns"{
value= aws_ecr_repository.repo[*].arn
}
