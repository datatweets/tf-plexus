output "instance_name" {
  value       = google_compute_instance.monitoring.name
  description = "Monitoring instance name"
}

output "instance_id" {
  value       = google_compute_instance.monitoring.id
  description = "Monitoring instance ID"
}

output "internal_ip" {
  value       = google_compute_instance.monitoring.network_interface[0].network_ip
  description = "Internal IP address"
}

output "external_ip" {
  value       = google_compute_instance.monitoring.network_interface[0].access_config[0].nat_ip
  description = "External IP address"
}

output "monitored_instances" {
  value       = var.monitored_instances
  description = "List of monitored instances"
}
