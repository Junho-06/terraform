output "VPC" {
  value = {
    VPC_ID   = aws_vpc.vpc.id
    VPC_CIDR = aws_vpc.vpc.cidr_block

    Public_Subnet_ids   = try(aws_subnet.public_subnets[*].id, [])
    Private_Subnet_ids  = try(aws_subnet.private_subnets[*].id, [])
    Database_Subnet_ids = try(aws_subnet.database_subnets[*].id, [])

    Database_Route_Table_Seperate = var.vpc.database.database_route_table_seperate

    VPC_Flowlog_ID = try(aws_flow_log.vpc-flowlog[0].id, null)

    Created_Endpoint_List = try(var.vpc.endpoint.service_names, [])
  }
}
