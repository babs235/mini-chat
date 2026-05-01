# ============================================================
# outputs.tf - "Quelles adresses afficher après le déploiement ?"
# ============================================================
# Après terraform apply, Terraform affiche ces valeurs
# C'est comme un reçu qui te donne les infos importantes
# ============================================================

# ID de l'instance EC2 (utile pour SSM Session Manager)
# Exemple : aws ssm start-session --target i-0XXXXXXXXX
output "ec2_instance_id" {
  description = "ID de l'instance EC2 (pour se connecter via SSM)"
  value       = aws_instance.mini_chat_ec2.id
}

# IP publique du serveur EC2
output "ec2_public_ip" {
  description = "Adresse IP publique du serveur EC2"
  value       = aws_instance.mini_chat_ec2.public_ip
}

# Endpoint de la base de données RDS
# C'est l'adresse que le backend utilise pour se connecter à MySQL
output "rds_endpoint" {
  description = "Endpoint de la base de données RDS MySQL"
  value       = aws_db_instance.mini_chat_db.endpoint
}

# URL de l'application
output "app_url" {
  description = "URL de l'application Mini-Chat"
  value       = "http://${aws_instance.mini_chat_ec2.public_ip}:3000"
}
