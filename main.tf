provider "aws" {
  region = var.region
}

variable "region" {}
variable "bucket_name" {}

resource "aws_s3_bucket" "example" {
  bucket = var.bucket_name
  
}
