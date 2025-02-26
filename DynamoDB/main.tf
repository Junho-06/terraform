resource "aws_dynamodb_table" "dynamodb-table" {
  name         = var.dynamodb.table_name
  billing_mode = var.dynamodb.billing_mode

  hash_key  = var.dynamodb.partition_key
  range_key = try(var.dynamodb.sort_key, null)

  read_capacity  = var.dynamodb.billing_mode == "PROVISIONED" ? try(var.dynamodb.read_capacity, null) : null
  write_capacity = var.dynamodb.billing_mode == "PROVISIONED" ? try(var.dynamodb.write_capacity, null) : null

  dynamic "attribute" {
    for_each = var.dynamodb.keys

    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb-cmk.arn
  }

  tags = {
    "Name" = var.dynamodb.table_name
  }
}
data "aws_caller_identity" "current" {}
resource "aws_kms_key" "dynamodb-cmk" {
  description             = "DyanmoDB CMK"
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
resource "aws_kms_alias" "dynamodb-cmk-alias" {
  name          = "alias/dynamodb-cmk"
  target_key_id = aws_kms_key.dynamodb-cmk.id
}
resource "null_resource" "trigger_backup" {
  provisioner "local-exec" {
    command = <<EOT
      aws dynamodb create-backup --table-name ${var.dynamodb.table_name} --backup-name ${var.dynamodb.table_name}
    EOT
  }
  depends_on = [aws_dynamodb_table.dynamodb-table]
}
