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

resource "aws_cloudwatch_log_group" "example-production-client" {
  name = "backend-container-logs"

  tags = {
    Environment = "production"
  }
}

resource "aws_ecs_task_definition" "backend_task_def" {
  family                   = "${var.project_name}-${var.stage_name}-backend-task-def"
  #task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  runtime_platform  {
    cpu_architecture         = "X86_64"
     operating_system_family  = "LINUX"
  }
  requires_compatibilities = ["FARGATE"]
  depends_on               = [aws_ecs_cluster.main]


  container_definitions = <<DEFINITION
[
  {
    "image": "${data.terraform_remote_state.init-deploy_infra.outputs.backend-ecr-names[var.stage_name]}:latest",
    "name": "backend-${var.stage_name}-container",
    "portMappings": [
      {
        "hostPort": 8080,
        "protocol": "tcp",
        "containerPort": 8080,
        "appProtocol": "http"
      }
    ],
    "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-region" : "eu-central-1",
                    "awslogs-group" : "backend-container-logs",
                    "awslogs-stream-prefix" : "ecs"
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


resource "aws_ecs_service" "main" {
  name                               = "${var.project_name}-service-${var.stage_name}"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.backend_task_def.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  depends_on                         = [aws_ecs_task_definition.backend_task_def, aws_alb_target_group.main]

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.public_subnet.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.main.arn
    container_name   = "backend-${var.stage_name}-container"
    container_port   = 8080
  }

  #lifecycle {
  #  ignore_changes = [task_definition, desired_count]
  #}
}
