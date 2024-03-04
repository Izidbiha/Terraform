terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.13"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.3"
    }
  }
  required_version = " 1.7.4"
}
provider "aws" {
  region = "eu-west-3"
}

provider "kubernetes" {

}
