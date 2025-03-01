output "bastion" {
  value = {
    Instance_Puiblic_IP = var.ec2.map_eip_to_bastion == true ? aws_eip.bastion-eip[0].public_ip : aws_instance.bastion.public_ip

    AMI_ID = data.external.ami_lookup.result["ami_id"]

    Instance_SSH_CIDR = "${var.ec2.ssh-cidr-myip == true ? "${chomp(data.http.myip[0].response_body)}/32" : "0.0.0.0/0"}"

    Instance_Attached_Policy_ARN = "arn:aws:iam::aws:policy/${var.ec2.attach-policy == "Admin" ? "AdministratorAccess" : var.ec2.attach-policy == "Poweruser" ? "PowerUserAccess" : null}"
  }
}
