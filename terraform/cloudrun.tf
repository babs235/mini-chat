# ── CLOUD RUN SERVICE ────────────────────────────────────────
# Remplace ECS Fargate + ALB + ACM — Cloud Run gère HTTPS automatiquement
resource "google_cloud_run_v2_service" "backend" {
  name     = "mini-chat-backend"
  location = var.region

  template {
    service_account = google_service_account.cloudrun.email

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/mini-chat/backend:${var.image_tag}"

      ports {
        container_port = 3000
      }

      # Variables non-sensibles
      env {
        name  = "NODE_ENV"
        value = "production"
      }
      env {
        name  = "DB_USER"
        value = "root"
      }
      env {
        name  = "DB_NAME"
        value = "mini_chat"
      }
      # Connexion Cloud SQL via socket Unix (Auth Proxy intégré)
      env {
        name  = "DB_SOCKET_PATH"
        value = "/cloudsql/${google_sql_database_instance.main.connection_name}"
      }

      # Secrets injectés depuis Secret Manager — jamais en clair
      env {
        name = "DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "JWT_SECRET"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.jwt_secret.secret_id
            version = "latest"
          }
        }
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    # Connexion Cloud SQL Auth Proxy intégrée — crée le socket Unix
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.main.connection_name]
      }
    }

    volume_mounts {
      name       = "cloudsql"
      mount_path = "/cloudsql"
    }

    scaling {
      min_instance_count = 0   # scale to zero quand inactif — coût nul
      max_instance_count = 3
    }
  }

  depends_on = [
    google_secret_manager_secret_version.db_password,
    google_secret_manager_secret_version.jwt_secret,
    google_project_iam_member.cloudrun_sql,
  ]
}

# Accès public à l'URL Cloud Run (pas d'authentification requise)
resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.backend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
