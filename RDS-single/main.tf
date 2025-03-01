# Aurora MySQL
# ========================================================
resource "aws_rds_cluster" "aurora-mysql-cluster" {
  count = var.db_engine.create_aurora_mysql_cluster == true ? 1 : 0

  cluster_identifier = var.aurora-mysql.cluster_name

  engine         = "aurora-mysql"
  engine_mode    = "provisioned"
  engine_version = var.aurora-mysql.engine_version

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.aurora-mysql-sg[0].id]

  port = var.aurora-mysql.port

  database_name = try(var.aurora-mysql.initial_database_name, null)

  master_username                     = var.aurora-mysql.master_username
  manage_master_user_password         = true
  master_user_secret_kms_key_id       = aws_kms_key.rds-cmk.id
  iam_database_authentication_enabled = true

  storage_encrypted       = true
  kms_key_id              = aws_kms_key.rds-cmk.arn
  backup_retention_period = var.aurora-mysql.backup_retention_period
  skip_final_snapshot     = var.aurora-mysql.skip_final_snapshot
  copy_tags_to_snapshot   = var.aurora-mysql.copy_tags_to_snapshot

  backtrack_window = var.aurora-mysql.backtrack_window

  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.monitoring_role.arn
  enabled_cloudwatch_logs_exports = var.aurora-mysql.enabled_logs_type
}

resource "aws_rds_cluster_instance" "aurora-mysql-instance" {
  count      = var.db_engine.create_aurora_mysql_cluster == true ? length(var.network.database_subnet_ids) : 0
  depends_on = [aws_rds_cluster.aurora-mysql-cluster[0]]

  identifier         = "${var.aurora-mysql.instance_name_prefix}-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora-mysql-cluster[0].id

  instance_class = var.aurora-mysql.instance_type
  engine         = "aurora-mysql"
  engine_version = var.aurora-mysql.engine_version

  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.monitoring_role.arn
  performance_insights_enabled = !startswith(var.aurora-mysql.instance_type, "db.t")
}

resource "aws_security_group" "aurora-mysql-sg" {
  count = var.db_engine.create_aurora_mysql_cluster == true ? 1 : 0

  name        = "aurora-mysql-sg"
  description = "aurora mysql security group"

  vpc_id = var.network.vpc_id

  ingress {
    from_port   = var.aurora-mysql.port
    to_port     = var.aurora-mysql.port
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

data "aws_secretsmanager_secret" "mysql_secrets" {
  count = var.db_engine.create_aurora_mysql_cluster == true ? 1 : 0
  arn   = aws_rds_cluster.aurora-mysql-cluster[0].master_user_secret[0].secret_arn
}

data "aws_secretsmanager_secret_version" "mysql_secrets_current" {
  count     = var.db_engine.create_aurora_mysql_cluster == true ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.mysql_secrets[0].id
}


# Aurora PostgreSQL
# ========================================================
resource "aws_rds_cluster" "aurora-postgres-cluster" {
  count = var.db_engine.create_aurora_postgres_cluster == true ? 1 : 0

  cluster_identifier = var.aurora-postgres.cluster_name

  engine         = "aurora-postgresql"
  engine_mode    = "provisioned"
  engine_version = var.aurora-postgres.engine_version

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.aurora-postgres-sg[0].id]

  port = var.aurora-postgres.port

  database_name = try(var.aurora-postgres.initial_database_name, null)

  master_username                     = var.aurora-postgres.master_username
  manage_master_user_password         = true
  master_user_secret_kms_key_id       = aws_kms_key.rds-cmk.id
  iam_database_authentication_enabled = true

  storage_encrypted       = true
  kms_key_id              = aws_kms_key.rds-cmk.arn
  backup_retention_period = var.aurora-postgres.backup_retention_period
  skip_final_snapshot     = var.aurora-postgres.skip_final_snapshot
  copy_tags_to_snapshot   = var.aurora-postgres.copy_tags_to_snapshot

  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.monitoring_role.arn
  enabled_cloudwatch_logs_exports = var.aurora-postgres.enabled_logs_type
}

resource "aws_rds_cluster_instance" "aurora-postgres-instance" {
  count      = var.db_engine.create_aurora_postgres_cluster == true ? length(var.network.database_subnet_ids) : 0
  depends_on = [aws_rds_cluster.aurora-postgres-cluster[0]]

  identifier         = "${var.aurora-postgres.instance_name_prefix}-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora-postgres-cluster[0].id

  instance_class = var.aurora-postgres.instance_type
  engine         = "aurora-postgresql"
  engine_version = var.aurora-postgres.engine_version

  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.monitoring_role.arn
  performance_insights_enabled = !startswith(var.aurora-postgres.instance_type, "db.t")
}

resource "aws_security_group" "aurora-postgres-sg" {
  count = var.db_engine.create_aurora_postgres_cluster == true ? 1 : 0

  name        = "aurora-postgres-sg"
  description = "aurora postgres security group"

  vpc_id = var.network.vpc_id

  ingress {
    from_port   = var.aurora-postgres.port
    to_port     = var.aurora-postgres.port
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

data "aws_secretsmanager_secret" "postgres_secrets" {
  count = var.db_engine.create_aurora_postgres_cluster == true ? 1 : 0
  arn   = aws_rds_cluster.aurora-postgres-cluster[0].master_user_secret[0].secret_arn
}

data "aws_secretsmanager_secret_version" "postgres_secrets_current" {
  count     = var.db_engine.create_aurora_postgres_cluster == true ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.postgres_secrets[0].id
}


# CMK
# ========================================================
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "rds-cmk" {
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

resource "aws_kms_alias" "rds-cmk-alias" {
  name          = "alias/rds-cmk"
  target_key_id = aws_kms_key.rds-cmk.id
}


# RDS Monitoring IAM Role
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


# RDS Subnet Group
# ========================================================
resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = "rds-subnet-group"
  description = "rds subnet group"
  subnet_ids  = var.network.database_subnet_ids
}
