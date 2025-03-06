variable "region" {
  type = any
  default = {
    primary_region   = "ap-northeast-2"
    secondary_region = "us-east-1"
  }
}

variable "network" {
  type = any
  default = {
    primary_network = {
      vpc_id              = ""
      vpc_cidr            = ""
      database_subnet_ids = ["", ""]
    }

    secondary_network = {
      vpc_id              = ""
      vpc_cidr            = ""
      database_subnet_ids = ["", ""]
    }
  }
}

variable "docdb" {
  type        = any
  description = "Value for DocumentDB"
  default = {
    global = {
      name = "skills-docdb-global"

      port = 27017

      engine_version = "5.0.0" # 5.0.0, 4.0.0, 3.6.0

      initial_database_name = ""

      username = "skillsadmin"
      password = "skillspassword12"
    }

    primary = {
      name = "skills-docdb-primary"

      instance_name_prefix = "skills-docdb-primary-instance"

      # https://docs.aws.amazon.com/ko_kr/documentdb/latest/developerguide/db-instance-classes.html#db-instance-class-specs
      # Global Cluster는 t3, t4g, r4는 지원하지 않음
      instance_type = "db.r6g.large"

      export_log_types = ["audit", "profiler"] # "audit", "profiler"
    }

    secondary = {
      name = "skills-docdb-secondary"

      instance_name_prefix = "skills-docdb-secondary-instance"

      # https://docs.aws.amazon.com/ko_kr/documentdb/latest/developerguide/db-instance-classes.html#db-instance-class-specs
      # Global Cluster는 t3, t4g, r4는 지원하지 않음
      instance_type = "db.r6g.large"

      export_log_types = ["audit", "profiler"] # "audit", "profiler"
    }
  }
}
