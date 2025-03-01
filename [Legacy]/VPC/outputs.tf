output "vpc" {
  value = <<EOT
    vpc_id             = ${jsonencode(aws_vpc.main-vpc.id)}
    vpc_cidr           = ${jsonencode(aws_vpc.main-vpc.cidr_block)}
    public_subnets     = ${jsonencode([aws_subnet.public-a.id, aws_subnet.public-b.id])}
    private_subnets    = ${jsonencode([aws_subnet.private-a.id, aws_subnet.private-b.id])}
    database_subnets   = ${jsonencode([aws_subnet.database-a.id, aws_subnet.database-b.id])}
  EOT
}
