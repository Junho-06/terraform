output "rds" {
  value = {
    Writer_Endpoint = aws_db_instance.rds-instance.address

    Username = aws_db_instance.rds-instance.username
    Passwrod = var.rds.manage_master_user_password == true ? nonsensitive(jsondecode(data.aws_secretsmanager_secret_version.mysql_secrets_current[0].secret_string)["password"]) : try(var.rds.password, null)

    Port = aws_db_instance.rds-instance.port
  }
}
