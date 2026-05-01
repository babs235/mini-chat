# ============================================================
# variables.tf - "Quelles sont les options ?"
# ============================================================
# Ce fichier définit les variables utilisées dans main.tf
# Avantage : on peut changer les valeurs sans modifier le code
# Les vraies valeurs sont dans terraform.tfvars (pas sur GitHub)
# ============================================================

# Région AWS = dans quel data center on construit
variable "aws_region" {
  description = "Région AWS où déployer l'infrastructure"
  type        = string
  default     = "eu-west-3" # Paris
}

# Mot de passe de la base de données RDS
#  SENSIBLE = ne jamais afficher dans les logs
variable "db_password" {
  description = "Mot de passe RDS MySQL"
  type        = string
  sensitive   = true # Terraform masquera cette valeur dans les logs
}

# Nom de la clé SSH (créée sur AWS Console)
variable "key_name" {
  description = "Nom de la clé SSH EC2 (max 255 caractères)"
  type        = string
  
  validation {
    condition     = length(var.key_name) <= 255
    error_message = "Le nom de la clé SSH ne doit pas dépasser 255 caractères."
  }
}

# IP publique de l'admin (pour restreindre l'accès SSH)
#  Seul toi peux te connecter en SSH
variable "admin_ip" {
  description = "IP publique de l'administrateur pour SSH"
  type        = string
  default     = "0.0.0.0/0" # Par défaut : tout le monde (À REMPLACER par ton IP/32)
}
