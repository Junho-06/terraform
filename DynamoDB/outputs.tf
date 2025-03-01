output "dynamodb" {
  value = {
    Partition_Key = var.dynamodb.partition_key
    Sort_Key      = try(var.dynamodb.sort_key, null)

    Keys = var.dynamodb.keys[*].name

    Table_Mode = var.dynamodb.billing_mode

    PITR = var.dynamodb.PITR_enable

    CMK_ID  = aws_kms_key.dynamodb-cmk.id
    CMK_ARN = aws_kms_key.dynamodb-cmk.arn
  }
}
