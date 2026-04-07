variable "aws_region" {
  description = "Région AWS"
  default     = "eu-west-3"  # Paris
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