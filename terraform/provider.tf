# ============================================================
# provider.tf - "Qui construit et où sont les plans ?"
# ============================================================
# Ce fichier dit à Terraform :
#   1. Quel fournisseur cloud utiliser (AWS)
#   2. Où stocker le state (coffre-fort S3)
#   3. Où mettre le verrou (cadenas DynamoDB)
# ============================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

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
