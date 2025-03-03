# Elasticache
# ========================================================
resource "aws_elasticache_replication_group" "elasticache" {
  count = var.cache.serverless_enable == true ? 0 : 1

  replication_group_id = var.cache.cluster.name
  description          = "Elasticache ${var.cache.cluster.name}"

  engine         = var.cache.cluster.engine
  engine_version = var.cache.cluster.engine_version

  cluster_mode = "enabled"

  node_type               = var.cache.cluster.node_type
  num_node_groups         = var.cache.cluster.nodegroup_count
  replicas_per_node_group = var.cache.cluster.replicas_per_nodegroup

  port = var.cache.cluster.port

  subnet_group_name  = aws_elasticache_subnet_group.cache_subnet_group[0].name
  security_group_ids = [aws_security_group.cache_security_group[0].id]

  multi_az_enabled           = true
  automatic_failover_enabled = true

  at_rest_encryption_enabled = true
  kms_key_id                 = aws_kms_key.elasticache-cmk.id
  transit_encryption_enabled = true
  transit_encryption_mode    = var.cache.cluster.transit_encryption_mode

  snapshot_retention_limit = var.cache.cluster.snapshot_retention_limit

  log_delivery_configuration {
    log_type         = "slow-log"
    log_format       = "json"
    destination_type = "cloudwatch-logs"
    destination      = aws_cloudwatch_log_group.slow-log-log_group[0].name
  }

  log_delivery_configuration {
    log_type         = "engine-log"
    log_format       = "json"
    destination_type = "cloudwatch-logs"
    destination      = aws_cloudwatch_log_group.engine-log-log_group[0].name
  }

  apply_immediately = true
}


# Elasticache
# ========================================================
resource "aws_elasticache_serverless_cache" "serverless_elasticache" {
  count = var.cache.serverless_enable == true ? 1 : 0

  name                 = var.cache.serverless.name
  engine               = var.cache.serverless.engine
  major_engine_version = var.cache.serverless.engine_version

  cache_usage_limits {
    data_storage {
      minimum = var.cache.serverless.data_storage_minimum
      maximum = var.cache.serverless.data_storage_maximum
      unit    = "GB"
    }
    ecpu_per_second {
      minimum = var.cache.serverless.ecpu_per_second_minimum
      maximum = var.cache.serverless.ecpu_per_second_maximum
    }
  }

  security_group_ids = [aws_security_group.serverless_cache_security_group[0].id]
  subnet_ids         = var.network.database_subnet_ids

  kms_key_id = aws_kms_key.elasticache-cmk.arn

  daily_snapshot_time      = var.cache.serverless.daily_snapshot_time
  snapshot_retention_limit = var.cache.serverless.snapshot_retention_limit
}


# Cloudwatch Log group
# ========================================================
resource "aws_cloudwatch_log_group" "slow-log-log_group" {
  count = var.cache.serverless_enable == true ? 0 : 1

  name              = "/elasticache/${var.cache.cluster.name}/slow-log"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "engine-log-log_group" {
  count = var.cache.serverless_enable == true ? 0 : 1

  name              = "/elasticache/${var.cache.cluster.name}/engine-log"
  retention_in_days = 7
}


# Elasticache Subnet Group
# ========================================================
resource "aws_elasticache_subnet_group" "cache_subnet_group" {
  count = var.cache.serverless_enable == true ? 0 : 1

  name        = "${var.cache.cluster.name}-subnet-group"
  description = "Subnet group for ${var.cache.cluster.name}"

  subnet_ids = var.network.database_subnet_ids
}


# Security group
# ========================================================
resource "aws_security_group" "cache_security_group" {
  count = var.cache.serverless_enable == true ? 0 : 1

  name        = "${var.cache.cluster.name}-sg"
  description = "${var.cache.cluster.name} security group"

  vpc_id = var.network.vpc_id

  ingress {
    from_port   = var.cache.cluster.port
    to_port     = var.cache.cluster.port
    protocol    = "tcp"
    cidr_blocks = [var.network.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cache.cluster.name}-sg"
  }
}


# Serverless Security group
# ========================================================
resource "aws_security_group" "serverless_cache_security_group" {
  count = var.cache.serverless_enable == true ? 1 : 0

  name        = "${var.cache.serverless.name}-serverless-sg"
  description = "${var.cache.serverless.name} serverless security group"

  vpc_id = var.network.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.network.vpc_cidr]
  }

  ingress {
    from_port   = 6380
    to_port     = 6380
    protocol    = "tcp"
    cidr_blocks = [var.network.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cache.serverless.name}-serverless-sg"
  }
}


# CMK
# ========================================================
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "elasticache-cmk" {
  description             = "Elasticache CMK"
  enable_key_rotation     = true
  rotation_period_in_days = 90
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
