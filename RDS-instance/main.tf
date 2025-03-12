# RDS Instance
# ========================================================
resource "aws_db_instance" "rds-instance" {
  identifier = var.rds.name

  engine                     = var.rds.engine
  engine_version             = var.rds.engine_version
  auto_minor_version_upgrade = true

  instance_class = var.rds.instance_class

  db_subnet_group_name = aws_db_subnet_group.rds-subnet-group.name

  username                      = var.rds.username
  manage_master_user_password   = var.rds.manage_master_user_password ? var.rds.manage_master_user_password : null
  master_user_secret_kms_key_id = var.rds.manage_master_user_password ? aws_kms_key.rds-cmk.id : null
  password                      = var.rds.manage_master_user_password ? null : var.rds.password

  db_name = var.rds.initial_database_name

  port = var.rds.port

  storage_type      = var.rds.storage_type
  allocated_storage = var.rds.allocated_storage
  iops              = var.rds.storage_type == "io1" || var.rds.storage_type == "io2" ? var.rds.iops : var.rds.storage_type == "gp3" && var.rds.allocated_storage > 400 ? var.rds.iops : null

  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds-cmk.arn

  vpc_security_group_ids = [aws_security_group.rds-sg.id]

  performance_insights_enabled          = !startswith(var.rds.instance_class, "db.t") ? true : false
  performance_insights_kms_key_id       = !startswith(var.rds.instance_class, "db.t") ? aws_kms_key.rds-cmk.arn : null
  performance_insights_retention_period = !startswith(var.rds.instance_class, "db.t") ? var.rds.performance_insights_retention_period : null
  backup_retention_period               = var.rds.backup_retention_period
  monitoring_interval                   = var.rds.monitoring_interval
  monitoring_role_arn                   = aws_iam_role.monitoring_role.arn
  skip_final_snapshot                   = true

  enabled_cloudwatch_logs_exports = var.rds.enabled_log_types
}


# RDS Subnet Group
# ========================================================
resource "aws_db_subnet_group" "rds-subnet-group" {
  name       = "${var.rds.name}-subnet-group"
  subnet_ids = var.rds.database_subnet_ids

  tags = {
    Name = "${var.rds.name}-subnet-group"
  }
}


# RDS CMK
# ========================================================
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "rds-cmk" {
  description             = "RDS Instance CMK"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "rds-instance-key"
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

resource "aws_kms_alias" "rds-cmk-alias" {
  name          = "alias/rds-instance-cmk"
  target_key_id = aws_kms_key.rds-cmk.id
}


# RDS Monitoring Role
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
  name               = "${var.rds.name}-rds-monitoring-role"
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


# RDS Security group
# ========================================================
resource "aws_security_group" "rds-sg" {
  name        = "${var.rds.name}-rds-sg"
  description = "rds security group"

  vpc_id = var.rds.vpc_id

  ingress {
    from_port   = var.rds.port
    to_port     = var.rds.port
    protocol    = "tcp"
    cidr_blocks = [var.rds.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.rds.name}-rds-sg"
  }
}


# RDS Password Secret
# ========================================================
data "aws_secretsmanager_secret" "mysql_secrets" {
  count = var.rds.manage_master_user_password == true ? 1 : 0
  arn   = aws_db_instance.rds-instance.master_user_secret[0].secret_arn
}

data "aws_secretsmanager_secret_version" "mysql_secrets_current" {
  count     = var.rds.manage_master_user_password == true ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.mysql_secrets[0].id
}
