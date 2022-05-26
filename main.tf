provider "aws" {
  region = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

variable "region" {}
variable "bucket_name" {}
variable "access_key" {}
variable "secret_key" {}

resource "aws_s3_bucket" "example" {
  bucket = var.bucket_name
  
}
