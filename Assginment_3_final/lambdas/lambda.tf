data "archive_file" "lambda_code_into_zip" {
  type        = "zip"
  source_dir  = "${path.module}/my-lambda-function"
  output_path = "${path.module}/my-lambda-function.zip"
}

resource "aws_s3_bucket" "my_lambda_s3_bucket" {
  bucket = var.s3_bucket_name
}
//making the s3 bucket private
resource "aws_s3_bucket_acl" "lambda_bucket_acl" {
  bucket = aws_s3_bucket.my_lambda_s3_bucket.id
  acl    = "private"
  depends_on = [aws_s3_bucket_ownership_controls.example]
}
# puting some ownership control to s3 bucket object default ["BucketOwnerPreferred", "ObjectWriter"]
resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.my_lambda_s3_bucket.id

  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_object" "lambda_code_as_s3_object" {
  bucket = aws_s3_bucket.my_lambda_s3_bucket.id
  key    = "my-lambda-function.zip"
  source = data.archive_file.lambda_code_into_zip.output_path
  etag   = filemd5(data.archive_file.lambda_code_into_zip.output_path)
}

resource "aws_lambda_function" "lambda_function" {
  function_name    = var.lambda_function_name
  s3_bucket        = aws_s3_bucket.my_lambda_s3_bucket.id
  s3_key           = aws_s3_object.lambda_code_as_s3_object.key
  runtime          = "nodejs12.x"
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_code_into_zip.output_base64sha256
  role             = aws_iam_role.lambda_execution_role.arn
}
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_function.function_name}"
  retention_in_days = 30
}
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role_${var.lambda_function_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}