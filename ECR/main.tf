resource "aws_ecr_repository" "repository" {
  for_each = var.repositories

  name         = each.key
  force_delete = true

  dynamic "encryption_configuration" {
    for_each = try(each.value.encrypted, true) ? [1] : []
    content {
      encryption_type = "KMS"
      kms_key         = aws_kms_key.ecr-cmk.arn
    }
  }

  image_tag_mutability = try(each.value.immutable, true) ? "IMMUTABLE" : "MUTABLE"
}
resource "aws_ecr_registry_scanning_configuration" "basic-scan-configuration" {
  count     = var.repositories_scan_enhanced ? 0 : 1
  scan_type = "BASIC"

  rule {
    scan_frequency = "SCAN_ON_PUSH"
    repository_filter {
      filter      = "*"
      filter_type = "WILDCARD"
    }
  }
}
resource "aws_ecr_registry_scanning_configuration" "enhanced-scan-configuration" {
  count     = var.repositories_scan_enhanced ? 1 : 0
  scan_type = "ENHANCED"

  rule {
    scan_frequency = "CONTINUOUS_SCAN"
    repository_filter {
      filter      = "*"
      filter_type = "WILDCARD"
    }
  }
}
data "aws_caller_identity" "current" {}
resource "aws_kms_key" "ecr-cmk" {
  description             = "ECR CMK"
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
resource "aws_kms_alias" "ecr-cmk-alias" {
  name          = "alias/ecr-cmk"
  target_key_id = aws_kms_key.ecr-cmk.id
}
