# Global Cluster
# ========================================================
resource "aws_rds_global_cluster" "rds_global_cluster" {
  provider = aws.primary

  global_cluster_identifier = var.rds.global_cluster_name

  engine         = var.rds.engine
  engine_version = var.rds.engine == "aurora-postgresql" ? var.rds.engine_version : var.rds.engine == "aurora-mysql" ? var.rds.engine_version == "8.0" ? "8.0.mysql_aurora.3.08.1" : var.rds.engine_version == "5.7" ? "5.7.mysql_aurora.2.11.5" : null : null

  database_name = try(var.rds.initial_database_name, null)

  storage_encrypted = true
}


# Primary Cluster
# ========================================================
resource "aws_rds_cluster" "primary-cluster" {
  provider = aws.primary

  engine         = aws_rds_global_cluster.rds_global_cluster.engine
  engine_mode    = "provisioned"
  engine_version = aws_rds_global_cluster.rds_global_cluster.engine_version

  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.rds.engine_mode == "serverless" ? [1] : []

    content {
      min_capacity             = var.rds.serverless.min_capacity
      max_capacity             = var.rds.serverless.max_capacity
      seconds_until_auto_pause = var.rds.serverless.seconds_until_auto_pause
    }
  }


  cluster_identifier        = var.rds.primary_cluster_name
  global_cluster_identifier = aws_rds_global_cluster.rds_global_cluster.id

  master_username                     = var.rds.username
  master_password                     = var.rds.password
  iam_database_authentication_enabled = true

  db_subnet_group_name   = aws_db_subnet_group.primary_rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.primary-rds-sg.id]
  port                   = var.rds.port

  storage_encrypted = true
  kms_key_id        = aws_kms_key.primary-rds-cmk.arn

  backup_retention_period = var.rds.backup_retention_period
  skip_final_snapshot     = var.rds.skip_final_snapshot
  copy_tags_to_snapshot   = var.rds.copy_tags_to_snapshot

  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.monitoring_role.arn
  performance_insights_enabled    = !startswith(var.rds.provisioned.instance_type, "db.t")
  enabled_cloudwatch_logs_exports = var.rds.engine == "aurora-mysql" ? var.rds.enabled_mysql_logs_type : var.rds.engine == "aurora-postgresql" ? var.rds.enabled_postgres_logs_type : null

  apply_immediately = true
}

resource "aws_rds_cluster_instance" "primary-instance" {
  provider   = aws.primary
  depends_on = [aws_rds_cluster.primary-cluster]
  count      = length(var.primary_network.database_subnet_ids)

  identifier         = "${var.rds.primary-instance_name_prefix}-${count.index}"
  cluster_identifier = aws_rds_cluster.primary-cluster.id

  instance_class = var.rds.engine_mode == "provisioned" ? var.rds.provisioned.instance_type : var.rds.engine_mode == "serverless" ? "db.serverless" : null
  engine         = aws_rds_global_cluster.rds_global_cluster.engine
  engine_version = aws_rds_global_cluster.rds_global_cluster.engine_version

  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.monitoring_role.arn
  performance_insights_enabled = !startswith(var.rds.provisioned.instance_type, "db.t")
}


# Secondary Cluster
# ========================================================
resource "aws_rds_cluster" "secondary-cluster" {
  provider = aws.secondary

  engine         = aws_rds_global_cluster.rds_global_cluster.engine
  engine_mode    = "provisioned"
  engine_version = aws_rds_global_cluster.rds_global_cluster.engine_version

  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.rds.engine_mode == "serverless" ? [1] : []

    content {
      min_capacity             = var.rds.serverless.min_capacity
      max_capacity             = var.rds.serverless.max_capacity
      seconds_until_auto_pause = var.rds.serverless.seconds_until_auto_pause
    }
  }

  cluster_identifier        = var.rds.secondary_cluster_name
  global_cluster_identifier = aws_rds_global_cluster.rds_global_cluster.id

  db_subnet_group_name   = aws_db_subnet_group.secondary_rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.secondary-rds-sg.id]
  port                   = var.rds.port

  iam_database_authentication_enabled = true

  storage_encrypted = true
  kms_key_id        = aws_kms_key.secondary-rds-cmk.arn

  backup_retention_period = var.rds.backup_retention_period
  skip_final_snapshot     = var.rds.skip_final_snapshot
  copy_tags_to_snapshot   = var.rds.copy_tags_to_snapshot

  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.monitoring_role.arn
  performance_insights_enabled    = !startswith(var.rds.provisioned.instance_type, "db.t")
  enabled_cloudwatch_logs_exports = var.rds.engine == "aurora-mysql" ? var.rds.enabled_mysql_logs_type : var.rds.engine == "aurora-postgresql" ? var.rds.enabled_postgres_logs_type : null

  apply_immediately = true

  lifecycle {
    ignore_changes = [
      replication_source_identifier
    ]
  }

  depends_on = [
    aws_rds_cluster.primary-cluster
  ]
}

resource "aws_rds_cluster_instance" "secondary-instance" {
  provider   = aws.secondary
  depends_on = [aws_rds_cluster.secondary-cluster]
  count      = length(var.secondary_network.database_subnet_ids)

  identifier         = "${var.rds.secondary-instance_name_prefix}-${count.index}"
  cluster_identifier = aws_rds_cluster.secondary-cluster.id

  instance_class = var.rds.engine_mode == "provisioned" ? var.rds.provisioned.instance_type : var.rds.engine_mode == "serverless" ? "db.serverless" : null
  engine         = aws_rds_global_cluster.rds_global_cluster.engine
  engine_version = aws_rds_global_cluster.rds_global_cluster.engine_version

  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.monitoring_role.arn
  performance_insights_enabled = !startswith(var.rds.provisioned.instance_type, "db.t")
}


# Subnet Groups
# ========================================================
resource "aws_db_subnet_group" "primary_rds_subnet_group" {
  provider = aws.primary

  name        = "primary-rds-subnet-group"
  description = "primary rds subnet group"

  subnet_ids = var.primary_network.database_subnet_ids
}

resource "aws_db_subnet_group" "secondary_rds_subnet_group" {
  provider = aws.secondary

  name        = "secondary-rds-subnet-group"
  description = "secondary rds subnet group"

  subnet_ids = var.secondary_network.database_subnet_ids
}


# Security Groups
# ========================================================
resource "aws_security_group" "primary-rds-sg" {
  provider = aws.primary

  name        = "primary-rds-sg"
  description = "primary rds security group"

  vpc_id = var.primary_network.vpc_id

  ingress {
    from_port   = var.rds.port
    to_port     = var.rds.port
    protocol    = "tcp"
    cidr_blocks = [var.primary_network.vpc_cidr, var.secondary_network.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "primary-rds-sg"
  }
}

resource "aws_security_group" "secondary-rds-sg" {
  provider = aws.secondary

  name        = "secondary-rds-sg"
  description = "secondary rds security group"

  vpc_id = var.secondary_network.vpc_id

  ingress {
    from_port   = var.rds.port
    to_port     = var.rds.port
    protocol    = "tcp"
    cidr_blocks = [var.primary_network.vpc_cidr, var.secondary_network.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "secondary-rds-sg"
  }
}


# CMK
# ========================================================
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "primary-rds-cmk" {
  provider = aws.primary

  description             = "RDS CMK"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "rds-key"
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

resource "aws_kms_alias" "primary-rds-cmk-alias" {
  provider = aws.primary

  name          = "alias/rds-cmk"
  target_key_id = aws_kms_key.primary-rds-cmk.id
}

resource "aws_kms_key" "secondary-rds-cmk" {
  provider = aws.secondary

  description             = "RDS CMK"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "rds-key"
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

resource "aws_kms_alias" "secondary-rds-cmk-alias" {
  provider = aws.secondary

  name          = "alias/rds-cmk"
  target_key_id = aws_kms_key.secondary-rds-cmk.id
}


# Monitoring Role
# ========================================================
data "aws_iam_policy_document" "monitoring_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "monitoring_role" {
  name               = "rds-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.monitoring_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "monitoring_role_policy_attach" {
  role       = aws_iam_role.monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_iam_role_policy_attachments_exclusive" "delete-iam-policy" {
  role_name = aws_iam_role.monitoring_role.name
  policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  ]
}
