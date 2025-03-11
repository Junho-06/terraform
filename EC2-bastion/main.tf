# Bastion
# ========================================================
resource "aws_instance" "bastion" {
  ami = data.external.ami_lookup.result["ami_id"]

  instance_type = var.ec2.instance_type
  key_name      = aws_key_pair.keypair.key_name

  subnet_id              = var.ec2.subnet_id
  vpc_security_group_ids = [aws_security_group.bastion_security_group.id]

  iam_instance_profile = aws_iam_instance_profile.bastion_profile.name

  associate_public_ip_address = true

  tags = {
    Name = var.ec2.name
  }

  user_data = var.ec2.ssh-port != 22 ? join("\n", [
    "#!/bin/bash",
    "sed -i 's/^#Port 22/Port ${var.ec2.ssh-port}/' /etc/ssh/sshd_config",
    "sed -i 's/^Port 22/Port ${var.ec2.ssh-port}/' /etc/ssh/sshd_config",
    "systemctl daemon-reload",
    "systemctl restart ${startswith(var.ec2.ec2_ami, "Amazon Linux") == true ? "sshd" : "ssh"}"
  ]) : null
}


# Key Pair
# ========================================================
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "keypair" {
  key_name   = var.key
  public_key = tls_private_key.key.public_key_openssh
}

resource "local_file" "local" {
  filename        = "./keypairs/${var.key}.pem"
  content         = tls_private_key.key.private_key_pem
  file_permission = "0600"
}


# Bastion Security Group
# ========================================================
resource "aws_security_group" "bastion_security_group" {
  name        = var.ec2.sg-name
  description = "bastion security group"

  vpc_id = var.ec2.vpc_id

  ingress {
    from_port   = var.ec2.ssh-port
    to_port     = var.ec2.ssh-port
    protocol    = "tcp"
    cidr_blocks = ["${var.ec2.ssh-cidr-myip == true ? "${chomp(data.http.myip[0].response_body)}/32" : "0.0.0.0/0"}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.ec2.sg-name
  }
}

data "http" "myip" {
  count = var.ec2.ssh-cidr-myip ? 1 : 0
  url   = "https://ipv4.icanhazip.com"
}


# Bastion IAM Role
# ========================================================
resource "aws_iam_role" "bastion_role" {
  name = var.ec2.bastion-iam-role-name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bastion-policy-attach" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/${var.ec2.attach-policy == "Admin" ? "AdministratorAccess" : var.ec2.attach-policy == "Poweruser" ? "PowerUserAccess" : null}"
}

resource "aws_iam_role_policy_attachments_exclusive" "bastion-policy-delete" {
  role_name   = aws_iam_role.bastion_role.name
  policy_arns = ["arn:aws:iam::aws:policy/${var.ec2.attach-policy == "Admin" ? "AdministratorAccess" : var.ec2.attach-policy == "Poweruser" ? "PowerUserAccess" : null}"]
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = var.ec2.bastion-iam-role-name
  role = aws_iam_role.bastion_role.name
}


# Bastion Elastic IP
# ========================================================
resource "aws_eip" "bastion-eip" {
  count = var.ec2.map_eip_to_bastion ? 1 : 0

  domain                    = "vpc"
  instance                  = aws_instance.bastion.id
  associate_with_private_ip = aws_instance.bastion.private_ip
}


# Bastion AMI ID Find
# ========================================================
data "external" "ami_lookup" {
  program = [
    "python3",
    "${path.module}/get_ami.py",
    var.ec2.region,
    var.ec2.ec2_ami,
    var.ec2.arch
  ]
}
