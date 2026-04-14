resource "google_compute_firewall" "allow_lb_health_check" {
  name          = "allow-lb-health-check"
  network       = "default"
  direction     = "INGRESS"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  target_tags = ["cliniclarity-application"]
}

resource "google_service_account" "cliniclarity_service_account" {
  account_id   = "cliniclarity-app-service"
  display_name = "CliniClarity Application Identity"
}

resource "google_project_iam_member" "firebase_admin" {
  project = "cliniclarity"
  role    = "roles/firebaseauth.admin"
  member  = "serviceAccount:${google_service_account.cliniclarity_service_account.email}"
}

resource "google_cloud_run_v2_service" "cliniclarity_api" {
  name     = var.cloud_run
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.cliniclarity_service_account.email

    containers {
      image = "${var.region}-docker.pkg.dev/cliniclarity/my-repo/cliniclarity-app:latest"

      ports {
        container_port = 8080
      }

      env {
        name  = "GOOGLE_API_KEY"
        value = var.google_api_key
      }

      env {
        name  = "INDEX_NAME"
        value = var.index
      }
      env {
        name  = "LANGCHAIN_API_KEY"
        value = var.langchain_api_key
      }
      env {
        name  = "LANGCHAIN_PROJECT"
        value = "cliniclarity-production"
      }

      env {
        name  = "HUGGINGFACE_TOKEN"
        value = var.huggingface_token
      }
      env {
        name  = "CACHE_BUCKET_NAME"
        value = var.cache_bucket_name
      }

      env {
        name  = "DEEPEVAL_TELEMETRY_OPT_OUT"
        value = "YES"
      }
      env {
        name  = "LANGCHAIN_TRACING_V2"
        value = "true"
      }
      env {
        name  = "LANGCHAIN_ENDPOINT"
        value = "https://api.smith.langchain.com"
      }
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "public_access" {
  project  = google_cloud_run_v2_service.cliniclarity_api.project
  location = google_cloud_run_v2_service.cliniclarity_api.location
  name     = google_cloud_run_v2_service.cliniclarity_api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
