resource "aws_lb" "main" {
  name               = "${var.project_name}-alb-${var.stage_name}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.private_subnet.*.id
 
  enable_deletion_protection = false

  tags = {
    Project = var.project_name
    Stage   = var.stage_name
    Tier    = "backend"
    Name    = "BackendALB"
  }

}
 
resource "aws_alb_target_group" "main" {
  name        = "${var.project_name}-tg-${var.stage_name}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
 
   tags = {
    Project = var.project_name
    Stage   = var.stage_name
    Tier    = "backend"
    Name    = "BackendALBTargetGroup80"
  }

}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = 80
  protocol          = "HTTP"
 
  default_action {
   type = "forward" 
   target_group_arn = aws_alb_target_group.main.arn
  }

  tags = {
    Project = var.project_name
    Stage   = var.stage_name
    Tier    = "backend"
    Name    = "BackendALBListener80"
  }

}

/* 
resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_lb.main.id
  port              = 443
  protocol          = "HTTPS"
 
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.alb_tls_cert_arn
 
  default_action {
    target_group_arn = aws_alb_target_group.main.id
    type             = "forward"
  }

    tags = {
    Project = var.project_name
    Stage   = var.stage_name
    Tier    = "backend"
    Name    = "BackendALBListener443"
  }

}*/

