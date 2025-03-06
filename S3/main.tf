# Bucket
# ========================================================
resource "aws_s3_bucket" "bucket" {
  for_each = var.buckets

  bucket        = each.value.name
  force_destroy = true

  object_lock_enabled = each.value.object_lock_enabled
}


# Bucket Ownership
# ========================================================
resource "aws_s3_bucket_ownership_controls" "ownership" {
  for_each = var.buckets

  bucket = aws_s3_bucket.bucket[each.key].id
  rule {
    object_ownership = each.value.object_ownership
  }
}


# Bucket ACL
# ========================================================
resource "aws_s3_bucket_acl" "acl" {
  for_each = {
    for k, v in var.buckets : k => v
    if v.object_ownership != "BucketOwnerEnforced"
  }
  depends_on = [aws_s3_bucket_ownership_controls.ownership]

  bucket = aws_s3_bucket.bucket[each.key].id
  acl    = each.value.acl
}


# Bucket Public Access control
# ========================================================
resource "aws_s3_bucket_public_access_block" "public_access" {
  for_each = var.buckets

  bucket = aws_s3_bucket.bucket[each.key].id

  block_public_acls       = each.value.public_access_deny
  block_public_policy     = each.value.public_access_deny
  ignore_public_acls      = each.value.public_access_deny
  restrict_public_buckets = each.value.public_access_deny
}


# Bucket Versioning
# ========================================================
resource "aws_s3_bucket_versioning" "versioning" {
  for_each = var.buckets

  bucket = aws_s3_bucket.bucket[each.key].id

  versioning_configuration {
    status = each.value.enable_bucket_versioning ? "Enabled" : "Disabled"
  }
}


# Bucket Encryption
# ========================================================
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  for_each = var.buckets

  bucket = aws_s3_bucket.bucket[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = each.value.enable_kms_encryption ? aws_kms_key.s3-cmk.id : null
      sse_algorithm     = each.value.enable_kms_encryption ? "aws:kms" : "AES256"
    }
    bucket_key_enabled = true
  }
}


# Bucket Transfer Accelerate
# ========================================================
resource "aws_s3_bucket_accelerate_configuration" "accelerate" {
  for_each = var.buckets

  bucket = aws_s3_bucket.bucket[each.key].id

  status = each.value.enable_transfer_accelerate ? "Enabled" : "Suspended"

  depends_on = [aws_s3_bucket.bucket]
}


# Bucket Lifecycle
# ========================================================
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  for_each = var.buckets

  bucket = aws_s3_bucket.bucket[each.key].id

  rule {
    id     = "default"
    status = "Enabled"
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 60
      storage_class = "ONEZONE_IA"
    }
  }
  depends_on = [aws_s3_bucket.bucket]
}


# Bucket Intelligent Tiering
# ========================================================
resource "aws_s3_bucket_intelligent_tiering_configuration" "intelligent_tiering" {
  for_each = var.buckets

  bucket = aws_s3_bucket.bucket[each.key].id

  name   = "default"
  status = "Enabled"
  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }
  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
  depends_on = [aws_s3_bucket.bucket]
}


# Bucket Logging destination bucket policy update
# ========================================================
data "aws_s3_bucket_policy" "existing_policy" {
  for_each = {
    for k, v in var.buckets : k => v
    if v.dest_bucket_has_policy == true
  }

  bucket = each.value.dest_bucket_name
}

resource "aws_s3_bucket_policy" "access_log_policy" {
  for_each = {
    for k, v in var.buckets : k => v
    if v.enable_bucket_access_log == true
  }

  bucket = each.value.dest_bucket_name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : concat(can(jsondecode(data.aws_s3_bucket_policy.existing_policy[each.key].policy)["Statement"]) ? jsondecode(data.aws_s3_bucket_policy.existing_policy[each.key].policy)["Statement"] : [],
      [
        {
          "Sid" : "S3ServerAccessLogsPolicy",
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "logging.s3.amazonaws.com"
          },
          "Action" : [
            "s3:PutObject"
          ],
          "Resource" : "arn:aws:s3:::${each.value.dest_bucket_name}/${each.value.dest_object_prefix}*",
          "Condition" : {
            "ArnLike" : {
              "aws:SourceArn" : "arn:aws:s3:::${each.value.name}"
            },
            "StringEquals" : {
              "aws:SourceAccount" : "${data.aws_caller_identity.current.account_id}"
            }
          }
        }
      ]
    )
  })
  depends_on = [aws_s3_bucket.bucket]
}


# Bucket Logging
# ========================================================
resource "aws_s3_bucket_logging" "accesslog" {
  for_each = {
    for k, v in var.buckets : k => v
    if v.enable_bucket_access_log == true
  }

  bucket        = each.value.name
  target_bucket = each.value.dest_bucket_name
  target_prefix = each.value.dest_object_prefix

  depends_on = [aws_s3_bucket_policy.access_log_policy]
}

data "aws_caller_identity" "current" {}


# CMK
# ========================================================
resource "aws_kms_key" "s3-cmk" {
  description             = "S3 CMK"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "s3-key"
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

resource "aws_kms_alias" "s3-cmk-alias" {
  name          = "alias/s3-cmk"
  target_key_id = aws_kms_key.s3-cmk.id
}
