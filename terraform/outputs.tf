# IP publique du serveur EC2 - pour s'y connecter
output "ec2_public_ip" {
  description = "Adresse IP publique du serveur EC2"
  value       = aws_instance.mini_chat_ec2.public_ip
}

# Endpoint de la base de données RDS
output "rds_endpoint" {
  description = "Endpoint de la base de données RDS MySQL"
  value       = aws_db_instance.mini_chat_db.endpoint
}

# URL de l'application
output "app_url" {
  description = "URL de l'application Mini-Chat"
  value       = "http://${aws_instance.mini_chat_ec2.public_ip}:3000"
}

# URL de Prometheus
output "prometheus_url" {
  description = "URL de Prometheus"
  value       = "http://${aws_instance.mini_chat_ec2.public_ip}:9090"
}

# URL de Grafana
output "grafana_url" {
  description = "URL de Grafana"
  value       = "http://${aws_instance.mini_chat_ec2.public_ip}:3001"
}