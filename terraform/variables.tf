variable "aws_region" {
  description = "Région AWS cible"
  type        = string
  default     = "eu-west-3"
}

# Sans default → Terraform bloque si la valeur n'est pas fournie
# En CI/CD elles arrivent via TF_VAR_* depuis les GitHub Secrets
variable "db_password" {
  description = "Mot de passe RDS MySQL"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "Clé secrète pour signer les tokens JWT"
  type        = string
  sensitive   = true
}

# En CI/CD : github.sha → on sait exactement quel commit est déployé
# En local  : "latest" pour les terraform plan sans pipeline
variable "image_tag" {
  description = "Tag de l'image Docker dans ECR"
  type        = string
  default     = "latest"
}
