output "dynamodb" {
  value = {
    Primary_Table_ARN   = aws_dynamodb_table.dynamodb-table.arn
    Secondary_Table_ARN = aws_dynamodb_table_replica.secondary_table.arn

    Partition_Key = var.dynamodb.partition_key
    Sort_Key      = try(var.dynamodb.sort_key, null)

    Keys = var.dynamodb.keys[*].name

    Table_Mode = var.dynamodb.billing_mode

    PITR = var.dynamodb.PITR_enable

    Primary_CMK_ID    = aws_kms_key.dynamodb-cmk.id
    Primary_CMK_ARN   = aws_kms_key.dynamodb-cmk.arn
    Secondary_CMK_ID  = aws_kms_replica_key.dynamodb-replica-cmk.key_id
    Secondary_CMK_ARN = aws_kms_replica_key.dynamodb-replica-cmk.arn
  }
}
