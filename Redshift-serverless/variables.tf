variable "redshift" {
  type = any
  default = {
    region = "ap-northeast-2"

    vpc_id   = ""
    vpc_cidr = ""
    # 최소 3개 가용영역 필요함
    database_subnet_ids = ["", "", ""]

    namespace_name = "skills-redshift-namespace"
    workgroup_name = "skills-redshift-workgroup"

    initial_database_name = "skills"

    port = "5439"

    # 32 ~ 512 / incrementes of 8
    base_capacity = 32
    max_capacity  = 128

    username = "skillsadmin"

    export_log_types = ["connectionlog", "userlog", "useractivitylog"] # "connectionlog", "userlog", "useractivitylog"
  }
}
