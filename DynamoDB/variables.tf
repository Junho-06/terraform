variable "dynamodb" {
  type        = any
  description = "DynamoDB Variables"
  default = {
    table_name = "skills-dynamodb"

    table_class  = "STANDARD"        # STANDARD / STANDARD_INFREQUENT_ACCESS
    billing_mode = "PAY_PER_REQUEST" # PAY_PER_REQUEST / PROVISIONED

    # 아래 capacity_autoscaling_enable은 PROVISIONED 모드일 때만 true/false를 선택하면 됨
    capacity_autoscaling_enable = true
    enable_auto_scaling = {
      read_capacity_min                 = 1
      read_capacity_max                 = 10
      read_capacity_utilization_percent = 70

      write_capacity_min                 = 1
      write_capacity_max                 = 10
      write_capacity_utilization_percent = 70
    }
    disable_auto_scaling = {
      read_capacity  = 10
      write_capacity = 10
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
