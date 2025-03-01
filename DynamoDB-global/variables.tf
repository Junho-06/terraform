variable "dynamodb" {
  type        = any
  description = "DynamoDB Variables"
  default = {
    region = {
      primary_region   = "ap-northeast-2"
      secondary_region = "us-east-1"
    }

    table_name = "skills-dynamodb"

    table_class  = "STANDARD"        # STANDARD / STANDARD_INFREQUENT_ACCESS
    billing_mode = "PAY_PER_REQUEST" # PAY_PER_REQUEST / PROVISIONED(AutoScaling)

    # 아래 옵션들은 PROVISIONED 모드일 때만 설정하면 됨
    enable_auto_scaling = {
      read_capacity_min                 = 1
      read_capacity_max                 = 10
      read_capacity_utilization_percent = 70

      write_capacity_min                 = 1
      write_capacity_max                 = 10
      write_capacity_utilization_percent = 70
    }

    PITR_enable = true

    partition_key = "id"
    sort_key      = null

    keys = [
      {
        name = "id"
        type = "S" # S(string), N(number), B(binary)
      },
      # {
      #   name = "category"
      #   type = "S"
      # },
    ]
  }
}
