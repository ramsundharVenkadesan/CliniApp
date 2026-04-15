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

  deletion_protection = false

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
        name  = "FIREBASE_API_KEY"
        value = data.google_firebase_web_app_config.app_config.api_key
      }
      env {
        name  = "FIREBASE_AUTH_DOMAIN"
        value = data.google_firebase_web_app_config.app_config.auth_domain
      }

      env {
        name  = "LANGCHAIN_ENDPOINT"
        value = "https://api.smith.langchain.com"
      }
    }
  }
  lifecycle {
    ignore_changes = [
      template.0.containers.0.image,
      client,
      client_version
    ]
  }
}

resource "google_cloud_run_v2_service_iam_member" "public_access" {
  project  = google_cloud_run_v2_service.cliniclarity_api.project
  location = google_cloud_run_v2_service.cliniclarity_api.location
  name     = google_cloud_run_v2_service.cliniclarity_api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
