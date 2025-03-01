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
    cluster_name   = "skills-aurora-mysql-cluster"
    instance1_name = "skills-aurora-mysql-cluster-instance-1"
    instance2_name = "skills-aurora-mysql-cluster-instance-2"

    engine_version = "8.0"

    port = "3306"

    instance_type = "db.t3.medium"

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
    cluster_name   = "skills-aurora-postgres-cluster"
    instance1_name = "skills-aurora-postgres-cluster-instance-1"
    instance2_name = "skills-aurora-postgres-cluster-instance-2"

    engine_version = "16"

    port = "5432"

    instance_type = "db.t3.medium"

    initial_database_name = ""

    master_username = "skillsadmin"

    backup_retention_period = 7
    skip_final_snapshot     = true
    copy_tags_to_snapshot   = true

    enabled_logs_type = ["postgresql", "iam-db-auth-error"]
  }
}
