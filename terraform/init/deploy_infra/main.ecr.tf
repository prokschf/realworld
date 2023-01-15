

resource "aws_ecr_repository" "backend-ecrs" {
  for_each = var.stage_names
  name = "${var.project_name}-${each.key}-backend-ecr"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
      Project = var.project_name
      Stage = each.key     
      Tier = "backend" 
  }
}

output "backend-ecr-names" {
  value       = {for ecr in aws_ecr_repository.backend-ecrs : "${ecr.tags["Stage"]}" => ecr.repository_url}
}
