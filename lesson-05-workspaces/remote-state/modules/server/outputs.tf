output "id" {
  description = "Server instance ID"
  value       = google_compute_instance.server.instance_id
}

output "name" {
  description = "Server name"
  value       = google_compute_instance.server.name
}

output "internal_ip" {
  description = "Internal IP address"
  value       = google_compute_instance.server.network_interface[0].network_ip
}

output "external_ip" {
  description = "External IP address (if enabled)"
  value       = var.enable_external_ip ? google_compute_instance.server.network_interface[0].access_config[0].nat_ip : null
}

output "self_link" {
  description = "Server self link"
  value       = google_compute_instance.server.self_link
}

output "machine_type" {
  description = "Machine type used"
  value       = google_compute_instance.server.machine_type
}
