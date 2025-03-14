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

variable "cache" {
  type        = any
  description = "Variables for elasticache"
  default = {
    # !! redis는 지원되는 node type이 제한되어 있음 (r7g, m7g, r6g, r6gd, m6g, r5, m5) !!
    # valkey도 제한되어 있음 (r7g, m7g, r6g, m6g, t4g, r5, m5, r4, m4, t3, t2)

    global = {
      name_suffix = "skills"

      engine_version = "7.1" # redis = 7.1, 7.0, 6.2, 6.0 ... / valkey = 8.0, 7.2
    }

    primary = {
      name = "skills-elasticache-primary"

      engine         = "redis" # redis or valkey
      engine_version = "7.1"   # redis = 7.1, 7.0, 6.2, 6.0 ... / valkey = 8.0, 7.2
      port           = 6379

      node_type              = "cache.r7g.large"
      nodegroup_count        = 2 # shard count
      replicas_per_nodegroup = 1 # primary 1 + replicas_per_nodegroup = node count per shard

      snapshot_retention_limit = 3 # unit is DAY
    }

    secondary = {
      name = "skills-elasticache-secondary"

      port = 6379

      replicas_per_node_group = 1

      snapshot_retention_limit = 3 # unit is DAY
    }
  }
}
