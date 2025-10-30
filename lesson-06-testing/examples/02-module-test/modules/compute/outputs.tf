output "instance_id" {
  description = "ID of the compute instance"
  value       = google_compute_instance.vm.instance_id
}

output "instance_name" {
  description = "Name of the compute instance"
  value       = google_compute_instance.vm.name
}

output "instance_self_link" {
  description = "Self link of the compute instance"
  value       = google_compute_instance.vm.self_link
}

output "internal_ip" {
  description = "Internal IP address of the instance"
  value       = google_compute_instance.vm.network_interface[0].network_ip
}

output "external_ip" {
  description = "External IP address of the instance (if assigned)"
  value       = length(google_compute_instance.vm.network_interface[0].access_config) > 0 ? google_compute_instance.vm.network_interface[0].access_config[0].nat_ip : null
}

output "zone" {
  description = "Zone where the instance is located"
  value       = google_compute_instance.vm.zone
}

output "machine_type" {
  description = "Machine type of the instance"
  value       = google_compute_instance.vm.machine_type
}

output "tags" {
  description = "Tags applied to the instance"
  value       = google_compute_instance.vm.tags
}
