# DynamoDB
# ========================================================
resource "aws_dynamodb_table" "dynamodb-table" {
  name = var.dynamodb.table_name

  table_class  = var.dynamodb.table_class
  billing_mode = var.dynamodb.billing_mode

  hash_key  = var.dynamodb.partition_key
  range_key = try(var.dynamodb.sort_key, null)

  read_capacity  = var.dynamodb.billing_mode == "PROVISIONED" ? var.dynamodb.capacity_autoscaling_enable == false ? var.dynamodb.disable_auto_scaling.read_capacity : 1 : null
  write_capacity = var.dynamodb.billing_mode == "PROVISIONED" ? var.dynamodb.capacity_autoscaling_enable == false ? var.dynamodb.disable_auto_scaling.write_capacity : 1 : null

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

  tags = {
    "Name" = var.dynamodb.table_name
  }
}


# Capacity Auto Scaling
# ========================================================
resource "aws_appautoscaling_target" "dynamodb_table_read_target" {
  count = var.dynamodb.billing_mode == "PROVISIONED" && var.dynamodb.capacity_autoscaling_enable == true ? 1 : 0

  max_capacity       = var.dynamodb.enable_auto_scaling.read_capacity_max
  min_capacity       = var.dynamodb.enable_auto_scaling.read_capacity_min
  resource_id        = "table/${var.dynamodb.table_name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"

  depends_on = [aws_dynamodb_table.dynamodb-table]
}

resource "aws_appautoscaling_policy" "dynamodb_table_read_policy" {
  count = var.dynamodb.billing_mode == "PROVISIONED" && var.dynamodb.capacity_autoscaling_enable == true ? 1 : 0

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
  count = var.dynamodb.billing_mode == "PROVISIONED" && var.dynamodb.capacity_autoscaling_enable == true ? 1 : 0

  max_capacity       = var.dynamodb.enable_auto_scaling.write_capacity_max
  min_capacity       = var.dynamodb.enable_auto_scaling.write_capacity_min
  resource_id        = "table/${var.dynamodb.table_name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"

  depends_on = [aws_dynamodb_table.dynamodb-table]
}

resource "aws_appautoscaling_policy" "dynamodb_table_write_policy" {
  count = var.dynamodb.billing_mode == "PROVISIONED" && var.dynamodb.capacity_autoscaling_enable == true ? 1 : 0

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
      aws dynamodb create-backup --table-name ${var.dynamodb.table_name} --backup-name ${var.dynamodb.table_name}
    EOT
    when    = create
  }
  depends_on = [aws_dynamodb_table.dynamodb-table]
}


# CMK
# ========================================================
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
