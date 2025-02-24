data "aws_region" "current" {}

resource "aws_vpc" "main-vpc" {
  tags = {
    Name = var.vpc.name
  }
  cidr_block           = var.vpc.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}
resource "aws_subnet" "public-a" {
  vpc_id            = aws_vpc.main-vpc.id
  cidr_block        = var.vpc.public_subnet_cidr[0]
  availability_zone = var.vpc.azs[0]
  tags = {
    Name = var.vpc.public_subnet_names[0]
  }
  map_public_ip_on_launch                     = true
  enable_resource_name_dns_a_record_on_launch = true
}
resource "aws_subnet" "public-b" {
  vpc_id            = aws_vpc.main-vpc.id
  cidr_block        = var.vpc.public_subnet_cidr[1]
  availability_zone = var.vpc.azs[1]
  tags = {
    Name = var.vpc.public_subnet_names[1]
  }
  map_public_ip_on_launch                     = true
  enable_resource_name_dns_a_record_on_launch = true
}
resource "aws_subnet" "private-a" {
  vpc_id            = aws_vpc.main-vpc.id
  cidr_block        = var.vpc.private_subnet_cidr[0]
  availability_zone = var.vpc.azs[0]
  tags = {
    Name = var.vpc.private_subnet_names[0]
  }
  enable_resource_name_dns_a_record_on_launch = true
}
resource "aws_subnet" "private-b" {
  vpc_id            = aws_vpc.main-vpc.id
  cidr_block        = var.vpc.private_subnet_cidr[1]
  availability_zone = var.vpc.azs[1]
  tags = {
    Name = var.vpc.private_subnet_names[1]
  }
  enable_resource_name_dns_a_record_on_launch = true
}
resource "aws_subnet" "database-a" {
  vpc_id            = aws_vpc.main-vpc.id
  cidr_block        = var.vpc.database_subnet_cidr[0]
  availability_zone = var.vpc.azs[0]
  tags = {
    Name = var.vpc.database_subnet_names[0]
  }
  enable_resource_name_dns_a_record_on_launch = true
}
resource "aws_subnet" "database-b" {
  vpc_id            = aws_vpc.main-vpc.id
  cidr_block        = var.vpc.database_subnet_cidr[1]
  availability_zone = var.vpc.azs[1]
  tags = {
    Name = var.vpc.database_subnet_names[1]
  }
  enable_resource_name_dns_a_record_on_launch = true
}
resource "aws_internet_gateway" "main-igw" {
  vpc_id = aws_vpc.main-vpc.id
  tags = {
    Name = var.vpc.igw_name
  }
}
resource "aws_eip" "ngw-a-eip" {}
resource "aws_eip" "ngw-b-eip" {}
resource "aws_nat_gateway" "main-ngw-a" {
  allocation_id = aws_eip.ngw-a-eip.id
  subnet_id     = aws_subnet.public-a.id
  tags = {
    Name = var.vpc.ngw_name[0]
  }
}
resource "aws_nat_gateway" "main-ngw-b" {
  allocation_id = aws_eip.ngw-b-eip.id
  subnet_id     = aws_subnet.public-b.id
  tags = {
    Name = var.vpc.ngw_name[1]
  }
}
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.main-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-igw.id
  }
  route {
    cidr_block = var.vpc.cidr
    gateway_id = "local"
  }
  tags = {
    Name = var.vpc.public_route_table_names[0]
  }
}
resource "aws_route_table" "private-a-rt" {
  vpc_id = aws_vpc.main-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.main-ngw-a.id
  }
  route {
    cidr_block = var.vpc.cidr
    gateway_id = "local"
  }
  tags = {
    Name = var.vpc.private_route_table_names[0]
  }
}
resource "aws_route_table" "private-b-rt" {
  vpc_id = aws_vpc.main-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.main-ngw-b.id
  }
  route {
    cidr_block = var.vpc.cidr
    gateway_id = "local"
  }
  tags = {
    Name = var.vpc.private_route_table_names[1]
  }
}
resource "aws_route_table" "database-a-rt" {
  count  = var.vpc.database_route_table_separate == true ? 1 : 0
  vpc_id = aws_vpc.main-vpc.id
  route {
    cidr_block = var.vpc.cidr
    gateway_id = "local"
  }
  tags = {
    Name = var.vpc.database_route_table_separate_names[0]
  }
}
resource "aws_route_table" "database-b-rt" {
  count  = var.vpc.database_route_table_separate == true ? 1 : 0
  vpc_id = aws_vpc.main-vpc.id
  route {
    cidr_block = var.vpc.cidr
    gateway_id = "local"
  }
  tags = {
    Name = var.vpc.database_route_table_separate_names[1]
  }
}
resource "aws_route_table" "database-rt" {
  count  = var.vpc.database_route_table_separate == false ? 1 : 0
  vpc_id = aws_vpc.main-vpc.id
  route {
    cidr_block = var.vpc.cidr
    gateway_id = "local"
  }
  tags = {
    Name = var.vpc.database_route_table_names[0]
  }
}
resource "aws_route_table_association" "public-a-association" {
  subnet_id      = aws_subnet.public-a.id
  route_table_id = aws_route_table.public-rt.id
}
resource "aws_route_table_association" "public-b-association" {
  subnet_id      = aws_subnet.public-b.id
  route_table_id = aws_route_table.public-rt.id
}
resource "aws_route_table_association" "private-a-association" {
  subnet_id      = aws_subnet.private-a.id
  route_table_id = aws_route_table.private-a-rt.id
}
resource "aws_route_table_association" "private-b-association" {
  subnet_id      = aws_subnet.private-b.id
  route_table_id = aws_route_table.private-b-rt.id
}
resource "aws_route_table_association" "database-a-association" {
  count          = var.vpc.database_route_table_separate == true ? 1 : 0
  subnet_id      = aws_subnet.database-a.id
  route_table_id = aws_route_table.database-a-rt[0].id
}
resource "aws_route_table_association" "database-b-association" {
  count          = var.vpc.database_route_table_separate == true ? 1 : 0
  subnet_id      = aws_subnet.database-b.id
  route_table_id = aws_route_table.database-b-rt[0].id
}
resource "aws_route_table_association" "database-separate-a-association" {
  count          = var.vpc.database_route_table_separate == false ? 1 : 0
  subnet_id      = aws_subnet.database-a.id
  route_table_id = aws_route_table.database-rt[0].id
}
resource "aws_route_table_association" "database-separate-b-association" {
  count          = var.vpc.database_route_table_separate == false ? 1 : 0
  subnet_id      = aws_subnet.database-b.id
  route_table_id = aws_route_table.database-rt[0].id
}
data "aws_iam_policy_document" "assume_role" {
  count = var.vpc.enable_cloudwatch_flowlog == true ? 1 : 0
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "vpc-flowlog-role" {
  count              = var.vpc.enable_cloudwatch_flowlog == true ? 1 : 0
  name               = "${var.vpc.name}-flowlog-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json
}

data "aws_iam_policy_document" "flowlog-policy" {
  count = var.vpc.enable_cloudwatch_flowlog == true ? 1 : 0
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "flowlog-policy-attach" {
  count  = var.vpc.enable_cloudwatch_flowlog == true ? 1 : 0
  name   = "${var.vpc.name}-flowlog-policy"
  role   = aws_iam_role.vpc-flowlog-role[0].id
  policy = data.aws_iam_policy_document.flowlog-policy[0].json
}
resource "aws_cloudwatch_log_group" "vpc-flowlog-loggroup" {
  count             = var.vpc.enable_cloudwatch_flowlog == true ? 1 : 0
  name              = var.vpc.flowlog-loggroup-name
  retention_in_days = var.vpc.flow_log_group_retention_days
}
resource "aws_flow_log" "main-vpc-flowlog" {
  count                    = var.vpc.enable_cloudwatch_flowlog == true ? 1 : 0
  iam_role_arn             = aws_iam_role.vpc-flowlog-role[0].arn
  log_destination          = aws_cloudwatch_log_group.vpc-flowlog-loggroup[0].arn
  traffic_type             = var.vpc.flowlog-traffic-type
  vpc_id                   = aws_vpc.main-vpc.id
  max_aggregation_interval = var.vpc.flow_log_max_aggregation_interval
  log_destination_type     = "cloud-watch-logs"
  tags = {
    Name = "${var.vpc.name}-flowlog"
  }
}
resource "aws_security_group" "vpc-endpoint-sg" {
  name   = var.vpc.vpc_endpoint_security_group_name
  vpc_id = aws_vpc.main-vpc.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc.cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = var.vpc.vpc_endpoint_security_group_name
  }
}
resource "aws_vpc_endpoint" "gateway_endpoint" {
  for_each = toset([
    for service_name in var.vpc.vpc_endpoints :
    service_name if contains([
      "s3",
      "dynamodb",
    ], service_name)
  ])
  vpc_id            = aws_vpc.main-vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
  vpc_endpoint_type = "Gateway"
  route_table_ids = compact([
    aws_route_table.public-rt.id,
    aws_route_table.private-a-rt.id,
    aws_route_table.private-b-rt.id,
    try(aws_route_table.database-rt[0].id, null),
    try(aws_route_table.database-a-rt[0].id, null),
    try(aws_route_table.database-b-rt[0].id, null)
  ])
  tags = {
    Name = "${var.vpc.name}-${each.key}-endpoint"
  }
}
resource "aws_vpc_endpoint" "interface_endpoint" {
  for_each = toset([
    for service_name in var.vpc.vpc_endpoints :
    service_name if !contains([
      "s3",
      "dynamodb",
    ], service_name)
  ])
  vpc_id              = aws_vpc.main-vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private-a.id, aws_subnet.private-b.id]
  security_group_ids  = [aws_security_group.vpc-endpoint-sg.id]
  tags = {
    Name = "${var.vpc.name}-${each.key}-endpoint"
  }
}
