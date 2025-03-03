output "elasticache" {
  value = {
    cluster = {
      Configuration_Endpoint = try(aws_elasticache_replication_group.elasticache[0].configuration_endpoint_address, null)
      Primary_Endpoint       = try(aws_elasticache_replication_group.elasticache[0].primary_endpoint_address, null)
      Reader_Endpoint        = try(aws_elasticache_replication_group.elasticache[0].reader_endpoint_address, null)
      Port                   = var.cache.serverless_enable == true ? null : var.cache.cluster.port
    }

    serverless = {
      Primary_Endpoint      = try(aws_elasticache_serverless_cache.serverless_elasticache[0].endpoint[0].address, null)
      Primary_Endpoint_Port = try(aws_elasticache_serverless_cache.serverless_elasticache[0].endpoint[0].port, null)
      Reader_Endpoint       = try(aws_elasticache_serverless_cache.serverless_elasticache[0].reader_endpoint[0].address, null)
      Reader_Endpoint_Port  = try(aws_elasticache_serverless_cache.serverless_elasticache[0].reader_endpoint[0].port, null)
    }
  }
}
