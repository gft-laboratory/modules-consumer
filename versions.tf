terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.00"
    }
  }

  backend "s3" {
    bucket         = "hdi-tfstate-project"
    key            = "module-data/terraform_hdi.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform_locks"
  }
}

provider "aws" {
  region = "us-east-2"
}