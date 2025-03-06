output "docdb" {
  value = {
    primary-cluster = {
      Endpoint        = aws_docdb_cluster.primary-cluster.endpoint
      Reader_Endpoint = aws_docdb_cluster.primary-cluster.reader_endpoint
      Username        = var.docdb.global.username
      Password        = var.docdb.global.password
      Port            = var.docdb.global.port
    }

    secondary-cluster = {
      Endpoint        = aws_docdb_cluster.secondary-cluster.endpoint
      Reader_Endpoint = aws_docdb_cluster.secondary-cluster.reader_endpoint
      Username        = var.docdb.global.username
      Password        = var.docdb.global.password
      Port            = var.docdb.global.port
    }
  }
}
