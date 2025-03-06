# Docdb Cluster
# ========================================================
resource "aws_docdb_global_cluster" "global-cluster" {
  provider = aws.primary

  global_cluster_identifier = var.docdb.global.name

  engine         = "docdb"
  engine_version = var.docdb.global.engine_version

  database_name = var.docdb.global.initial_database_name

  storage_encrypted = true
}


# Docdb Cluster
# ========================================================
resource "aws_docdb_cluster" "primary-cluster" {
  provider = aws.primary

  cluster_identifier = var.docdb.primary.name

  global_cluster_identifier = aws_docdb_global_cluster.global-cluster.id

  engine         = aws_docdb_global_cluster.global-cluster.engine
  engine_version = aws_docdb_global_cluster.global-cluster.engine_version

  vpc_security_group_ids = [aws_security_group.primary-documentdb-sg.id]
  db_subnet_group_name   = aws_docdb_subnet_group.primary-subnet-group.name

  port = var.docdb.global.port

  master_username = var.docdb.global.username
  master_password = var.docdb.global.password

  enabled_cloudwatch_logs_exports = var.docdb.primary.export_log_types

  storage_encrypted = true
  kms_key_id        = aws_kms_key.primary-docdb-cmk.arn

  backup_retention_period = 7

  skip_final_snapshot = true

  apply_immediately = true
}

resource "aws_docdb_cluster" "secondary-cluster" {
  provider = aws.secondary

  cluster_identifier = var.docdb.secondary.name

  global_cluster_identifier = aws_docdb_global_cluster.global-cluster.id

  engine         = aws_docdb_global_cluster.global-cluster.engine
  engine_version = aws_docdb_global_cluster.global-cluster.engine_version

  vpc_security_group_ids = [aws_security_group.secondary-documentdb-sg.id]
  db_subnet_group_name   = aws_docdb_subnet_group.secondary-subnet-group.name

  port = var.docdb.global.port

  enabled_cloudwatch_logs_exports = var.docdb.secondary.export_log_types

  storage_encrypted = true
  kms_key_id        = aws_kms_key.secondary-docdb-cmk.arn

  backup_retention_period = 7

  skip_final_snapshot = true

  apply_immediately = true

  depends_on = [aws_docdb_cluster.primary-cluster]
}


# Docdb Cluster Instance
# ========================================================
resource "aws_docdb_cluster_instance" "primary-cluster-instance" {
  provider = aws.primary
  count    = length(var.network.primary_network.database_subnet_ids)

  engine = aws_docdb_global_cluster.global-cluster.engine

  identifier = "${var.docdb.primary.instance_name_prefix}-${count.index}"

  cluster_identifier = aws_docdb_cluster.primary-cluster.id

  instance_class = var.docdb.primary.instance_type

  enable_performance_insights = !startswith(var.docdb.primary.instance_type, "db.t")

  apply_immediately = true
}

resource "aws_docdb_cluster_instance" "secondary-cluster-instance" {
  provider = aws.secondary
  count    = length(var.network.secondary_network.database_subnet_ids)

  engine = aws_docdb_global_cluster.global-cluster.engine

  identifier = "${var.docdb.secondary.instance_name_prefix}-${count.index}"

  cluster_identifier = aws_docdb_cluster.secondary-cluster.id

  instance_class = var.docdb.secondary.instance_type

  enable_performance_insights = !startswith(var.docdb.secondary.instance_type, "db.t")

  apply_immediately = true

  depends_on = [aws_docdb_cluster_instance.primary-cluster-instance]
}


# DocumentDB Subnet Group
# ========================================================
resource "aws_docdb_subnet_group" "primary-subnet-group" {
  provider = aws.primary

  name       = "docdb-primary-subnet-group"
  subnet_ids = var.network.primary_network.database_subnet_ids
}

resource "aws_docdb_subnet_group" "secondary-subnet-group" {
  provider = aws.secondary

  name       = "docdb-secondary-subnet-group"
  subnet_ids = var.network.secondary_network.database_subnet_ids
}


# CMK
# ========================================================
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "primary-docdb-cmk" {
  provider = aws.primary

  description             = "DocumentDB CMK"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "docdb-key"
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

resource "aws_kms_alias" "primary-docdb-cmk-alias" {
  provider = aws.primary

  name          = "alias/docdb-cmk"
  target_key_id = aws_kms_key.primary-docdb-cmk.id
}

resource "aws_kms_key" "secondary-docdb-cmk" {
  provider = aws.secondary

  description             = "DocumentDB CMK"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "docdb-key"
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

resource "aws_kms_alias" "secondary-docdb-cmk-alias" {
  provider = aws.secondary

  name          = "alias/docdb-cmk"
  target_key_id = aws_kms_key.secondary-docdb-cmk.id
}


# Security Group
# ========================================================
resource "aws_security_group" "primary-documentdb-sg" {
  provider = aws.primary

  name        = "primary-documentdb-sg"
  description = "DocumentDB primary security group"

  vpc_id = var.network.primary_network.vpc_id

  ingress {
    from_port   = var.docdb.global.port
    to_port     = var.docdb.global.port
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
    Name = "primary-documentdb-sg"
  }
}

resource "aws_security_group" "secondary-documentdb-sg" {
  provider = aws.secondary

  name        = "secondary-documentdb-sg"
  description = "DocumentDB secondary security group"

  vpc_id = var.network.secondary_network.vpc_id

  ingress {
    from_port   = var.docdb.global.port
    to_port     = var.docdb.global.port
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
    Name = "secondary-documentdb-sg"
  }
}
