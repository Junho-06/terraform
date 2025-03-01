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
    global_cluster_name    = "skills-rds-global-cluster"
    primary_cluster_name   = "skills-rds-ap-cluster"
    secondary_cluster_name = "skills-rds-us-cluster"

    primary-instance_name_prefix = "skills-rds-ap-instance"
    #primary-instance2_name = "skills-rds-ap-instance2"

    secondary-instance_name_prefix = "skills-rds-us-instance"
    #secondary-instance2_name = "skills-rds-us-instance2"

    engine_version = "8.0"

    port = "3306"

    initial_database_name = ""

    instance_type = "db.r7g.large"

    username = "skillsadmin"
    password = "skillspassword"

    backup_retention_period = 7
    skip_final_snapshot     = true
    copy_tags_to_snapshot   = true

    backtrack_window = 60 * 60 * 24

    enabled_logs_type = ["error", "general", "slowquery", "audit", "iam-db-auth-error"]
  }
}
