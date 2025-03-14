# ALB
# ========================================================
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


# ALB Listener
# ========================================================
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


# ALB Target Group
# ========================================================
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


# Log Destination S3 Bucket Policy update
# ========================================================
data "aws_region" "region" {}

data "aws_s3_bucket_policy" "existing_policy" {
  count = var.alb.accesslog.dest_bucket_has_policy || var.alb.connectionlog.dest_bucket_has_policy ? 1 : 0

  bucket = var.alb.accesslog.enabled ? var.alb.accesslog.bucket_name : var.alb.connectionlog.bucket_name
}

resource "aws_s3_bucket_policy" "merged_policy" {
  count = var.alb.accesslog.enabled || var.alb.connectionlog.enabled ? 1 : 0

  bucket = var.alb.accesslog.enabled == true && var.alb.accesslog.bucket_name != "" ? var.alb.accesslog.bucket_name : var.alb.connectionlog.bucket_name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : concat(can(jsondecode(data.aws_s3_bucket_policy.existing_policy[0].policy)["Statement"]) ? jsondecode(data.aws_s3_bucket_policy.existing_policy[0].policy)["Statement"] : [],
      [
        {
          "Sid" : "AWSLogDeliveryWrite",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "arn:aws:iam::${local.elb_service_accounts[data.aws_region.region.name]}:root"
          },
          "Action" : [
            "s3:PutObject"
          ],
          "Resource" : "arn:aws:s3:::${var.alb.accesslog.enabled == true && var.alb.accesslog.bucket_name != "" ? var.alb.accesslog.bucket_name : var.alb.connectionlog.bucket_name}/*",
        }
      ]
    )
  })
}


# Security Group
# ========================================================
resource "aws_security_group" "alb-sg" {
  name = "${var.alb.name}-sg"

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


# ALB Root Account ID Variable
locals {
  elb_service_accounts = {
    us-east-1      = "127311923021"
    us-east-2      = "033677994240"
    us-west-1      = "027434742980"
    us-west-2      = "797873946194"
    af-south-1     = "098369216593"
    ap-east-1      = "754344448648"
    ap-south-1     = "718504428378"
    ap-northeast-1 = "582318560864"
    ap-northeast-2 = "600734575887"
    ap-northeast-3 = "383597477331"
    ap-southeast-1 = "114774131450"
    ap-southeast-2 = "783225319266"
    ap-southeast-3 = "589379963580"
    ca-central-1   = "985666609251"
    eu-central-1   = "054676820928"
    eu-west-1      = "156460612806"
    eu-west-2      = "652711504416"
    eu-west-3      = "009996457667"
    eu-south-1     = "635631232127"
    eu-north-1     = "897822967062"
    me-south-1     = "076674570225"
    sa-east-1      = "507241528517"
    us-gov-west-1  = "048591011584"
    us-gov-east-1  = "190560391635"
    cn-north-1     = "638102146993"
    cn-northwest-1 = "037604701340"
  }
}
