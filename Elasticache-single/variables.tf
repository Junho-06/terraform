variable "network" {
  type = any
  default = {
    vpc_id              = ""
    vpc_cidr            = ""
    database_subnet_ids = ["", ""]
  }
}

variable "region" {
  type    = any
  default = "ap-northeast-2"
}

variable "cache" {
  type        = any
  description = "Variables for elasticache"
  default = {
    # serverless_enable이 true 일 땐 cluster 부분 변수 수정, false 일 땐 serverless 부분 변수 수정
    serverless_enable = false

    cluster = {
      name = "skills-elasticache"

      engine         = "redis" # redis or valkey
      engine_version = "7.1"   # redis = 7.1, 7.0, 6.2, 6.0 ... / valkey = 8.0, 7.2
      port           = 6379

      node_type              = "cache.t3.micro"
      nodegroup_count        = 2 # shard count
      replicas_per_nodegroup = 1 # primary 1 + replicas_per_nodegroup = node count per shard

      # "required" is only allow TLS, "preferred" is allow TLS & non-TLS
      transit_encryption_mode = "preferred" # required, preferred

      snapshot_retention_limit = 3 # unit is DAY
    }

    serverless = {
      name = "skills-serverless-elasticache"

      engine         = "redis" # memcached, valkey, redis
      engine_version = "7"     # redis 7, 6 / valkey = 8, 7 / memcached = 1.6

      # Unit is GB
      # 1 ~ 5000
      data_storage_minimum = 1
      data_storage_maximum = 100

      # 1000 ~ 15000000
      ecpu_per_second_minimum = 1000
      ecpu_per_second_maximum = 10000

      # daily_snapshot_time 은 "HH:MM" 형식으로 1의 자리 숫자여도 앞에 '0' 이 붙어야함
      daily_snapshot_time      = "08:00"
      snapshot_retention_limit = 3
    }
  }
}
