variable "db_engine" {
  type = any
  default = {
    create_aurora_mysql_cluster    = true
    create_aurora_postgres_cluster = true
  }
}

variable "region" {
  default = "ap-northeast-2"
}

variable "network" {
  type = any
  default = {
    vpc_id              = ""
    vpc_cidr            = ""
    database_subnet_ids = ["", ""]
  }
}

variable "aurora-mysql" {
  type        = any
  description = "Value for Aurora MYSQL"

  default = {
    cluster_name = "skills-aurora-mysql-cluster"
    # Instance는 subnet 갯수만큼 생김
    instance_name_prefix = "skills-aurora-mysql-cluster-instance"

    engine_version = "8.0"

    engine_mode = "provisioned" # provisioned / serverless
    provisioned = {
      instance_type = "db.t3.medium"
    }
    serverless = {
      # 0 ~ 256 (step of 0.5)
      min_capacity = 0
      max_capacity = 16

      # min capacity가 0일 때만 활성화 가능함 / 0 아니면 이 옵션에서 오류남 / 옵션 비활성화가 불가능해서 minimum = 0 고정 필요
      # 300 seconds ~ 86400 seconds (24 hours)
      seconds_until_auto_pause = 43200 # 12 hours
    }

    port = "3306"

    initial_database_name = ""

    master_username = "skillsadmin"

    backup_retention_period = 7
    skip_final_snapshot     = true
    copy_tags_to_snapshot   = true

    backtrack_window = 60 * 60 * 24

    enabled_logs_type = ["error", "general", "slowquery", "audit", "iam-db-auth-error"]
  }
}

variable "aurora-postgres" {
  type        = any
  description = "Value for Aurora Postgres"

  default = {
    cluster_name         = "skills-aurora-postgres-cluster"
    instance_name_prefix = "skills-aurora-postgres-cluster-instance"

    engine_version = "16"

    engine_mode = "provisioned" # provisioned / serverless
    provisioned = {
      instance_type = "db.t3.medium"
    }
    serverless = {
      # 0 ~ 256 (step of 0.5)
      min_capacity = 0
      max_capacity = 16

      # min capacity가 0일 때만 활성화 가능함 / 0 아니면 이 옵션에서 오류남 / 옵션 비활성화가 불가능해서 minimum = 0 고정 필요
      # 300 seconds ~ 86400 seconds (24 hours)
      seconds_until_auto_pause = 43200 # 12 hours
    }

    port = "5432"

    initial_database_name = ""

    master_username = "skillsadmin"

    backup_retention_period = 7
    skip_final_snapshot     = true
    copy_tags_to_snapshot   = true

    enabled_logs_type = ["postgresql", "iam-db-auth-error"]
  }
}
