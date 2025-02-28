variable "alb" {
  type        = any
  description = "Value for ALB"
  default = {
    name     = "skills-alb"
    internal = false

    # internal = false 일 때는 public subnets
    public_subnets = ["subnet-0839403815cefa4fd", "subnet-07d349fc271cf70ce"]
    # internal = true 일 때는 private subnets
    private_subnets = []

    enable_cross_zone_load_balancing = true
    enable_http2                     = true

    idle_timeout         = 60
    preserve_host_header = false

    # Accesslog는 bucket이 s3 관리형 키를 사용해서 암호화 해야함 (CMK는 안됨)
    accesslog = {
      enabled       = true
      bucket_name   = "mytestbucket-20250207-2" # access log와 connection log는 같은 버킷 사용해야함
      bucket_prefix = "accesslog"               # 끝에 / 포함 하면 안됨
    }

    # !!! Bucket 정책 덮어 쓰기 주의 !!!

    # Connectionlog도 bucket이 s3 관리형 키를 사용해서 암호화 해야함 (CMK는 안됨)
    connectionlog = {
      enabled       = true
      bucket_name   = "mytestbucket-20250207-2" # access log와 connection log는 같은 버킷 사용해야함
      bucket_prefix = "connectionlog"           # 끝에 / 포함 하면 안됨
    }

    listener_protocol = "HTTP" # HTTPS
    listener_port     = 80
  }
}

variable "tg" {
  type        = any
  description = "Target Group Value"
  default = {
    name        = "skills-tg"
    target_type = "instance" # ip

    target_port = 8080

    protocol         = "HTTP"  # HTTPS, TCP, UDP
    protocol_version = "HTTP1" # HTTP2

    load_balancing_algorithm_type = "round_robin" # round_robin, least_outstanding_requests, weighted_random

    deregistration_delay = 10

    vpc_id = "vpc-0eee0002731cc0abf"

    health_check_protocol = "HTTP"
    health_check_port     = "8080"
    health_check_path     = "/healthcheck"

    health_check_healthy_threshold   = 2
    health_check_unhealthy_threshold = 2
    health_check_interval            = 10
    health_check_timeout             = 5
  }
}
