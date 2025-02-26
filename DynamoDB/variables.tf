variable "dynamodb" {
  type        = any
  description = "DynamoDB Variables"
  default = {
    table_name   = "skills-dynamodb"
    billing_mode = "PAY_PER_REQUEST" # PROVISIONED

    # if you want capacity auto scaling? -> create on console
    read_capacity  = 10 # only use billing_mode is PROVISIONED
    write_capacity = 10 # only use billing_mode is PROVISIONED

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
