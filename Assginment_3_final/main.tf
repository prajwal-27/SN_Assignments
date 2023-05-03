module "Lambdas" {
  source = "./lambdas"
}

module "Api_gateway-1" {
  source                 = "./api_gate_ways"
  api_gateway_region     = var.region #this variables are refering from outer variables.tf file and assigning to variable.tf file which are present inside the folder.
  api_gateway_account_id = var.account_id #this variables are refering from outer variables.tf file
  lambda_function_name   = module.Lambdas.lambda_function_name
  lambda_function_arn    = module.Lambdas.lambda_function_arn
  apigtw_logs            = module.Cloudwatch.cloudwatch_logs
}

module "Cloudfront" {
  source          = "./cloudfront_distribution"
  aws_rest_api_id = module.Api_gateway-1.rest_api_id
  bucket_domain_id  = module.Lambdas.aws_s3_bucket_id
  bucket_domain_name = module.Lambdas.aws_s3_bucket_domain
}

module "Cloudwatch" {
  source = "./cloudwatch_logs"
}


