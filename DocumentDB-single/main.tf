# Elastic Docdb Cluster
# ========================================================
resource "aws_docdbelastic_cluster" "elastic-cluster" {
  count = var.docdb.elastic_cluster_enable == true ? 1 : 0

  name = var.docdb.elastic.name

  subnet_ids             = var.docdb.database_subnet_ids
  vpc_security_group_ids = [aws_security_group.documentdb-sg.id]

  auth_type = "PLAIN_TEXT"

  shard_capacity = var.docdb.elastic.shard_capacity
  shard_count    = var.docdb.elastic.shard_count

  admin_user_name     = var.docdb.elastic.username
  admin_user_password = var.docdb.elastic.password

  kms_key_id = aws_kms_key.docdb-cmk.arn

  backup_retention_period = 7
}


# Docdb Cluster
# ========================================================
resource "aws_docdb_cluster" "cluster" {
  count = var.docdb.elastic_cluster_enable == false ? 1 : 0

  cluster_identifier = var.docdb.normal.name

  engine         = "docdb"
  engine_version = var.docdb.normal.engine_version

  vpc_security_group_ids = [aws_security_group.documentdb-sg.id]
  db_subnet_group_name   = aws_docdb_subnet_group.subnet-group[0].name

  port = var.docdb.port

  master_username = var.docdb.normal.username
  master_password = var.docdb.normal.password

  enabled_cloudwatch_logs_exports = var.docdb.normal.export_log_types

  storage_encrypted = true
  kms_key_id        = aws_kms_key.docdb-cmk.arn

  backup_retention_period = 7

  skip_final_snapshot = true

  apply_immediately = true
}


# Docdb Cluster Instance
# ========================================================
resource "aws_docdb_cluster_instance" "cluster-instance" {
  count = var.docdb.elastic_cluster_enable == false ? length(var.docdb.database_subnet_ids) : 0

  engine = "docdb"

  identifier = "${var.docdb.normal.instance_name_prefix}-${count.index}"

  cluster_identifier = aws_docdb_cluster.cluster[0].id

  instance_class = var.docdb.normal.instance_type

  enable_performance_insights = !startswith(var.docdb.normal.instance_type, "db.t")

  apply_immediately = true
}


# DocumentDB Subnet Group
# ========================================================
resource "aws_docdb_subnet_group" "subnet-group" {
  count = var.docdb.elastic_cluster_enable == false ? 1 : 0

  name       = "docdb-subnet-group"
  subnet_ids = var.docdb.database_subnet_ids
}


# CMK
# ========================================================
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "docdb-cmk" {
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

resource "aws_kms_alias" "docdb-cmk-alias" {
  name          = "alias/docdb-cmk"
  target_key_id = aws_kms_key.docdb-cmk.id
}


# Security Group
# ========================================================
resource "aws_security_group" "documentdb-sg" {
  name        = "documentdb-sg"
  description = "DocumentDB security group"

  vpc_id = var.docdb.vpc_id

  ingress {
    from_port   = var.docdb.port
    to_port     = var.docdb.port
    protocol    = "tcp"
    cidr_blocks = [var.docdb.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "documentdb-sg"
  }
}
