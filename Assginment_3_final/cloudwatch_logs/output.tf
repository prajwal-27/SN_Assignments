# these are the output variables for Cloudwatch module
output "cloudwatch_logs" {
  value     = aws_cloudwatch_log_group.cloudwatch_yada.arn
}