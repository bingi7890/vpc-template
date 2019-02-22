# providers.tf - declare the provide and region

provider "aws" {
  version = "~> 1.10"
  alias   = "main"
  region  = "us-west-2"
}

# I need to change the place for this code

