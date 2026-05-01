variable "aws_region" {
  description = "Région AWS où déployer l'infrastructure"
  type        = string
  default     = "eu-west-3"
}

variable "db_password" {
  description = "Mot de passe RDS MySQL"
  type        = string
  sensitive   = true
}

variable "key_name" {
  description = "Nom de la clé SSH EC2"
  type        = string
}

variable "admin_ip" {
  description = "IP publique de l'administrateur pour SSH"
  type        = string
  default     = "0.0.0.0/0"
}

# 🔥 AJOUT IMPORTANT
variable "image_tag" {
  description = "Tag de l'image Docker venant du pipeline"
  type        = string
}