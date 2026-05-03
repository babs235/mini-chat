terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # State distant dans S3 chiffré — pas de lock DynamoDB (projet solo, un seul apply à la fois)
  backend "s3" {
    bucket  = "mini-chat-tfstate-babs235"
    key     = "prod/terraform.tfstate"
    region  = "eu-west-3"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}
