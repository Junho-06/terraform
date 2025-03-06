variable "docdb" {
  type        = any
  description = "Value for DocumentDB"
  default = {
    region = "ap-northeast-2"

    vpc_id              = ""
    vpc_cidr            = ""
    database_subnet_ids = ["", ""]

    port = 27017

    elastic_cluster_enable = false
    elastic = {
      name = "skills-elastic-docdb"

      # 2, 4, 8, 16, 32, 64
      shard_capacity = 2
      # maximum is 32
      shard_count = 2

      username = "skillsadmin"
      password = "skillspassword12"
    }
    normal = {
      name = "skills-docdb"

      instance_name_prefix = "skills-docdb-instance"

      engine_version = "5.0.0" # 5.0.0, 4.0.0, 3.6.0

      # https://docs.aws.amazon.com/ko_kr/documentdb/latest/developerguide/db-instance-classes.html#db-instance-class-specs
      instance_type = "db.t3.medium"

      username = "skillsadmin"
      password = "skillspassword12"

      export_log_types = ["audit", "profiler"] # "audit", "profiler"
    }
  }
}
