variable "region" {
  type    = any
  default = "ap-northeast-2"
}

variable "rds" {
  type = any
  default = {
    vpc_id              = ""
    vpc_cidr            = ""
    database_subnet_ids = ["", ""]

    name = "skills-rds"

    engine         = "mysql"
    engine_version = "8.0"

    port = "3307"

    instance_class = "db.t3.medium"

    username                    = "skillsadmin"
    manage_master_user_password = true
    password                    = "skillspassword"

    # gp2, gp3, io1, io2
    storage_type = "gp3"
    # gp = 20 GiB ~ 6144 GiB / io = 100 ~ 6144
    allocated_storage = 20
    # gp3 = 12000 ~ 64000 / io = 1000 ~ 80000
    iops = 1000

    initial_database_name = "dev"

    backup_retention_period               = 7
    monitoring_interval                   = 30
    performance_insights_retention_period = 7

    enabled_log_types = ["error", "general", "slowquery", "audit"] # "iam-db-auth-error"
  }
}
