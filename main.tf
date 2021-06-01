provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/20"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Environment = "poc"
  }
}

