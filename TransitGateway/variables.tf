variable "tgw" {
  type = any
  default = {
    region = "us-east-1"

    tgw_name = "wsc2024-vpc-tgw"

    auto_accept_shared_attachments     = "disable"
    default_route_table_association    = "disable"
    default_route_table_propagation    = "disable"
    dns_support                        = "enable"
    security_group_referencing_support = "enable"
    multicast_support                  = "disable"
    vpn_ecmp_support                   = "disable"

    vpc_information = {
      wsc2024-ma-vpc = {
        attach_name       = "wsc2024-ma-tgw-attach"
        vpc_id            = "vpc-0c058e8732fc05c1e"
        attach_subnet_ids = ["subnet-0622af0db75634dac", "subnet-07921310e3fd19b4c"]
      },
      wsc2024-prod-vpc = {
        attach_name       = "wsc2024-prod-tgw-attach"
        vpc_id            = "vpc-0347e13817143aee9"
        attach_subnet_ids = ["subnet-0d69ce1cfd7b6ae18", "subnet-0302453579e5f4403"]
      },
      wsc2024-storage-vpc = {
        attach_name       = "wsc2024-storage-tgw-attach"
        vpc_id            = "vpc-0508e30a51e60b039"
        attach_subnet_ids = ["subnet-00fc67cbb6a99a9e7", "subnet-0e0023b13acc72182"]
      }
    }

    tgw_route_table = {
      wsc2024-ma-tgw-rt = {
        associate_vpc_name = "wsc2024-ma-vpc"
      },
      wsc2024-prod-tgw-rt = {
        associate_vpc_name = "wsc2024-prod-vpc"
      },
      wsc2024-storage-tgw-rt = {
        associate_vpc_name = "wsc2024-storage-vpc"
      }
    }

    route = {
      route1 = {
        dest_vpc_name = "wsc2024-ma-vpc"
        dest_cidr     = "10.0.0.0/16"
        tgw_rt_name   = "wsc2024-prod-tgw-rt"
      },
      route2 = {
        dest_vpc_name = "wsc2024-ma-vpc"
        dest_cidr     = "10.0.0.0/16"
        tgw_rt_name   = "wsc2024-storage-tgw-rt"
      },
      route3 = {
        dest_vpc_name = "wsc2024-prod-vpc"
        dest_cidr     = "172.16.0.0/16"
        tgw_rt_name   = "wsc2024-ma-tgw-rt"
      },
      route4 = {
        dest_vpc_name = "wsc2024-prod-vpc"
        dest_cidr     = "172.16.0.0/16"
        tgw_rt_name   = "wsc2024-storage-tgw-rt"
      },
      route5 = {
        dest_vpc_name = "wsc2024-storage-vpc"
        dest_cidr     = "192.168.0.0/16"
        tgw_rt_name   = "wsc2024-ma-tgw-rt"
      },
      route6 = {
        dest_vpc_name = "wsc2024-storage-vpc"
        dest_cidr     = "192.168.0.0/16"
        tgw_rt_name   = "wsc2024-prod-tgw-rt"
      }
    }
  }
}
