variable "project_id" {
  description = "ID du projet GCP"
  type        = string
  default     = "mini-chat-asd"
}

variable "region" {
  description = "Région GCP cible"
  type        = string
  default     = "europe-west1"
}

variable "db_password" {
  description = "Mot de passe Cloud SQL MySQL"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "Clé secrète pour signer les tokens JWT"
  type        = string
  sensitive   = true
}

# En CI/CD : github.sha → traçabilité exacte du commit déployé
# En local  : "latest" pour les terraform plan manuels
variable "image_tag" {
  description = "Tag de l'image Docker dans Artifact Registry"
  type        = string
  default     = "latest"
}
