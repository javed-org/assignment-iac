output "ecr_repo_names" {
  value = aws_ecr_repository.repo[*].name
}
output "ecr_repo_urls"{
value= aws_ecr_repository.repo[*].repository_url
}
