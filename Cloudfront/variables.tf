variable "cf" {
  type        = any
  description = "Variables for Cloudfront"
  default = {
    ipv6_enabled = false

    # PriceClass_All = Use all edge locations
    # PriceClass_200 = Use North America, Europe, Asia, Middle East, and Africa
    # PriceClass_100 = Use only North America and Europe
    price_class = "PriceClass_All"

    default_root_object = null # "index.html"

    custom_origins = {
      alb_1 = {
        domain_name = "myalb.us-east-1.elb.amazonaws.com"
        protocol    = "http-only"

        connection_timeout = 10
        read_timeout       = 30
        retry              = 3
      }
    }

    s3_origins = {
      s3_1 = {
        domain_name = "mybucket.s3.us-east-1.amazonaws.com" # BUCKET_NAME.s3.REGION.amazonaws.com
      }
    }

    default_cache_behavior = {
      origin_id       = "s3"
      allowed_methods = "GET" # GET | POST

      cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
      origin_request_policy_id = null
    }

    cache_behavior = {
      # Order matters
      api = {
        path_pattern    = "/v1/color"
        origin_id       = "alb"
        allowed_methods = "POST"

        cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingDisabled
        origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3" # AllViewer
      }
    }

    tags = {
      Name = "skills-cdn"
    }
  }
}
