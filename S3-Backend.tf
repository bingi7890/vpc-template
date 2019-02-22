terraform {
  backend "s3" {
    bucket  = "nike-net-us-west-2-tfstate"
    key     = "VPC-template/terraform.tfstate"
    region  = "us-west-2"
    encrypt = "true"
  }
}
