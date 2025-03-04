# Elasticache Global Datastore
# ========================================================
resource "aws_elasticache_global_replication_group" "global_datastore" {
  provider = aws.primary

  global_replication_group_id_suffix = var.cache.global.name_suffix

  primary_replication_group_id = aws_elasticache_replication_group.primary-elasticache.id
  engine_version               = var.cache.global.engine_version
}


# Primary Elasticache
# ========================================================
resource "aws_elasticache_replication_group" "primary-elasticache" {
  provider = aws.primary

  replication_group_id = var.cache.primary.name
  description          = "Elasticache ${var.cache.primary.name}"

  engine         = var.cache.primary.engine
  engine_version = var.cache.primary.engine_version

  cluster_mode = "enabled"

  node_type               = var.cache.primary.node_type
  num_node_groups         = var.cache.primary.nodegroup_count
  replicas_per_node_group = var.cache.primary.replicas_per_nodegroup

  port = var.cache.primary.port

  subnet_group_name  = aws_elasticache_subnet_group.primary_cache_subnet_group.name
  security_group_ids = [aws_security_group.primary_cache_security_group.id]

  multi_az_enabled           = true
  automatic_failover_enabled = true

  at_rest_encryption_enabled = true
  kms_key_id                 = aws_kms_key.primary-elasticache-cmk.id
  transit_encryption_enabled = true
  transit_encryption_mode    = "required"

  snapshot_retention_limit = var.cache.primary.snapshot_retention_limit

  log_delivery_configuration {
    log_type         = "slow-log"
    log_format       = "json"
    destination_type = "cloudwatch-logs"
    destination      = aws_cloudwatch_log_group.primary_slow-log-log_group.name
  }

  log_delivery_configuration {
    log_type         = "engine-log"
    log_format       = "json"
    destination_type = "cloudwatch-logs"
    destination      = aws_cloudwatch_log_group.primary_engine-log-log_group.name
  }

  apply_immediately = true
}


# Secondary Elasticache
# ========================================================
resource "aws_elasticache_replication_group" "secondary-elasticache" {
  provider = aws.secondary

  global_replication_group_id = aws_elasticache_global_replication_group.global_datastore.id

  replication_group_id = var.cache.secondary.name
  description          = "Elasticache ${var.cache.secondary.name}"

  subnet_group_name  = aws_elasticache_subnet_group.secondary_cache_subnet_group.name
  security_group_ids = [aws_security_group.secondary_cache_security_group.id]

  port = var.cache.secondary.port

  automatic_failover_enabled = true
  multi_az_enabled           = true

  replicas_per_node_group = var.cache.secondary.replicas_per_node_group

  kms_key_id = aws_kms_key.secondary-elasticache-cmk.id

  snapshot_retention_limit = var.cache.secondary.snapshot_retention_limit

  log_delivery_configuration {
    log_type         = "slow-log"
    log_format       = "json"
    destination_type = "cloudwatch-logs"
    destination      = aws_cloudwatch_log_group.secondary_slow-log-log_group.name
  }

  log_delivery_configuration {
    log_type         = "engine-log"
    log_format       = "json"
    destination_type = "cloudwatch-logs"
    destination      = aws_cloudwatch_log_group.secondary_engine-log-log_group.name
  }

  apply_immediately = true
}


# Primary Cloudwatch Log group
# ========================================================
resource "aws_cloudwatch_log_group" "primary_slow-log-log_group" {
  provider = aws.primary

  name              = "/elasticache/${var.cache.primary.name}/slow-log"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "primary_engine-log-log_group" {
  provider = aws.primary

  name              = "/elasticache/${var.cache.primary.name}/engine-log"
  retention_in_days = 7
}


# Secondary Cloudwatch Log group
# ========================================================
resource "aws_cloudwatch_log_group" "secondary_slow-log-log_group" {
  provider = aws.secondary

  name              = "/elasticache/${var.cache.secondary.name}/slow-log"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "secondary_engine-log-log_group" {
  provider = aws.secondary

  name              = "/elasticache/${var.cache.secondary.name}/engine-log"
  retention_in_days = 7
}


# Primary Elasticache Subnet Group
# ========================================================
resource "aws_elasticache_subnet_group" "primary_cache_subnet_group" {
  provider = aws.primary

  name        = "${var.cache.primary.name}-subnet-group"
  description = "Subnet group for ${var.cache.primary.name}"

  subnet_ids = var.network.primary_network.database_subnet_ids
}


# Secondary Elasticache Subnet Group
# ========================================================
resource "aws_elasticache_subnet_group" "secondary_cache_subnet_group" {
  provider = aws.secondary

  name        = "${var.cache.secondary.name}-subnet-group"
  description = "Subnet group for ${var.cache.secondary.name}"

  subnet_ids = var.network.secondary_network.database_subnet_ids
}


# Primary Security group
# ========================================================
resource "aws_security_group" "primary_cache_security_group" {
  provider = aws.primary

  name        = "${var.cache.primary.name}-sg"
  description = "${var.cache.primary.name} security group"

  vpc_id = var.network.primary_network.vpc_id

  ingress {
    from_port   = var.cache.primary.port
    to_port     = var.cache.primary.port
    protocol    = "tcp"
    cidr_blocks = [var.network.primary_network.vpc_cidr, var.network.secondary_network.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cache.primary.name}-sg"
  }
}


# Secondary Security group
# ========================================================
resource "aws_security_group" "secondary_cache_security_group" {
  provider = aws.secondary

  name        = "${var.cache.secondary.name}-sg"
  description = "${var.cache.secondary.name} security group"

  vpc_id = var.network.secondary_network.vpc_id

  ingress {
    from_port   = var.cache.secondary.port
    to_port     = var.cache.secondary.port
    protocol    = "tcp"
    cidr_blocks = [var.network.secondary_network.vpc_cidr, var.network.primary_network.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cache.secondary.name}-sg"
  }
}


# Primary CMK
data "aws_caller_identity" "current" {}
# ========================================================
resource "aws_kms_key" "primary-elasticache-cmk" {
  provider = aws.primary

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

resource "aws_kms_alias" "primary-elasticache-cmk-alias" {
  provider = aws.primary

  name          = "alias/elasticache-cmk"
  target_key_id = aws_kms_key.primary-elasticache-cmk.id
}


# Secondary CMK
# ========================================================
resource "aws_kms_key" "secondary-elasticache-cmk" {
  provider = aws.secondary

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

resource "aws_kms_alias" "secondary-elasticache-cmk-alias" {
  provider = aws.secondary

  name          = "alias/elasticache-cmk"
  target_key_id = aws_kms_key.secondary-elasticache-cmk.id
}
