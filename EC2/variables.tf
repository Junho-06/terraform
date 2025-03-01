variable "key" {
  type        = string
  description = "for bastion key pair"
  default     = "skills" # 미리 key pair가 생성 되어있는 상태에서, key pair name 입력
}

variable "ec2" {

  # No module named 'requests' 발생 시 local에 pip3 install requests 가 필요함

  type        = any
  description = "Variables for EC2"
  default = {
    region = "ap-northeast-2"

    name = "skills-bastion"

    ec2_ami = "Amazon Linux 2023 AMI" # "Amazon Linux 2 AMI", "Ubuntu"
    arch    = "x86_64"                # arm64

    instance_type = "t3.micro"

    vpc_id    = ""
    subnet_id = "" # Public Subnet ID to locate bastion instance

    sg-name = "bastion-sg"

    ssh-port      = "22" # Best Practice is change this port
    ssh-cidr-myip = true # true = only allow my ip / false = allow 0.0.0.0/0

    map_eip_to_bastion = true # eip associate to bastion

    bastion-iam-role-name = "bastion-role"
    attach-policy         = "Poweruser" # Poweruser / 둘 다 아닐 경우 attach X
  }
}
