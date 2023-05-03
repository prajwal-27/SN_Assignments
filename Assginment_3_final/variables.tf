variable "region" {
  type        = string
  description = "The AWS Region to use"
  default     = "us-east-1"
}
variable "account_id" {
  type        = string
  description = "The account ID in which to create/manage resources"
  default = "422578292388"
}
