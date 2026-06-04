terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # State distant dans GCS — équivalent du bucket S3 AWS
  backend "gcs" {
    bucket = "mini-chat-asd-tfstate"
    prefix = "prod/terraform.tfstate"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
