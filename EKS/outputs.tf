output "eks" {
  value = {
    kube-config_update_command = "aws eks update-kubeconfig --region ${var.cluster.region} --name ${var.cluster.name}"
  }
}
