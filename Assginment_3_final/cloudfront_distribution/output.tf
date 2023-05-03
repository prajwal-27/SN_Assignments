# these are the output variables for Cloudfront module
output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.cloud_front_distribution_v1.domain_name
}