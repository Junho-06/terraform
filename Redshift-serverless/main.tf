# Redshift Serverless Namespace
# ========================================================
resource "aws_redshiftserverless_namespace" "namespace" {
  namespace_name = var.redshift.namespace_name

  kms_key_id = aws_kms_key.redshift-cmk.arn

  iam_roles            = [aws_iam_role.redshift-role.arn]
  default_iam_role_arn = aws_iam_role.redshift-role.arn

  db_name = var.redshift.initial_database_name

  admin_username                   = var.redshift.username
  manage_admin_password            = true
  admin_password_secret_kms_key_id = aws_kms_key.redshift-cmk.id

  log_exports = var.redshift.export_log_types
}


# Redshift Serverless Namespace
# ========================================================
resource "aws_redshiftserverless_workgroup" "workgroup" {
  namespace_name = aws_redshiftserverless_namespace.namespace.id
  workgroup_name = var.redshift.workgroup_name

  base_capacity = var.redshift.base_capacity
  max_capacity  = var.redshift.max_capacity

  port = var.redshift.port

  publicly_accessible = false

  security_group_ids = [aws_security_group.redshift-sg.id]
  subnet_ids         = var.redshift.database_subnet_ids

  enhanced_vpc_routing = true
}


# Redshift Default IAM Role
# ========================================================
resource "aws_iam_role" "redshift-role" {
  name = "${var.redshift.namespace_name}-AmazonRedshift-Default-IAM-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow"
        "Principal" : {
          "Service" : [
            "sagemaker.amazonaws.com",
            "redshift.amazonaws.com",
            "redshift-serverless.amazonaws.com"
          ]
        }
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "redshift-s3-policy" {
  name        = "${var.redshift.namespace_name}-AmazonRedshift-to-Any-S3-Policy"
  description = "AmazonRedshift to Any S3 Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Action" : [
          "s3:GetObject",
          "s3:GetBucketAcl",
          "s3:GetBucketCors",
          "s3:GetEncryptionConfiguration",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListAllMyBuckets",
          "s3:ListMultipartUploadParts",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject",
          "s3:PutBucketAcl",
          "s3:PutBucketCors",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:CreateBucket"
        ]
        "Effect" : "Allow"
        "Resource" : "arn:aws:s3:::*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "redhsift-s3-policy-attach" {
  role       = aws_iam_role.redshift-role.name
  policy_arn = aws_iam_policy.redshift-s3-policy.arn
}

resource "aws_iam_role_policy_attachment" "redhsift-default-policy-attach" {
  role       = aws_iam_role.redshift-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRedshiftAllCommandsFullAccess"
}

resource "aws_iam_role_policy_attachments_exclusive" "redshift-policy-exclusive" {
  role_name = aws_iam_role.redshift-role.name
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonRedshiftAllCommandsFullAccess",
    aws_iam_policy.redshift-s3-policy.arn
  ]
}


# Redshift Security Group
# ========================================================
resource "aws_security_group" "redshift-sg" {
  name        = "redshift-sg"
  description = "Redshift security group"

  vpc_id = var.redshift.vpc_id

  ingress {
    from_port   = var.redshift.port
    to_port     = var.redshift.port
    protocol    = "tcp"
    cidr_blocks = [var.redshift.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "redshift-sg"
  }
}


# CMK
# ========================================================
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "redshift-cmk" {
  description             = "Redshift CMK"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "redshift-key"
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

resource "aws_kms_alias" "redshift-cmk-alias" {
  name          = "alias/redshift-cmk"
  target_key_id = aws_kms_key.redshift-cmk.id
}


# Secret Output
# ========================================================
data "aws_secretsmanager_secret" "redshift_secrets" {
  arn = aws_redshiftserverless_namespace.namespace.admin_password_secret_arn
}

data "aws_secretsmanager_secret_version" "redshift_secrets_current" {
  secret_id = data.aws_secretsmanager_secret.redshift_secrets.id
}
