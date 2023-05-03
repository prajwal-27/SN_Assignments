resource "aws_cloudwatch_log_group" "cloudwatch_yada" {
  name = "/aws/my-api-gateway/my-cloudwatch-logs"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "log_stream" {
  name           = "api_gateway_log_stream"
  log_group_name = aws_cloudwatch_log_group.cloudwatch_yada.name
}

resource "aws_cloudwatch_log_metric_filter" "metric_filter" {
  name           = "api_gateway_metric_filter"
  pattern        = "ERROR"
  log_group_name = aws_cloudwatch_log_group.cloudwatch_yada.name
  metric_transformation {
    name      = "ErrorCount"
    namespace = "APIgateway"
    value     = "1"
  }
}

data "aws_iam_policy_document" "cloudwatch_logs" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    effect = "Allow"

    resources = [
      "${aws_cloudwatch_log_group.cloudwatch_yada.arn}",
    ]
  }
}