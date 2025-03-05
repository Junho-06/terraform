variable "vpc" {
  type        = any
  description = "Mapping value for VPC"

  default = {
    region = "ap-northeast-2"

    vpc_name = "skills-vpc"
    vpc_cidr = "10.0.0.0/16"

    create_public_subnets = true
    public = {
      # ["a", "c"] / ["a", "b", "c"] / ...
      # az 순서 상관 없는데 private subnet az랑 맞추는게 중요함 (NAT GW 위치 때문에)
      public_subnet_azs = ["a", "b"]
      public_subnet_names = {
        "a" = "skills-public-a"
        "b" = "skills-public-b"
      }
      public_subnet_cidrs = {
        "a" = "10.0.0.0/24"
        "b" = "10.0.1.0/24"
      }
      internet_gateway_name   = "skills-igw"
      public_route_table_name = "skills-public-rt"
    }

    create_private_subnets = true
    private = {
      private_subnet_azs = ["a", "b"]
      private_subnet_names = {
        "a" = "skills-private-a"
        "b" = "skills-private-b"
      }
      private_subnet_cidrs = {
        "a" = "10.0.10.0/24"
        "b" = "10.0.11.0/24"
      }
      nat_gateway_names = {
        "a" = "skills-ngw-a"
        "b" = "skills-ngw-b"
      }
      private_route_table_names = {
        "a" = "skills-private-rt-a"
        "b" = "skills-private-rt-b"
      }
    }

    create_database_subnets = true
    database = {
      database_subnet_azs = ["a", "b"]
      database_subnet_names = {
        "a" = "skills-database-a"
        "b" = "skills-database-b"
      }
      database_subnet_cidrs = {
        "a" = "10.0.20.0/24"
        "b" = "10.0.21.0/24"
      }
      database_route_table_seperate = false
      # database_route_table_seperate = true 일 때 사용하는 rt 이름
      database_route_table_seperate_names = {
        "a" = "skills-database-rt-a"
        "b" = "skills-database-rt-b"
      }
      # database_route_table_seperate = false 일 때 사용하는 rt 이름
      database_route_table_name = "skills-database-rt"
    }

    flowlog = {
      vpc_flowlog_to_cloudwatch_enable = true
      flowlog_traffic_type             = "ALL" # "ALL", "ACCEPT", "REJECT"
      flowlog_log_group_name           = "skills-vpc-flowlog-log-group"
      flowlog_max_aggregation_interval = 60 # 60s or 600s
      flowlog_log_group_retention_days = 90
    }

    endpoint = {
      vpc_endpoint_security_group_name = "skills-endpoint-sg"
      service_names = [
        "s3",
        "dynamodb",
        # "sts",
        # "ecr.api",
        # "ecr.dkr",
        # "secretsmanager",
        # "kms",
        # "eks",
        # "autoscaling",
        # "elasticloadbalancing",
        # "ssm",
        # "ssmmessages",
        # "ec2messages",
      ]
    }
  }
}
