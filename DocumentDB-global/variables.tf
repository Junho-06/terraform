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
      vpc_id              = "vpc-098f45c83adc26a24"
      vpc_cidr            = "10.0.0.0/16"
      database_subnet_ids = ["subnet-084940f14158bb19e", "subnet-0cf33dca7e45444e4"]
    }

    secondary_network = {
      vpc_id              = "vpc-05ab944f167da7a01"
      vpc_cidr            = "172.16.0.0/16"
      database_subnet_ids = ["subnet-06eab3ba73130b8f6", "subnet-0ca656e6fe4ee71b6"]
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
