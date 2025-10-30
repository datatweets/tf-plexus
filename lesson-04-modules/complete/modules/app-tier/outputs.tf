output "instance_count" {
  value       = var.instance_count
  description = "Number of app instances"
}

output "instance_names" {
  value       = google_compute_instance.app[*].name
  description = "Names of app instances"
}

output "instance_ids" {
  value       = google_compute_instance.app[*].id
  description = "IDs of app instances"
}

output "internal_ips" {
  value       = google_compute_instance.app[*].network_interface[0].network_ip
  description = "Internal IP addresses"
}
