output "elasticache" {
  value = {
    primary = {
      Configuration_Endpoint = try(aws_elasticache_replication_group.primary-elasticache.configuration_endpoint_address, null)
      Primary_Endpoint       = try(aws_elasticache_replication_group.primary-elasticache.primary_endpoint_address, null)
      Reader_Endpoint        = try(aws_elasticache_replication_group.primary-elasticache.reader_endpoint_address, null)
      Port                   = try(var.cache.primary.port, null)
    }

    secondary = {
      Configuration_Endpoint = try(aws_elasticache_replication_group.secondary-elasticache.configuration_endpoint_address, null)
      Primary_Endpoint       = try(aws_elasticache_replication_group.secondary-elasticache.primary_endpoint_address, null)
      Reader_Endpoint        = try(aws_elasticache_replication_group.secondary-elasticache.reader_endpoint_address, null)
      Port                   = try(var.cache.secondary.port, null)
    }
  }
}
