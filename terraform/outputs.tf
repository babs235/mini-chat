# ============================================================
# outputs.tf — Informations affichées après terraform apply
# ============================================================

# URL de l'application — à utiliser dans le navigateur
output "app_url" {
  description = "URL publique de l'application (HTTPS)"
  value       = "https://chat.ibrahimbabikir.fr"
}

output "acm_validation_cname" {
  description = "CNAME a ajouter dans IONOS pour valider le certificat SSL"
  value       = aws_acm_certificate.mini_chat.domain_validation_options
}

# Endpoint RDS — utile pour les migrations manuelles
output "rds_endpoint" {
  description = "Endpoint de la base de données RDS MySQL"
  value       = aws_db_instance.mini_chat_db.endpoint
}

# Nom du cluster ECS — pour les commandes aws ecs
output "ecs_cluster" {
  description = "Nom du cluster ECS"
  value       = aws_ecs_cluster.mini_chat.name
}

# Nom du service ECS — pour les rollbacks et le monitoring
output "ecs_service" {
  description = "Nom du service ECS"
  value       = aws_ecs_service.backend.name
}
