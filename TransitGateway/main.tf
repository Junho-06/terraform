resource "aws_ec2_transit_gateway" "tgw" {
  tags = {
    Name = var.tgw.tgw_name
  }
  description = var.tgw.tgw_name

  amazon_side_asn = 64512

  auto_accept_shared_attachments     = var.tgw.auto_accept_shared_attachments
  default_route_table_association    = var.tgw.default_route_table_association
  default_route_table_propagation    = var.tgw.default_route_table_propagation
  dns_support                        = var.tgw.dns_support
  security_group_referencing_support = var.tgw.security_group_referencing_support
  multicast_support                  = var.tgw.multicast_support
  vpn_ecmp_support                   = var.tgw.vpn_ecmp_support
}

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc-attach" {
  for_each = var.tgw.vpc_information

  transit_gateway_id = aws_ec2_transit_gateway.tgw.id

  vpc_id     = each.value.vpc_id
  subnet_ids = each.value.attach_subnet_ids

  dns_support                        = var.tgw.dns_support
  security_group_referencing_support = var.tgw.security_group_referencing_support

  tags = {
    Name = each.value.tgw_attachment_name
  }
}

resource "aws_ec2_transit_gateway_route_table" "tgw-rt" {
  for_each = var.tgw.tgw_route_table

  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    Name = each.key
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "tgw-rt-associate" {
  for_each = var.tgw.tgw_route_table

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc-attach[each.value.associate_vpc_name].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt[each.key].id
}

resource "aws_ec2_transit_gateway_route" "route" {
  for_each = var.tgw.tgw_route

  destination_cidr_block         = each.value.dest_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc-attach[each.value.dest_vpc_name].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw-rt[each.value.tgw_rt_name].id
}

resource "aws_route" "vpc_routes" {
  for_each = merge([
    for rt_key, rt in var.tgw.vpc_route : {
      for cidr in rt.dest_cidr :
      "${rt.route_table_id}-${cidr}" => {
        route_table_id = rt.route_table_id
        dest_cidr      = cidr
      }
    }
  ]...)

  route_table_id         = each.value.route_table_id
  destination_cidr_block = each.value.dest_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}
