output "instance_template" {
  value = google_compute_instance_template.instance_template.id
  sensitive = false
}

output "managed_instance_group" {
  value = google_compute_region_instance_group_manager.app_server.id
  sensitive = false
}
