variable "tgw" {
  type = any
  default = {
    region = "ap-northeast-2"

    tgw_name = "wsc2024-vpc-tgw"

    auto_accept_shared_attachments     = "disable"
    default_route_table_association    = "disable"
    default_route_table_propagation    = "disable"
    dns_support                        = "enable"
    security_group_referencing_support = "enable"
    multicast_support                  = "disable"
    vpn_ecmp_support                   = "disable"

    # Key Name을 VPC Name으로 설정해야 함
    vpc_information = {
      wsc2024-ma-vpc = {
        vpc_id              = "vpc-018e9ee7e887fab46"
        tgw_attachment_name = "wsc2024-ma-tgw-attach"
        attach_subnet_ids   = ["subnet-09cb47453091e8940", "subnet-01564f4ea02bc21a8"]
      },
      wsc2024-prod-vpc = {
        vpc_id              = "vpc-0a5aee9e169aecc6f"
        tgw_attachment_name = "wsc2024-prod-tgw-attach"
        attach_subnet_ids   = ["subnet-0f5e394288bf4ad9a", "subnet-0c48ecbb238dd81f6"]
      },
      wsc2024-storage-vpc = {
        vpc_id              = "vpc-0bc23a34a04b530c0"
        tgw_attachment_name = "wsc2024-storage-tgw-attach"
        attach_subnet_ids   = ["subnet-00c230c6b0a473c49", "subnet-097c9e5f5f2b443fc"]
      }
    }

    # Key Name이 TGW Route Table Name이 됨
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

    tgw_route = {
      route1 = {
        tgw_rt_name   = "wsc2024-ma-tgw-rt"
        dest_vpc_name = "wsc2024-prod-vpc"
        dest_cidr     = "172.16.0.0/16"
      },
      route2 = {
        tgw_rt_name   = "wsc2024-ma-tgw-rt"
        dest_vpc_name = "wsc2024-storage-vpc"
        dest_cidr     = "192.168.0.0/16"
      },
      route3 = {
        tgw_rt_name   = "wsc2024-prod-tgw-rt"
        dest_vpc_name = "wsc2024-ma-vpc"
        dest_cidr     = "10.0.0.0/16"
      },
      route4 = {
        tgw_rt_name   = "wsc2024-prod-tgw-rt"
        dest_vpc_name = "wsc2024-storage-vpc"
        dest_cidr     = "192.168.0.0/16"
      },
      route5 = {
        tgw_rt_name   = "wsc2024-storage-tgw-rt"
        dest_vpc_name = "wsc2024-ma-vpc"
        dest_cidr     = "10.0.0.0/16"
      },
      route6 = {
        tgw_rt_name   = "wsc2024-storage-tgw-rt"
        dest_vpc_name = "wsc2024-prod-vpc"
        dest_cidr     = "172.16.0.0/16"
      }
    }

    vpc_route = {
      rt1 = {
        route_table_id = "rtb-05ac88f2cf9405e07"
        dest_cidr      = ["172.16.0.0/16", "192.168.0.0/16"]
      },
      rt2 = {
        route_table_id = "rtb-0ef8d01c60127d53d"
        dest_cidr      = ["10.0.0.0/16", "192.168.0.0/16"]
      },
      rt3 = {
        route_table_id = "rtb-07f836b5f6f8b7a5f"
        dest_cidr      = ["10.0.0.0/16", "192.168.0.0/16"]
      },
      rt4 = {
        route_table_id = "rtb-0d3047e64f43f2bf6"
        dest_cidr      = ["10.0.0.0/16", "172.16.0.0/16"]
      }
    }
  }
}
