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
    vpc_id              = "vpc-0ad2361ec8f22f77b"
    vpc_cidr            = "10.0.0.0/16"
    database_subnet_ids = ["subnet-08c20dde784e83ca0", "subnet-0b015f8afc6edc03e"]
  }
}
variable "secondary_network" {
  type = any
  default = {
    vpc_id              = "vpc-028cbd1bafba17ff5"
    vpc_cidr            = "172.16.0.0/16"
    database_subnet_ids = ["subnet-09ce01eb53a8cf67b", "subnet-077dd92e1dd12a638"]
  }
}

variable "rds" {
  type = any
  default = {
    global_cluster_name    = "skills-rds-global-cluster"
    primary_cluster_name   = "skills-rds-ap-cluster"
    secondary_cluster_name = "skills-rds-us-cluster"

    primary-instance1_name   = "skills-rds-ap-instance1"
    primary-instance2_name   = "skills-rds-ap-instance2"
    secondary-instance1_name = "skills-rds-us-instance1"
    secondary-instance2_name = "skills-rds-us-instance2"

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
