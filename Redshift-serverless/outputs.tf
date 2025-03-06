output "redshift" {
  value = {
    Endpoint = aws_redshiftserverless_workgroup.workgroup.endpoint[0].address
    Port     = aws_redshiftserverless_workgroup.workgroup.endpoint[0].port
    Username = var.redshift.username
    Password = nonsensitive(jsondecode(data.aws_secretsmanager_secret_version.redshift_secrets_current.secret_string)["password"])
  }
}
