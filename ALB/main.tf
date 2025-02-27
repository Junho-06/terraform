resource "aws_lb" "alb" {
  name               = var.alb.name
  internal           = var.alb.internal
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb-sg.id]
  subnets         = var.alb.internal ? var.alb.private_subnets : var.alb.public_subnets

  enable_cross_zone_load_balancing = var.alb.enable_cross_zone_load_balancing
  enable_http2                     = var.alb.enable_http2

  idle_timeout         = var.alb.idle_timeout
  preserve_host_header = var.alb.preserve_host_header

  access_logs {
    enabled = var.alb.accesslog.enabled
    bucket  = var.alb.accesslog.bucket_name
    prefix  = var.alb.accesslog.bucket_prefix != "" ? var.alb.accesslog.bucket_prefix : null
  }

  connection_logs {
    enabled = var.alb.connectionlog.enabled
    bucket  = var.alb.connectionlog.bucket_name
    prefix  = var.alb.connectionlog.bucket_prefix != "" ? var.alb.connectionlog.bucket_prefix : null
  }

  depends_on = [aws_s3_bucket_policy.merged_policy]
}
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn

  protocol = var.alb.listener_protocol
  port     = var.alb.listener_port

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = "404"
    }
  }
}
resource "aws_lb_target_group" "alb_target_group" {

  name        = var.tg.name
  target_type = var.tg.target_type

  ip_address_type  = "ipv4"
  protocol         = var.tg.protocol
  protocol_version = var.tg.protocol_version

  port                 = var.tg.target_port
  deregistration_delay = var.tg.deregistration_delay

  vpc_id = var.tg.vpc_id

  load_balancing_algorithm_type = var.tg.load_balancing_algorithm_type

  health_check {
    enabled = true

    protocol = var.tg.health_check_protocol
    port     = var.tg.health_check_port
    path     = var.tg.health_check_path

    healthy_threshold   = var.tg.health_check_healthy_threshold
    unhealthy_threshold = var.tg.health_check_unhealthy_threshold
    interval            = var.tg.health_check_interval
    timeout             = var.tg.health_check_timeout
  }
}

locals {
  new_policy = {
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_region.region.name == "ap-northeast-2" ? "600734575887" : ""}:root"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${var.alb.accesslog.bucket_name != "" ? var.alb.accesslog.bucket_name : var.alb.connectionlog.bucket_name}/${var.alb.accesslog.bucket_prefix != "" ? var.alb.accesslog.bucket_prefix : var.alb.connectionlog.bucket_prefix}/*"
      }
    ]
  }
}
data "aws_region" "region" {}
data "aws_caller_identity" "current" {}
resource "aws_s3_bucket_policy" "merged_policy" {
  count  = var.alb.accesslog.enabled ? 1 : var.alb.connectionlog.enabled ? 1 : 0
  bucket = var.alb.accesslog.bucket_name != "" ? var.alb.accesslog.bucket_name : var.alb.connectionlog.bucket_name

  policy = jsonencode(
    local.new_policy
  )
}
resource "aws_security_group" "alb-sg" {
  name   = "${var.alb.name}-sg"
  vpc_id = var.tg.vpc_id
  ingress {
    from_port   = var.alb.listener_port
    to_port     = var.alb.listener_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.alb.name}-sg"
  }
}
