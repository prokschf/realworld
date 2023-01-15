resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.stage_name}-ecs-cluster"
  tags = {
    Project = var.project_name
    Stage   = var.stage_name
    Tier    = "backend"
    Name    = "ECSCluster"
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "role-name"
  tags = {
    Project = var.project_name
    Stage   = var.stage_name
    Tier    = "backend"
    Name    = "BackendTaskExecutionRole"
  }
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role" "ecs_task_role" {
  name = "role-name-task"
  tags = {
    Project = var.project_name
    Stage   = var.stage_name
    Tier    = "backend"
    Name    = "BackendTaskRole"
  }
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "task_s3" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

data "terraform_remote_state" "init-deploy_infra" {
  backend = "s3"
  config = {
    bucket = "realworld-state-terraform"
    key    = "init/deploy_infra/terraform.tfstate"
    region = "${data.aws_region.current.name}"
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_ecs_task_definition" "backend_task_def" {
  family                   = "${var.project_name}-${var.stage_name}-backend-task-def"
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "1024"
  requires_compatibilities = ["FARGATE"]
  depends_on               = [aws_ecs_cluster.main]


container_definitions = <<DEFINITION
[
  {
    "image": "${data.terraform_remote_state.init-deploy_infra.outputs.backend-ecr-names[var.stage_name]}:latest",
    "name": "backend-container",
    "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-region" : "${data.aws_region.current.name}",
                    "awslogs-group" : "backend-container-logs",
                    "awslogs-stream-prefix" : "${var.project_name}-${var.stage_name}"
                }
            }
    }
  
]
DEFINITION


  tags = {
    Project = var.project_name
    Stage   = var.stage_name
    Tier    = "backend"
    Name    = "ECSTaskDefinition"
  }
}

