resource "google_compute_health_check" "auto_healing" {
  name = var.health_check
  check_interval_sec = 10
  timeout_sec = 10
  healthy_threshold = 2
  unhealthy_threshold = 10

  http_health_check {
    request_path = "/health_check"
    port = "8080"
  }
}


data "google_compute_image" "instance_image" {
  family = "debian-11"
  project = "debian-cloud"
}

resource "google_compute_instance_template" "instance_template" {
  name = var.instance_template

  machine_type = "e2-medium"
  can_ip_forward = false

  scheduling {
    automatic_restart = true
    on_host_maintenance = "MIGRATE"
  }

  metadata = {
    google_api_key = var.google_api_key
    pinecone_api_key = var.pinecone_api_key
    index_name = var.index
    langchain_api_key = var.langchain_api_key
    huggingface_token = var.huggingface_token
    cache_bucket_name = var.cache_bucket_name
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash

    # 1. Install Docker on the Debian VM
    apt-get update
    apt-get install -y docker.io

    # 2. Authenticate to Google Artifact Registry (if your image is private)
    # Replace the URL with your actual Artifact Registry region if different
    gcloud auth configure-docker us-central1-docker.pkg.dev

    # 3. Execute the Docker container, injecting variables directly into memory
    # NOTE: Replace the image path at the bottom with your actual Artifact Registry path
    docker run -d -p 8080:8080 \
      -e GOOGLE_API_KEY=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/google_api_key) \
      -e INDEX_NAME=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/index_name) \
      -e PINECONE_API_KEY=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/pinecone_api_key) \
      -e LANGCHAIN_API_KEY=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/langchain_api_key) \
      -e LANGCHAIN_PROJECT=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/langchain_project) \
      -e HUGGINGFACE_TOKEN=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/huggingface_token) \
      -e CACHE_BUCKET_NAME=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/cache_bucket_name) \
      -e DEEPEVAL_TELEMETRY_OPT_OUT="YES" \
      -e LANGCHAIN_TRACING_V2="true" \
      -e LANGCHAIN_ENDPOINT="https://api.smith.langchain.com" \
      us-central1-docker.pkg.dev/cliniclarity/app-repo/cliniclarity-backend:latest
  EOT


  disk {
    source_image = data.google_compute_image.instance_image.self_link
    auto_delete = true
    boot = true
  }

  service_account {
    email = google_service_account.cliniclarity_service_account.email
    scopes = ["cloud-platform"]
  }

  tags = ["cliniclarity-application"]

  network_interface { network = "default" }

  lifecycle {
    precondition {
      condition = length(data.google_compute_image.instance_image.id) > 0
      error_message = "OS image is not found for the instance-template"
    }
  }

}

resource "google_compute_firewall" "allow_lb_health_check" {
  name = "allow-lb-health-check"
  network = "default"
  direction = "INGRESS"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  allow {
    protocol = "tcp"
    ports = ["8080"]
  }
  target_tags = ["cliniclarity-application"]
}

resource "google_service_account" "cliniclarity_service_account" {
  account_id = "cliniclarity-app-service"
  display_name = "CliniClarity Application Identity"
}

resource "google_project_iam_member" "firebase_admin" {
  project = "cliniclarity"
  role = "roles/firebaseauth.admin"
  member = "serviceAccount:${google_service_account.cliniclarity_service_account.email}"
}

data "google_compute_zones" "available_zones" {
  region = var.region
  status = "UP"
}

resource "google_compute_region_instance_group_manager" "app_server" {
  name = var.regional_instance_group

  base_instance_name = "app"
  region = var.region
  distribution_policy_zones = slice(data.google_compute_zones.available_zones.names, 0, 3)

  version {
    instance_template = google_compute_instance_template.instance_template.self_link_unique
  }
  named_port {
    name = var.port_name
    port = 8080
  }

  auto_healing_policies {
    health_check = google_compute_health_check.auto_healing.id
    initial_delay_sec = 300
  }
}

resource "google_compute_region_autoscaler" "autoscaling" {
  name = var.autoscaler
  region = var.region
  target = google_compute_region_instance_group_manager.app_server.id

  autoscaling_policy {
    min_replicas = 2
    max_replicas = 5
    cooldown_period = 240

    cpu_utilization { target = 0.7 }
  }
}
