output "rds-global" {
  value = {
    Global_Writer_Endpoint = aws_rds_global_cluster.rds_global_cluster.endpoint
    Username               = var.rds.username
    Password               = var.rds.password
    Port                   = var.rds.port
  }
}
