variable "redshift" {
  type = any
  default = {
    region = "ap-northeast-2"

    vpc_id              = ""
    vpc_cidr            = ""
    database_subnet_ids = ["", ""]

    cluster_name          = "skills-redshift-cluster"
    initial_database_name = "skills"

    cluster_version = "1.0"

    port = "5439"

    # dc2.large, dc2.8xlarge -> multi-az 지원 X
    # ra3.large, ra3.xplus, ra3.4xlarge, ra3.16xlarge -> multi-az 지원 O (단 AZ가 3개 이상일 때)
    node_type = "dc2.large"
    # dc2 type 이면 minimum nodes = 1 / maximum nodes = 16
    # ra3 type 이면 minimum nodes = 2 / maximum nodes = 16
    number_of_nodes = 1

    username = "skillsadmin"

    export_log_types = ["connectionlog", "userlog", "useractivitylog"] # "connectionlog", "userlog", "useractivitylog"
  }
}
