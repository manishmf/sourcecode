provider "aws" {
  region = var.region
  assume_role {
    role_arn     = "arn:aws:iam::483229333212:role/testrole"
    session_name = "my_account"
  }
}

variable "region" {}
variable "bucket_name" {}
#variable "access_key" {}
#variable "secret_key" {}

resource "aws_s3_bucket" "example" {
  bucket = var.bucket_name
  
}
