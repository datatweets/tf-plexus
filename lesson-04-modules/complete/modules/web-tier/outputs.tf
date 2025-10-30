output "instance_count" {
  value       = var.instance_count
  description = "Number of web instances"
}

output "instance_names" {
  value       = google_compute_instance.web[*].name
  description = "Names of web instances"
}

output "instance_ids" {
  value       = google_compute_instance.web[*].id
  description = "IDs of web instances"
}

output "instance_self_links" {
  value       = google_compute_instance.web[*].self_link
  description = "Self links of web instances"
}

output "internal_ips" {
  value       = google_compute_instance.web[*].network_interface[0].network_ip
  description = "Internal IP addresses"
}

output "external_ips" {
  value       = google_compute_instance.web[*].network_interface[0].access_config[0].nat_ip
  description = "External IP addresses"
}
