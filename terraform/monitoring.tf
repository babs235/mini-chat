# ── CANAL DE NOTIFICATION EMAIL ──────────────────────────────
# Remplace AWS SNS — reçoit les alertes Cloud Monitoring
resource "google_monitoring_notification_channel" "email" {
  display_name = "Mini-Chat Alerts Email"
  type         = "email"

  labels = {
    email_address = "babikiribrahimalkhalil@gmail.com"
  }
}

# ── UPTIME CHECK ──────────────────────────────────────────────
# Vérifie que l'URL Cloud Run répond toutes les 5 minutes
resource "google_monitoring_uptime_check_config" "cloudrun" {
  display_name = "mini-chat-uptime"
  timeout      = "10s"
  period       = "300s"

  http_check {
    path         = "/"
    port         = 443
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = trimprefix(google_cloud_run_v2_service.backend.uri, "https://")
    }
  }

  depends_on = [google_cloud_run_v2_service.backend]
}

# ── ALERTE INDISPONIBILITE ────────────────────────────────────
# Déclenche un email si le service ne répond pas
resource "google_monitoring_alert_policy" "uptime_failure" {
  display_name = "mini-chat-service-down"
  combiner     = "OR"

  conditions {
    display_name = "Service Cloud Run indisponible"

    condition_threshold {
      filter          = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.type=\"uptime_url\""
      duration        = "60s"
      comparison      = "COMPARISON_LT"
      threshold_value = 1

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_TRUE"
        group_by_fields      = ["resource.label.host"]
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
  alert_strategy {
    notification_rate_limit {
      period = "300s"
    }
  }
}

# ── ALERTE ERREURS 5XX ────────────────────────────────────────
# Déclenche si le taux d'erreurs serveur dépasse 5%
resource "google_monitoring_alert_policy" "error_rate" {
  display_name = "mini-chat-high-error-rate"
  combiner     = "OR"

  conditions {
    display_name = "Taux d'erreurs 5xx elevé"

    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/request_count\" AND metric.labels.response_code_class=\"5xx\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 10

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
}
