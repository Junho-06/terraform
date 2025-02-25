# output "aurora_mysql_endpoint" {
#   value = var.create_aurora_mysql_cluster == true ? aws_rds_cluster.aurora-mysql-cluster[0].endpoint : null
# }
# output "aurora_mysql_reader_endpoint" {
#   value = var.create_aurora_mysql_cluster == true ? aws_rds_cluster.aurora-mysql-cluster[0].endpoint : null
# }
# output "aurora_postgres_endpoint" {
#   value = var.create_aurora_postgres_cluster == true ? aws_rds_cluster.aurora-postgres-cluster[0].endpoint : null
# }
# output "aurora_postgres_reader_endpoint" {
#   value = var.create_aurora_postgres_cluster == true ? aws_rds_cluster.aurora-postgres-cluster[0].endpoint : null
# }

output "rds" {
  value = <<EOT
    aurora_mysql_endpoint             = ${jsonencode(var.create_aurora_mysql_cluster == true ? aws_rds_cluster.aurora-mysql-cluster[0].endpoint : null)}
    aurora_mysql_reader_endpoint           = ${jsonencode(var.create_aurora_mysql_cluster == true ? aws_rds_cluster.aurora-mysql-cluster[0].reader_endpoint : null)}
    aurora_postgres_endpoint     = ${jsonencode(var.create_aurora_postgres_cluster == true ? aws_rds_cluster.aurora-postgres-cluster[0].endpoint : null)}
    aurora_postgres_reader_endpoint    = ${jsonencode(var.create_aurora_postgres_cluster == true ? aws_rds_cluster.aurora-postgres-cluster[0].reader_endpoint : null)}
  EOT
}
