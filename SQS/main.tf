# SQS Queue
# ========================================================
resource "aws_sqs_queue" "queue" {
  name       = var.sqs.FIFO_enable == true ? "${var.sqs.name}.fifo" : var.sqs.name
  fifo_queue = var.sqs.FIFO_enable

  content_based_deduplication = var.sqs.FIFO_enable == true ? var.sqs.content_based_deduplication_enable : null
  deduplication_scope         = var.sqs.FIFO_enable == true ? "messageGroup" : null
  fifo_throughput_limit       = var.sqs.FIFO_enable == true ? "perMessageGroupId" : null

  kms_master_key_id = aws_kms_key.sqs-cmk.id

  kms_data_key_reuse_period_seconds = var.sqs.kms_data_key_reuse_period_seconds
  max_message_size                  = var.sqs.max_message_size
  message_retention_seconds         = var.sqs.message_retention_seconds
  receive_wait_time_seconds         = var.sqs.receive_wait_time_seconds
  visibility_timeout_seconds        = var.sqs.visibility_timeout_seconds

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "SQS_default_policy",
    "Statement" : [
      {
        "Sid" : "owner_allow_statement",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "${data.aws_caller_identity.current.account_id}"
        },
        "Action" : [
          "SQS:*"
        ],
        "Resource" : "arn:aws:sqs:${var.sqs.region}:${data.aws_caller_identity.current.account_id}:${var.sqs.FIFO_enable == true ? "${var.sqs.name}.fifo" : var.sqs.name}"
      }
    ]
  })
}


# CMK
# ========================================================
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "sqs-cmk" {
  description             = "SQS CMK"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "sqs-key"
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

resource "aws_kms_alias" "sqs-cmk-alias" {
  name          = "alias/sqs-cmk"
  target_key_id = aws_kms_key.sqs-cmk.id
}
