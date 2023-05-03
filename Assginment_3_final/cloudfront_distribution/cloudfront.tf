
#creating AWS Cloudfront distribution :
resource "aws_cloudfront_distribution" "cloud_front_distribution_v1" {
  enabled = true

  origin {
    domain_name = "${var.aws_rest_api_id}.execute-api.${var.region}.amazonaws.com"
    origin_path = "/${var.rest_api_stage_name}"
    origin_id   = "Custome-${var.aws_rest_api_id}.execute-api.${var.region}.amazonaws.com"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "Custome-${var.aws_rest_api_id}.execute-api.${var.region}.amazonaws.com"
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      headers      = []
      query_string = true
      cookies {
        forward = "all"
      }
    }
  }
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["IN", "US", "CA"]
    }
  }
  tags = {
    "Project"   = "hands-on.cloud"
    "ManagedBy" = "Terraform"
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

#creating OAI :
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "Lambda assingments"
}
