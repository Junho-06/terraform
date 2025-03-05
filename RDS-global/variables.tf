variable "region" {
  type = any
  default = {
    primary_region   = "ap-northeast-2"
    secondary_region = "us-east-1"
  }
}

variable "primary_network" {
  type = any
  default = {
    vpc_id              = ""
    vpc_cidr            = ""
    database_subnet_ids = ["", ""]
  }
}

variable "secondary_network" {
  type = any
  default = {
    vpc_id              = ""
    vpc_cidr            = ""
    database_subnet_ids = ["", ""]
  }
}

variable "rds" {
  type = any
  default = {
    engine = "aurora-mysql" # aurora-mysql / aurora-postgresql

    # mysql = 8.0, 5.7
    # postgresql = 16.4, 15.8, 14.13, 13.16, 12.20, 11.21
    engine_version = "8.0"

    global_cluster_name    = "skills-rds-global-cluster"
    primary_cluster_name   = "skills-rds-ap-cluster"
    secondary_cluster_name = "skills-rds-us-cluster"

    primary-instance_name_prefix   = "skills-rds-ap-instance"
    secondary-instance_name_prefix = "skills-rds-us-instance"

    port = "3306" # mysql = 3306 / postgresql = 5432

    initial_database_name = "test"

    engine_mode = "provisioned" # provisioned / serverless
    provisioned = {
      instance_type = "db.r7g.large"
    }
    serverless = {
      # 0 ~ 256 (step of 0.5)
      min_capacity = 0
      max_capacity = 16

      # min capacity가 0일 때만 활성화 가능함 / 0 아니면 이 옵션에서 오류남 / 옵션 비활성화가 불가능해서 minimum = 0 고정 필요
      # 300 seconds ~ 86400 seconds (24 hours)
      seconds_until_auto_pause = 43200 # 12 hours
    }

    username = "skillsadmin"
    password = "skillspassword"

    backup_retention_period = 7
    skip_final_snapshot     = true
    copy_tags_to_snapshot   = true

    enabled_mysql_logs_type    = ["error", "general", "slowquery", "audit", "iam-db-auth-error"]
    enabled_postgres_logs_type = ["postgresql", "iam-db-auth-error"]
  }
}
