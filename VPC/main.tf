# VPC
# ========================================================
resource "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc.vpc_name
  }
  cidr_block           = var.vpc.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  depends_on = [aws_cloudwatch_log_group.vpc-flowlog-loggroup[0]]
}


# public subnet
# ========================================================
resource "aws_subnet" "public_subnets" {
  count = var.vpc.create_public_subnets == true ? length(var.vpc.public.public_subnet_azs) : 0

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.vpc.public.public_subnet_cidrs[var.vpc.public.public_subnet_azs[count.index]]
  availability_zone = "${var.vpc.region}${var.vpc.public.public_subnet_azs[count.index]}"

  tags = merge(
    {
      Name = var.vpc.public.public_subnet_names[var.vpc.public.public_subnet_azs[count.index]]
    },
    var.vpc.public.public_subnet_loadbalancer_controller_tag == true ? {
      "kubernetes.io/role/elb" = "1"
    } : {}
  )

  map_public_ip_on_launch                     = true
  enable_resource_name_dns_a_record_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  count = var.vpc.create_public_subnets == true ? 1 : 0

  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.vpc.public.internet_gateway_name
  }
}

resource "aws_route_table" "public-rt" {
  count = var.vpc.create_public_subnets == true ? 1 : 0

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }
  route {
    cidr_block = var.vpc.vpc_cidr
    gateway_id = "local"
  }

  tags = {
    Name = var.vpc.public.public_route_table_name
  }
}

resource "aws_route_table_association" "public-subnet-association" {
  count = var.vpc.create_public_subnets == true ? length(var.vpc.public.public_subnet_azs) : 0

  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public-rt[0].id
}


# private subnet
# ========================================================
resource "aws_subnet" "private_subnets" {
  count = var.vpc.create_private_subnets == true ? length(var.vpc.private.private_subnet_azs) : 0

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.vpc.private.private_subnet_cidrs[var.vpc.private.private_subnet_azs[count.index]]
  availability_zone = "${var.vpc.region}${var.vpc.private.private_subnet_azs[count.index]}"

  tags = merge(
    {
      Name = var.vpc.private.private_subnet_names[var.vpc.private.private_subnet_azs[count.index]]
    },
    var.vpc.private.private_subnet_loadbalancer_controller_tag == true ? {
      "kubernetes.io/role/internal-elb" = "1"
    } : {}
  )

  enable_resource_name_dns_a_record_on_launch = true
}

resource "aws_eip" "ngw-eip" {
  count = var.vpc.create_private_subnets == true ? length(var.vpc.private.private_subnet_azs) : 0

  tags = {
    Name = "${var.vpc.private.nat_gateway_names[var.vpc.private.private_subnet_azs[count.index]]}-eip"
  }
}

resource "aws_nat_gateway" "ngw" {
  count = var.vpc.create_private_subnets == true ? length(var.vpc.private.private_subnet_azs) : 0

  allocation_id = aws_eip.ngw-eip[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id

  tags = {
    Name = var.vpc.private.nat_gateway_names[var.vpc.private.private_subnet_azs[count.index]]
  }
}

resource "aws_route_table" "private-rt" {
  count = var.vpc.create_private_subnets == true ? length(var.vpc.private.private_subnet_azs) : 0

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw[count.index].id
  }
  route {
    cidr_block = var.vpc.vpc_cidr
    gateway_id = "local"
  }

  tags = {
    Name = var.vpc.private.private_route_table_names[var.vpc.private.private_subnet_azs[count.index]]
  }
}

resource "aws_route_table_association" "private-subnet-association" {
  count = var.vpc.create_private_subnets == true ? length(var.vpc.private.private_subnet_azs) : 0

  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private-rt[count.index].id
}


# database subnet
# ========================================================
resource "aws_subnet" "database_subnets" {
  count = var.vpc.create_database_subnets == true ? length(var.vpc.database.database_subnet_azs) : 0

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.vpc.database.database_subnet_cidrs[var.vpc.database.database_subnet_azs[count.index]]
  availability_zone = "${var.vpc.region}${var.vpc.database.database_subnet_azs[count.index]}"

  tags = {
    Name = var.vpc.database.database_subnet_names[var.vpc.database.database_subnet_azs[count.index]]
  }

  enable_resource_name_dns_a_record_on_launch = true
}

resource "aws_route_table" "database-seperate-rt" {
  count = var.vpc.create_database_subnets == true && var.vpc.database.database_route_table_seperate == true ? length(var.vpc.database.database_subnet_azs) : 0

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = var.vpc.vpc_cidr
    gateway_id = "local"
  }

  tags = {
    Name = var.vpc.database.database_route_table_seperate_names[var.vpc.database.database_subnet_azs[count.index]]
  }
}

resource "aws_route_table_association" "database-seperate-subnet-association" {
  count = var.vpc.create_database_subnets == true && var.vpc.database.database_route_table_seperate == true ? length(var.vpc.database.database_subnet_azs) : 0

  subnet_id      = aws_subnet.database_subnets[count.index].id
  route_table_id = aws_route_table.database-seperate-rt[count.index].id
}

resource "aws_route_table" "database-rt" {
  count = var.vpc.create_database_subnets == true && var.vpc.database.database_route_table_seperate == false ? 1 : 0

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = var.vpc.vpc_cidr
    gateway_id = "local"
  }

  tags = {
    Name = var.vpc.database.database_route_table_name
  }
}

resource "aws_route_table_association" "database-subnet-association" {
  count = var.vpc.create_database_subnets == true && var.vpc.database.database_route_table_seperate == false ? length(var.vpc.database.database_subnet_azs) : 0

  subnet_id      = aws_subnet.database_subnets[count.index].id
  route_table_id = aws_route_table.database-rt[0].id
}


# VPC flowlog
# ========================================================
data "aws_iam_policy_document" "assume_role" {
  count = var.vpc.flowlog.vpc_flowlog_to_cloudwatch_enable == true ? 1 : 0

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
  count = var.vpc.flowlog.vpc_flowlog_to_cloudwatch_enable == true ? 1 : 0

  name               = "${var.vpc.vpc_name}-flowlog-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json
}

data "aws_iam_policy_document" "flowlog-policy" {
  count = var.vpc.flowlog.vpc_flowlog_to_cloudwatch_enable == true ? 1 : 0

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

resource "aws_iam_role_policy" "flowlog-policy-attach-to-role" {
  count = var.vpc.flowlog.vpc_flowlog_to_cloudwatch_enable == true ? 1 : 0

  name   = "${var.vpc.vpc_name}-flowlog-policy"
  role   = aws_iam_role.vpc-flowlog-role[0].id
  policy = data.aws_iam_policy_document.flowlog-policy[0].json
}

resource "aws_cloudwatch_log_group" "vpc-flowlog-loggroup" {
  count = var.vpc.flowlog.vpc_flowlog_to_cloudwatch_enable == true ? 1 : 0

  name              = var.vpc.flowlog.flowlog_log_group_name
  retention_in_days = var.vpc.flowlog.flowlog_log_group_retention_days
}

resource "aws_flow_log" "vpc-flowlog" {
  count = var.vpc.flowlog.vpc_flowlog_to_cloudwatch_enable == true ? 1 : 0

  iam_role_arn             = aws_iam_role.vpc-flowlog-role[0].arn
  log_destination          = aws_cloudwatch_log_group.vpc-flowlog-loggroup[0].arn
  traffic_type             = var.vpc.flowlog.flowlog_traffic_type
  vpc_id                   = aws_vpc.vpc.id
  max_aggregation_interval = var.vpc.flowlog.flowlog_max_aggregation_interval
  log_destination_type     = "cloud-watch-logs"

  tags = {
    Name = "${var.vpc.vpc_name}-flowlog"
  }
}


# Endpoint
# ========================================================
resource "aws_security_group" "vpc-endpoint-sg" {
  count = var.vpc.endpoint.create_endpoint_sg == true ? 1 : 0

  name   = var.vpc.endpoint.vpc_endpoint_security_group_name
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.vpc.endpoint.vpc_endpoint_security_group_name
  }
}

resource "aws_vpc_endpoint" "gateway_endpoint" {
  for_each = toset([
    for service_name in var.vpc.endpoint.service_names :
    service_name if contains([
      "s3",
      "dynamodb",
    ], service_name)
  ])

  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${var.vpc.region}.${each.key}"

  vpc_id = aws_vpc.vpc.id

  route_table_ids = compact(flatten([
    try(aws_route_table.public-rt[*].id, null),
    try(aws_route_table.private-rt[*].id, null),
    try(aws_route_table.database-rt[*].id, null),
    try(aws_route_table.database-seperate-rt[*].id, null)
  ]))

  tags = {
    Name = "${var.vpc.vpc_name}-${each.key}-endpoint"
  }
}

resource "aws_vpc_endpoint" "interface_endpoint" {
  for_each = toset([
    for service_name in var.vpc.endpoint.service_names :
    service_name if !contains([
      "s3",
      "dynamodb",
    ], service_name)
  ])

  vpc_endpoint_type = "Interface"
  service_name      = "com.amazonaws.${var.vpc.region}.${each.key}"

  vpc_id = aws_vpc.vpc.id

  private_dns_enabled = true
  subnet_ids          = try(aws_subnet.private_subnets[*].id, null)
  security_group_ids  = [aws_security_group.vpc-endpoint-sg[0].id]

  tags = {
    Name = "${var.vpc.vpc_name}-${each.key}-endpoint"
  }
}
