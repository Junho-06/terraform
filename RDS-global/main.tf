resource "aws_rds_global_cluster" "rds_global_cluster" {
  provider                  = aws.primary
  global_cluster_identifier = var.rds.global_cluster_name
  engine                    = "aurora-mysql"
  database_name             = try(var.rds.initial_database_name, null)
  storage_encrypted         = true
}
resource "aws_rds_cluster" "primary-cluster" {
  provider                            = aws.primary
  engine                              = aws_rds_global_cluster.rds_global_cluster.engine
  engine_mode                         = "provisioned"
  engine_version                      = aws_rds_global_cluster.rds_global_cluster.engine_version
  cluster_identifier                  = var.rds.primary_cluster_name
  master_username                     = var.rds.username
  database_name                       = try(var.rds.initial_database_name, null)
  global_cluster_identifier           = aws_rds_global_cluster.rds_global_cluster.id
  db_subnet_group_name                = aws_db_subnet_group.primary_rds_subnet_group.name
  vpc_security_group_ids              = [aws_security_group.primary-rds-sg.id]
  port                                = var.rds.port
  master_password                     = var.rds.password
  iam_database_authentication_enabled = true
  storage_encrypted                   = true
  kms_key_id                          = aws_kms_key.primary-rds-cmk.arn
  backup_retention_period             = var.rds.backup_retention_period
  skip_final_snapshot                 = var.rds.skip_final_snapshot
  copy_tags_to_snapshot               = var.rds.copy_tags_to_snapshot
  monitoring_interval                 = 60
  monitoring_role_arn                 = aws_iam_role.monitoring_role.arn
  enabled_cloudwatch_logs_exports     = var.rds.enabled_logs_type
  apply_immediately                   = true
}
resource "aws_rds_cluster_instance" "primary-instance-1" {
  provider   = aws.primary
  depends_on = [aws_rds_cluster.primary-cluster]

  identifier         = var.rds.primary-instance1_name
  cluster_identifier = aws_rds_cluster.primary-cluster.id

  instance_class = var.rds.instance_type
  engine         = "aurora-mysql"
  engine_version = var.rds.engine_version

  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.monitoring_role.arn
  performance_insights_enabled = !startswith(var.rds.instance_type, "db.t")
}
resource "aws_rds_cluster_instance" "primary-instance-2" {
  provider   = aws.primary
  depends_on = [aws_rds_cluster.primary-cluster]

  identifier         = var.rds.primary-instance2_name
  cluster_identifier = aws_rds_cluster.primary-cluster.id

  instance_class = var.rds.instance_type
  engine         = "aurora-mysql"
  engine_version = var.rds.engine_version

  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.monitoring_role.arn
  performance_insights_enabled = !startswith(var.rds.instance_type, "db.t")
}
resource "aws_rds_cluster" "secondary-cluster" {
  provider                            = aws.secondary
  engine                              = aws_rds_global_cluster.rds_global_cluster.engine
  engine_mode                         = "provisioned"
  engine_version                      = aws_rds_global_cluster.rds_global_cluster.engine_version
  cluster_identifier                  = var.rds.secondary_cluster_name
  global_cluster_identifier           = aws_rds_global_cluster.rds_global_cluster.id
  db_subnet_group_name                = aws_db_subnet_group.secondary_rds_subnet_group.name
  vpc_security_group_ids              = [aws_security_group.secondary-rds-sg.id]
  port                                = var.rds.port
  iam_database_authentication_enabled = true
  storage_encrypted                   = true
  kms_key_id                          = aws_kms_key.secondary-rds-cmk.arn
  backup_retention_period             = var.rds.backup_retention_period
  skip_final_snapshot                 = var.rds.skip_final_snapshot
  copy_tags_to_snapshot               = var.rds.copy_tags_to_snapshot
  monitoring_interval                 = 60
  monitoring_role_arn                 = aws_iam_role.monitoring_role.arn
  enabled_cloudwatch_logs_exports     = var.rds.enabled_logs_type
  apply_immediately                   = true

  lifecycle {
    ignore_changes = [
      replication_source_identifier
    ]
  }
  depends_on = [
    aws_rds_cluster.primary-cluster,
    aws_rds_cluster_instance.primary-instance-1,
    aws_rds_cluster_instance.primary-instance-2
  ]
}
resource "aws_rds_cluster_instance" "secondary-instance-1" {
  provider   = aws.secondary
  depends_on = [aws_rds_cluster.secondary-cluster]

  identifier         = var.rds.secondary-instance1_name
  cluster_identifier = aws_rds_cluster.secondary-cluster.id

  instance_class = var.rds.instance_type
  engine         = "aurora-mysql"
  engine_version = var.rds.engine_version

  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.monitoring_role.arn
  performance_insights_enabled = !startswith(var.rds.instance_type, "db.t")
}
resource "aws_rds_cluster_instance" "secondary-instance-2" {
  provider   = aws.secondary
  depends_on = [aws_rds_cluster.secondary-cluster]

  identifier         = var.rds.secondary-instance2_name
  cluster_identifier = aws_rds_cluster.secondary-cluster.id

  instance_class = var.rds.instance_type
  engine         = "aurora-mysql"
  engine_version = var.rds.engine_version

  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.monitoring_role.arn
  performance_insights_enabled = !startswith(var.rds.instance_type, "db.t")
}
resource "aws_db_subnet_group" "primary_rds_subnet_group" {
  provider    = aws.primary
  name        = "primary-rds-subnet-group"
  description = "primary rds subnet group"
  subnet_ids  = var.primary_network.database_subnet_ids
}
resource "aws_db_subnet_group" "secondary_rds_subnet_group" {
  provider    = aws.secondary
  name        = "secondary-rds-subnet-group"
  description = "secondary rds subnet group"
  subnet_ids  = var.secondary_network.database_subnet_ids
}
resource "aws_security_group" "primary-rds-sg" {
  provider    = aws.primary
  name        = "primary-rds-sg"
  description = "primary rds security group"
  vpc_id      = var.primary_network.vpc_id
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
}
resource "aws_security_group" "secondary-rds-sg" {
  provider    = aws.secondary
  name        = "secondary-rds-sg"
  description = "secondary rds security group"
  vpc_id      = var.secondary_network.vpc_id
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
}
data "aws_caller_identity" "current" {}
resource "aws_kms_key" "primary-rds-cmk" {
  provider                = aws.primary
  description             = "RDS CMK"
  enable_key_rotation     = true
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
  provider      = aws.primary
  name          = "alias/rds-cmk"
  target_key_id = aws_kms_key.primary-rds-cmk.id
}
resource "aws_kms_key" "secondary-rds-cmk" {
  provider                = aws.secondary
  description             = "RDS CMK"
  enable_key_rotation     = true
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
  provider      = aws.secondary
  name          = "alias/rds-cmk"
  target_key_id = aws_kms_key.secondary-rds-cmk.id
}
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
  name = "rds-monitoring-role"

  assume_role_policy = data.aws_iam_policy_document.monitoring_assume_role_policy.json
}
resource "aws_iam_role_policy_attachment" "monitoring_role_policy_attach" {
  depends_on = [aws_iam_role.monitoring_role]
  role       = aws_iam_role.monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
