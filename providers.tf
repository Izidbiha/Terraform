terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.13"
    }
  }
  required_version = " 1.7.4"
}
provider "aws" {
  region = "eu-west-3"
}
