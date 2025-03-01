# DynamoDB
# ========================================================
resource "aws_dynamodb_table" "dynamodb-table" {
  provider = aws.primary

  name = var.dynamodb.table_name

  table_class  = var.dynamodb.table_class
  billing_mode = var.dynamodb.billing_mode

  hash_key  = var.dynamodb.partition_key
  range_key = try(var.dynamodb.sort_key, null)

  read_capacity  = var.dynamodb.billing_mode == "PROVISIONED" ? 1 : null
  write_capacity = var.dynamodb.billing_mode == "PROVISIONED" ? 1 : null

  dynamic "attribute" {
    for_each = var.dynamodb.keys

    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  point_in_time_recovery {
    enabled = var.dynamodb.PITR_enable
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb-cmk.arn
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  tags = {
    "Name" = var.dynamodb.table_name
  }
}

resource "aws_dynamodb_table_replica" "secondary_table" {
  provider = aws.secondary

  global_table_arn = aws_dynamodb_table.dynamodb-table.arn

  kms_key_arn            = aws_kms_replica_key.dynamodb-replica-cmk.arn
  point_in_time_recovery = var.dynamodb.PITR_enable

  depends_on = [
    aws_dynamodb_table.dynamodb-table,
    aws_appautoscaling_policy.dynamodb_table_read_policy[0],
    aws_appautoscaling_policy.dynamodb_table_write_policy[0],
    aws_appautoscaling_target.dynamodb_table_read_target[0],
    aws_appautoscaling_target.dynamodb_table_write_target[0]
  ]
}


# Capacity Auto Scaling
# ========================================================
resource "aws_appautoscaling_target" "dynamodb_table_read_target" {
  provider = aws.primary
  count    = var.dynamodb.billing_mode == "PROVISIONED" ? 1 : 0

  max_capacity       = var.dynamodb.enable_auto_scaling.read_capacity_max
  min_capacity       = var.dynamodb.enable_auto_scaling.read_capacity_min
  resource_id        = "table/${var.dynamodb.table_name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"

  depends_on = [aws_dynamodb_table.dynamodb-table]
}

resource "aws_appautoscaling_policy" "dynamodb_table_read_policy" {
  provider = aws.primary
  count    = var.dynamodb.billing_mode == "PROVISIONED" ? 1 : 0

  name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.dynamodb_table_read_target[0].resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_table_read_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_table_read_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_table_read_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    target_value = var.dynamodb.enable_auto_scaling.read_capacity_utilization_percent
  }

  depends_on = [aws_dynamodb_table.dynamodb-table]
}

resource "aws_appautoscaling_target" "dynamodb_table_write_target" {
  provider = aws.primary
  count    = var.dynamodb.billing_mode == "PROVISIONED" ? 1 : 0

  max_capacity       = var.dynamodb.enable_auto_scaling.write_capacity_max
  min_capacity       = var.dynamodb.enable_auto_scaling.write_capacity_min
  resource_id        = "table/${var.dynamodb.table_name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"

  depends_on = [aws_dynamodb_table.dynamodb-table]
}

resource "aws_appautoscaling_policy" "dynamodb_table_write_policy" {
  provider = aws.primary
  count    = var.dynamodb.billing_mode == "PROVISIONED" ? 1 : 0

  name               = "DynamoDBWriteCapacityUtilization:${aws_appautoscaling_target.dynamodb_table_write_target[0].resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_table_write_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_table_write_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_table_write_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    target_value = var.dynamodb.enable_auto_scaling.write_capacity_utilization_percent
  }

  depends_on = [aws_dynamodb_table.dynamodb-table]
}


# Create DynamoDB Backup
# ========================================================
resource "null_resource" "trigger_backup" {
  provisioner "local-exec" {
    command = <<EOT
      aws dynamodb create-backup --region ${var.dynamodb.region.primary_region} --table-name ${var.dynamodb.table_name} --backup-name ${var.dynamodb.table_name}
    EOT
    when    = create
  }
  depends_on = [aws_dynamodb_table.dynamodb-table]
}

resource "null_resource" "trigger_backup-secondary" {
  provisioner "local-exec" {
    command = <<EOT
      aws dynamodb create-backup --region ${var.dynamodb.region.secondary_region} --table-name ${var.dynamodb.table_name} --backup-name ${var.dynamodb.table_name}
    EOT
    when    = create
  }
  depends_on = [aws_dynamodb_table_replica.secondary_table]
}


# CMK
# ========================================================
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "dynamodb-cmk" {
  provider = aws.primary

  description             = "DyanmoDB CMK"
  multi_region            = true
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

resource "aws_kms_alias" "dynamodb-cmk-alias" {
  provider = aws.primary

  name          = "alias/dynamodb-cmk"
  target_key_id = aws_kms_key.dynamodb-cmk.id
}

resource "aws_kms_replica_key" "dynamodb-replica-cmk" {
  provider = aws.secondary

  deletion_window_in_days = 7
  primary_key_arn         = aws_kms_key.dynamodb-cmk.arn
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

resource "aws_kms_alias" "dynamodb-replica-cmk-alias" {
  provider = aws.secondary

  name          = "alias/dynamodb-cmk"
  target_key_id = aws_kms_replica_key.dynamodb-replica-cmk.id
}
