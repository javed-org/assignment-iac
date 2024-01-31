# ECR resourse 
resource "aws_ecr_repository" "repo" {
  count = length(var.repo_name)
  name                 = "${var.project_name}-${var.environment_name}-${var.repo_name[count.index]}"
  image_tag_mutability = "MUTABLE"
  force_delete = true
  image_scanning_configuration {
    scan_on_push = true
  }
}