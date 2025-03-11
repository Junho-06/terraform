output "rds" {
  value = {
    Aurora_MySQL = {
      Writer_Endpoint = var.db_engine.create_aurora_mysql_cluster == true ? aws_rds_cluster.aurora-mysql-cluster[0].endpoint : null
      Reader_Endpoint = var.db_engine.create_aurora_mysql_cluster == true ? aws_rds_cluster.aurora-mysql-cluster[0].reader_endpoint : null

      Username = var.db_engine.create_aurora_mysql_cluster == true ? var.aurora-mysql.master_username : null
      Passwrod = var.db_engine.create_aurora_mysql_cluster == true && var.aurora-mysql.manage_master_user_password == true ? nonsensitive(jsondecode(data.aws_secretsmanager_secret_version.mysql_secrets_current[0].secret_string)["password"]) : try(var.aurora-mysql.master_password, null)

      Port = var.db_engine.create_aurora_mysql_cluster == true ? aws_rds_cluster.aurora-mysql-cluster[0].port : null
    }

    Aurora_PostgreSQL = {
      Writer_Endpoint = var.db_engine.create_aurora_postgres_cluster == true ? aws_rds_cluster.aurora-postgres-cluster[0].endpoint : null
      Reader_Endpoint = var.db_engine.create_aurora_postgres_cluster == true ? aws_rds_cluster.aurora-postgres-cluster[0].reader_endpoint : null

      Username = var.db_engine.create_aurora_postgres_cluster == true ? var.aurora-postgres.master_username : null
      Passwrod = var.db_engine.create_aurora_postgres_cluster == true && var.aurora-postgres.manage_master_user_password == true ? nonsensitive(jsondecode(data.aws_secretsmanager_secret_version.postgres_secrets_current[0].secret_string)["password"]) : try(var.aurora-postgres.master_password, null)

      Port = var.db_engine.create_aurora_postgres_cluster == true ? aws_rds_cluster.aurora-postgres-cluster[0].port : null
    }
  }
}
