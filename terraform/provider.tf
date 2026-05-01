# ============================================================
# provider.tf - "Qui construit et où sont les plans ?"
# ============================================================
# Ce fichier dit à Terraform :
#   1. Quel fournisseur cloud utiliser (AWS)
#   2. Où stocker le state (coffre-fort S3)
#   3. Où mettre le verrou (cadenas DynamoDB)
# ============================================================

terraform {
  # Quels fournisseurs (providers) on utilise
  required_providers {
    aws = {
      source  = "hashicorp/aws" # L'éditeur du provider
      version = "~> 5.0"        # Version 5.x (compatible)
    }
  }

  # Backend = où Terraform stocke son "state"
  # Le state = la liste de tout ce que Terraform a construit
  # Sans backend, le state est sur ton PC → perdu si tu changes de machine
  # Avec backend S3 → le state est dans le cloud → accessible partout
  backend "s3" {
    bucket         = "mini-chat-tfstate-babs235" # Le coffre-fort (ton bucket S3)
    key            = "prod/terraform.tfstate"     # Le chemin du fichier dans le bucket
    region         = "eu-west-3"                  # Région du bucket (Paris)
    encrypt        = true                         # Chiffrer les données dans S3
    dynamodb_table = "mini-chat-tflock"           # Le cadenas (table DynamoDB)
  }
}

# Provider AWS = "Je veux construire sur AWS"
provider "aws" {
  region = var.aws_region # Quel data center (défini dans variables.tf)
}
