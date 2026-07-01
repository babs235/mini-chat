# URL publique Cloud Run — HTTPS automatique sans configuration
output "app_url" {
  description = "URL publique de l'application Cloud Run"
  value       = google_cloud_run_v2_service.backend.uri
}

# Connexion Cloud SQL — utile pour les opérations manuelles
output "cloud_sql_connection" {
  description = "Nom de connexion Cloud SQL"
  value       = google_sql_database_instance.main.connection_name
}

# Nom du service Cloud Run
output "cloudrun_service" {
  description = "Nom du service Cloud Run"
  value       = google_cloud_run_v2_service.backend.name
}

