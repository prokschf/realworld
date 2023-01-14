resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.stage_name}-ecs-cluster"
  tags = {
    Project = var.project_name
    Stage   = var.stage_name
    Tier    = "backend"
    Name    = "ECSCluster"
  }
}