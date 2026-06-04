# ── ARTIFACT REGISTRY ────────────────────────────────────────
# Registre privé pour les images Docker — remplace AWS ECR
resource "google_artifact_registry_repository" "mini_chat" {
  repository_id = "mini-chat"
  format        = "DOCKER"
  location      = var.region
  description   = "Images Docker du projet Mini-Chat"
}

# ── CLOUD SQL MYSQL ──────────────────────────────────────────
# Base de données managée — remplace AWS RDS
resource "google_sql_database_instance" "main" {
  name             = "mini-chat-db"
  database_version = "MYSQL_8_0"
  region           = var.region

  settings {
    tier = "db-f1-micro"

    backup_configuration {
      enabled            = true
      binary_log_enabled = true
      start_time         = "03:00"
    }

    ip_configuration {
      # IP publique nécessaire pour Cloud Run (sans VPC connector)
      # Sécurisé par l'authentification du compte de service Cloud Run
      ipv4_enabled    = true
      require_ssl     = false
    }
  }

  deletion_protection = false
}

resource "google_sql_database" "mini_chat" {
  name     = "mini_chat"
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "root" {
  instance = google_sql_database_instance.main.name
  name     = "root"
  password = var.db_password
  host     = "%"
}

# ── SECRET MANAGER ───────────────────────────────────────────
# Stockage chiffré des secrets — remplace AWS SSM Parameter Store
resource "google_secret_manager_secret" "db_password" {
  secret_id = "mini-chat-db-password"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = var.db_password
}

resource "google_secret_manager_secret" "jwt_secret" {
  secret_id = "mini-chat-jwt-secret"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "jwt_secret" {
  secret      = google_secret_manager_secret.jwt_secret.id
  secret_data = var.jwt_secret
}

# ── SERVICE ACCOUNT CLOUD RUN ────────────────────────────────
# Compte de service dédié au container — principe du moindre privilège
resource "google_service_account" "cloudrun" {
  account_id   = "mini-chat-cloudrun"
  display_name = "Mini-Chat Cloud Run"
}

# Accès à Cloud SQL
resource "google_project_iam_member" "cloudrun_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloudrun.email}"
}

# Accès aux secrets
resource "google_secret_manager_secret_iam_member" "db_password" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloudrun.email}"
}

resource "google_secret_manager_secret_iam_member" "jwt_secret" {
  secret_id = google_secret_manager_secret.jwt_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloudrun.email}"
}
