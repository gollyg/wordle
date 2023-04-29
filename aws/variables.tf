variable "aws_region" {
  description = "AWS Cloud API Secret"
  type        = string
  sensitive   = true
  default = "ap-southeast-2"
}

variable "aws_user_tag" {
  description = "Username for tagging resources. This is important for finding these in the AWS console"
  type        = string
  sensitive   = false
  default = "terraform_user"
}

variable "aws_mysql_password" {
  description = "Password for mysql instnace"
  type        = string
  sensitive   = true
  default = "ch4ng3m3!!!"
}

variable "project_prefix" {
  description = "Password for mysql instnace"
  type        = string
  sensitive   = true
  default = "metering"
}