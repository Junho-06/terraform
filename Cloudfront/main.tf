locals {
  methods = {
    GET  = ["GET", "HEAD"]
    POST = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
  }
}
resource "aws_cloudfront_distribution" "cf" {
  enabled = true

  is_ipv6_enabled = var.cf.ipv6_enabled
  price_class     = var.cf.price_class

  dynamic "origin" {
    for_each = var.cf.custom_origins
    content {
      origin_id   = origin.key
      domain_name = origin.value.domain_name

      connection_attempts = origin.value.retry
      connection_timeout  = origin.value.connection_timeout
      custom_origin_config {
        http_port                = 80
        https_port               = 443
        origin_keepalive_timeout = 5
        origin_protocol_policy   = origin.value.protocol
        origin_read_timeout      = origin.value.read_timeout
        origin_ssl_protocols     = ["TLSv1.2", "TLSv1.1", "TLSv1", "SSLv3"]
      }
    }
  }
  dynamic "origin" {
    for_each = each.value.s3_origins
    content {
      origin_id   = origin.key
      domain_name = origin.value.domain_name
      s3_origin_config {
        origin_access_identity = ""
      }
      origin_access_control_id = aws_cloudfront_origin_access_control.oac[each.key].id
    }
  }

  default_cache_behavior {
    target_origin_id         = var.cf.default_cache_behavior.origin_id
    viewer_protocol_policy   = "redirect-to-https"
    allowed_methods          = local.methods[var.cf.default_cache_behavior.allowed_methods]
    cached_methods           = ["GET", "HEAD"]
    cache_policy_id          = var.cf.default_cache_behavior.cache_policy_id
    origin_request_policy_id = var.cf.default_cache_behavior.origin_request_policy_id
  }

  dynamic "ordered_cache_behavior" {
    for_each = each.value.cache_behavior
    content {
      path_pattern             = ordered_cache_behavior.value.path_pattern
      target_origin_id         = ordered_cache_behavior.value.origin_id
      viewer_protocol_policy   = "redirect-to-https"
      allowed_methods          = local.methods[ordered_cache_behavior.value.allowed_methods]
      cached_methods           = ["GET", "HEAD"]
      cache_policy_id          = ordered_cache_behavior.value.cache_policy_id
      origin_request_policy_id = ordered_cache_behavior.value.origin_request_policy_id
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = var.cf.tags

  default_root_object = try(var.cf.default_root_object, null)
}
resource "aws_cloudfront_origin_access_control" "oac" {
  for_each = var.cf.s3_origins

  name                              = each.value.domain_name
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
