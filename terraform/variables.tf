# ============================================================
# variables.tf — Paramètres de l'infrastructure
# ============================================================
# Règle : les valeurs SENSIBLES n'ont pas de default.
# Elles arrivent exclusivement via GitHub Secrets (TF_VAR_*).
# ============================================================

variable "aws_region" {
  description = "Région AWS cible"
  type        = string
  default     = "eu-west-3"
}

variable "db_password" {
  description = "Mot de passe RDS MySQL — via GitHub Secret TF_VAR_db_password"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "Clé secrète JWT — via GitHub Secret TF_VAR_jwt_secret"
  type        = string
  sensitive   = true
}

# En CI/CD : TF_VAR_image_tag=${{ github.sha }}
# En local  : default "latest" pour terraform plan/apply manuel
variable "image_tag" {
  description = "Tag de l'image Docker dans ECR"
  type        = string
  default     = "latest"
}
