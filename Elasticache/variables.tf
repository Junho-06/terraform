variable "network" {
  type = any
  default = {
    vpc_id              = "vpc-01b2bcf6054b12580"
    vpc_cidr            = "10.0.0.0/16"
    database_subnet_ids = ["subnet-00b8dd7573087a568", "subnet-040eba3a606fc6be9"]
  }
}

variable "cache" {
  type        = any
  description = "Variables for elasticache cluster mode"
  default = {
    name = "skills-elasticache"

    engine         = "redis" # redis or valkey
    port           = 6379
    engine_version = "7.1" # redis = 7.1, 7.0, 6.2, 6.0 / valkey = 8.0, 7.2

    node_type              = "cache.t3.micro"
    nodegroup_count        = 2 # shard count
    replicas_per_nodegroup = 1 # primary 1 + replicas_per_nodegroup = node count per shard

    # required is only allow TLS, preferred is allow TLS & non-TLS
    transit_encryption_mode = "preferred" # required, preferred

    snapshot_retention_limit = 3 # unit is DAY
  }
}
