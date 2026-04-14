resource "google_compute_region_health_check" "lb_health_check"{
  name = "lb-health-check"
  region = var.region
  http_health_check {
    port = 8080
  }
}

resource "google_compute_region_backend_service" "backend" {
  name = var.backend
  region = var.region
  protocol = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks = [google_compute_region_health_check.lb_health_check.id]
  port_name = var.port_name

  backend {
    group = google_compute_region_instance_group_manager.app_server.instance_group
    balancing_mode = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0
  }
}

resource "google_compute_region_url_map" "url_map" {
  name = "lb-regional-url-map"
  region = var.region
  default_service = google_compute_region_backend_service.backend.id
}

resource "google_compute_region_target_http_proxy" "http_proxy" {
  name = "lb-http-proxy"
  region = var.region
  url_map = google_compute_region_url_map.url_map.id
}

resource "google_compute_forwarding_rule" "forwarding_rule" {
  name = "lb-forwarding-rule"
  region = var.region
  ip_protocol = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range = "80"
  target = google_compute_region_target_http_proxy.http_proxy.id
  network_tier = "STANDARD"
  depends_on = [google_compute_subnetwork.proxy_subnet]
}

resource "google_compute_subnetwork" "proxy_subnet" {
  name = "lb-proxy-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region = var.region
  network = "default"
  purpose = "REGIONAL_MANAGED_PROXY"
  role = "ACTIVE"
}