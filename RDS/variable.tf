variable "create_aurora_mysql_cluster" { default = true }
variable "create_aurora_postgres_cluster" { default = true }

variable "vpc_id" { default = "vpc-0ad2361ec8f22f77b" }
variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "database_subnet_ids" { default = ["subnet-08c20dde784e83ca0", "subnet-0b015f8afc6edc03e"] }

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
    copy_tags_to_snapshot   = false

    backtrack_window = 60 * 60 * 24

    enabled_logs_type = ["error", "general", "slowquery", "audit", "iam-db-auth-error"]

    performance_insights_enabled = true
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
    copy_tags_to_snapshot   = false

    enabled_logs_type = ["postgresql", "iam-db-auth-error"]

    performance_insights_enabled = true
  }
}
