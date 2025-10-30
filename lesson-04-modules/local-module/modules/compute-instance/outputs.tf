# Outputs for compute-instance module

output "id" {
  value       = google_compute_instance.this.id
  description = "Instance ID"
}

output "name" {
  value       = google_compute_instance.this.name
  description = "Instance name"
}

output "zone" {
  value       = google_compute_instance.this.zone
  description = "Instance zone"
}

output "machine_type" {
  value       = google_compute_instance.this.machine_type
  description = "Instance machine type"
}

output "internal_ip" {
  value       = google_compute_instance.this.network_interface[0].network_ip
  description = "Internal IP address"
}

output "external_ip" {
  value       = google_compute_instance.this.network_interface[0].access_config[0].nat_ip
  description = "External IP address"
}

output "self_link" {
  value       = google_compute_instance.this.self_link
  description = "Instance self link"
}

output "instance" {
  value       = google_compute_instance.this
  description = "Full instance resource"
}
