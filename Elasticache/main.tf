resource "aws_elasticache_replication_group" "elasticache" {
  replication_group_id = var.cache.name
  description          = "Elasticache ${var.cache.name}"

  engine         = var.cache.engine
  engine_version = var.cache.engine_version

  cluster_mode = "enabled"

  node_type               = var.cache.node_type
  num_node_groups         = var.cache.nodegroup_count
  replicas_per_node_group = var.cache.replicas_per_nodegroup

  port = var.cache.port

  subnet_group_name  = aws_elasticache_subnet_group.cache_subnet_group.name
  security_group_ids = [aws_security_group.cache_security_group.id]

  multi_az_enabled           = true
  automatic_failover_enabled = true

  at_rest_encryption_enabled = true
  kms_key_id                 = aws_kms_key.elasticache-cmk.id
  transit_encryption_enabled = true
  transit_encryption_mode    = var.cache.transit_encryption_mode

  apply_immediately = true

  snapshot_retention_limit = var.cache.snapshot_retention_limit

  log_delivery_configuration {
    log_type         = "slow-log"
    log_format       = "json"
    destination_type = "cloudwatch-logs"
    destination      = aws_cloudwatch_log_group.slow-log-log_group.name
  }

  log_delivery_configuration {
    log_type         = "engine-log"
    log_format       = "json"
    destination_type = "cloudwatch-logs"
    destination      = aws_cloudwatch_log_group.engine-log-log_group.name
  }
}
resource "aws_cloudwatch_log_group" "slow-log-log_group" {
  name              = "/elasticache/${var.cache.name}/slow-log"
  retention_in_days = 7
}
resource "aws_cloudwatch_log_group" "engine-log-log_group" {
  name              = "/elasticache/${var.cache.name}/engine-log"
  retention_in_days = 7
}
resource "aws_elasticache_subnet_group" "cache_subnet_group" {
  name        = "${var.cache.name}-subnet-group"
  description = "Subnet group for ${var.cache.name}"
  subnet_ids  = var.network.database_subnet_ids
}
resource "aws_security_group" "cache_security_group" {
  name        = "${var.cache.name}-sg"
  description = "${var.cache.name} security group"
  vpc_id      = var.network.vpc_id
  ingress {
    from_port   = var.cache.port
    to_port     = var.cache.port
    protocol    = "tcp"
    cidr_blocks = [var.network.vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
data "aws_caller_identity" "current" {}
resource "aws_kms_key" "elasticache-cmk" {
  description             = "Elasticache CMK"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "elasticache-key"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}
resource "aws_kms_alias" "elasticache-cmk-alias" {
  name          = "alias/elasticache-cmk"
  target_key_id = aws_kms_key.elasticache-cmk.id
}
