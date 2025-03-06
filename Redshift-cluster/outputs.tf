output "redshift" {
  value = {
    Endpoint = aws_redshift_cluster.cluster.endpoint
    Port     = aws_redshift_cluster.cluster.port
    DNS_name = aws_redshift_cluster.cluster.dns_name
    Username = var.redshift.username
    Password = nonsensitive(jsondecode(data.aws_secretsmanager_secret_version.redshift_secrets_current.secret_string)["password"])
  }
}
