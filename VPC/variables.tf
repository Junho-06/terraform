
variable "vpc" {
  type        = any
  description = "VPC input Variable"

  default = {
    name = "skills-vpc"
    cidr = "10.0.0.0/16"

    igw_name = "skills-igw"
    ngw_name = ["skills-ngw-a", "skills-ngw-b"]

    azs = ["ap-northeast-2a", "ap-northeast-2b"]

    public_subnet_names   = ["skills-public-subnet-a", "skills-public-subnet-b"]
    private_subnet_names  = ["skills-private-subnet-a", "skills-private-subnet-b"]
    database_subnet_names = ["skills-database-subnet-a", "skills-database-subnet-b"]

    public_subnet_cidr   = ["10.0.0.0/24", "10.0.1.0/24"]
    private_subnet_cidr  = ["10.0.10.0/24", "10.0.11.0/24"]
    database_subnet_cidr = ["10.0.20.0/24", "10.0.21.0/24"]

    public_route_table_names  = ["skills-public-rt"]
    private_route_table_names = ["skills-private-rt-a", "skills-private-rt-b"]

    database_route_table_separate       = true
    database_route_table_names          = ["skills-database-rt"]                           # database_route_table_separate 변수가 false일 때 사용하는 이름
    database_route_table_separate_names = ["skills-database-rt-a", "skills-database-rt-b"] # database_route_table_separate 변수가 true일 때 사용하는 이름

    enable_cloudwatch_flowlog         = true
    flowlog-traffic-type              = "ALL" # "ACCEPT", "REJECT"
    flowlog-loggroup-name             = "skills-vpc-flowlog"
    flow_log_max_aggregation_interval = 60 # 60s or 600s (10 minutes)
    flow_log_group_retention_days     = 90

    vpc_endpoint_security_group_name = "skills-endpoint-sg"
    vpc_endpoints = [
      "s3",
      "dynamodb",
      "sts",
      # ecr.api",
      # ecr.dkr",
      # secretsmanager",
      # kms",
      # eks",
      # autoscaling",
      # elasticloadbalancing",
      # ssm",
      # ssmmessages",
      # ec2messages",
    ]
  }
}
