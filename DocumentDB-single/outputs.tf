output "docdb" {
  value = {
    elastic-cluster = {
      Endpoint = var.docdb.elastic_cluster_enable == true ? aws_docdbelastic_cluster.elastic-cluster[0].endpoint : null
      Username = var.docdb.elastic_cluster_enable == true ? var.docdb.elastic.username : null
      password = var.docdb.elastic_cluster_enable == true ? var.docdb.elastic.password : null
    }

    normal-cluster = {
      Endpoint        = var.docdb.elastic_cluster_enable == false ? aws_docdb_cluster.cluster[0].endpoint : null
      Reader_Endpoint = var.docdb.elastic_cluster_enable == false ? aws_docdb_cluster.cluster[0].reader_endpoint : null
      Username        = var.docdb.elastic_cluster_enable == false ? var.docdb.normal.username : null
      Password        = var.docdb.elastic_cluster_enable == false ? var.docdb.normal.password : null
    }
  }
}
