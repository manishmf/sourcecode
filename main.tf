provider "aws" {
  region = var.region
  assume_role {
    role_arn     = var.role_name
    session_name = "my_account"
  }
}

terraform {
  backend "s3" {
    bucket = "abcterrxyz"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

variable "region" {}
variable "bucket_name" {}
variable "role_name" {}
#variable "access_key" {}
#variable "secret_key" {}

resource "aws_s3_bucket" "example" {
  bucket = var.bucket_name
  
}
