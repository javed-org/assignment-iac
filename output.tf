output "eks-cluster-name" {
  value = module.eks.eks-cluster-name
}
output "ecr_repo_names" {
  value = module.ecr.ecr_repo_names
}
output "ecr_repo_arns" {
  value = module.ecr.ecr_repo_arns
}

