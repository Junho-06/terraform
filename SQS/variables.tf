variable "sqs" {
  type = any
  default = {
    region = "ap-northeast-2"

    name = "skills-sqs"

    FIFO_enable = true
    # only use when FIFO is enable
    content_based_deduplication_enable = true


    # 60 seconds ~ 86400 seconds (24 hours) / default is 300 seconds (5 minutes)
    kms_data_key_reuse_period_seconds = 300

    # 1024 bytes (1 KiB) ~ 262144 bytes (256 KiB) / default is 262144 bytes (256 KiB)
    max_message_size = 262144

    # 60 seconds ~ 1209600 seconds (14 days) / default is 345600 seconds (4 days)
    message_retention_seconds = 345600

    # 0 seconds ~ 20 seconds / default is 0 seconds
    receive_wait_time_seconds = 0

    # 0 seconds ~ 43200 seconds (12 hours) / default is 30 seconds
    visibility_timeout_seconds = 30
  }
}
