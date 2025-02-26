output "elasticache" {
  value = <<EOT
    configuration_endpoint = ${jsonencode(try(aws_elasticache_replication_group.elasticache.configuration_endpoint_address, null))}
    primary_endpoint = ${jsonencode(try(aws_elasticache_replication_group.elasticache.primary_endpoint_address, null))}
    reader_endpoint = ${jsonencode(try(aws_elasticache_replication_group.elasticache.reader_endpoint_address, null))}
  EOT
}
