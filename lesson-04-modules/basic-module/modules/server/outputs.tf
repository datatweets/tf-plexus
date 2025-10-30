# modules/server/outputs.tf

output "public_ip_address" {
  value       = var.static_ip ? google_compute_instance.this.network_interface[0].access_config[0].nat_ip : null
  description = "Public IP address (null if no static IP)"
}

output "private_ip_address" {
  value       = google_compute_instance.this.network_interface[0].network_ip
  description = "Private IP address"
}

output "self_link" {
  value       = google_compute_instance.this.self_link
  description = "Self link for resource references"
}

output "instance_id" {
  value       = google_compute_instance.this.instance_id
  description = "Unique instance ID"
}
