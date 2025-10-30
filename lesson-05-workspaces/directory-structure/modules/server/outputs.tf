output "id" {
  value       = var.enable_static_ip ? google_compute_instance.server_with_static_ip[0].id : google_compute_instance.server.id
  description = "Server instance ID"
}

output "name" {
  value       = var.enable_static_ip ? google_compute_instance.server_with_static_ip[0].name : google_compute_instance.server.name
  description = "Server instance name"
}

output "internal_ip" {
  value       = var.enable_static_ip ? google_compute_instance.server_with_static_ip[0].network_interface[0].network_ip : google_compute_instance.server.network_interface[0].network_ip
  description = "Internal IP address"
}

output "external_ip" {
  value       = var.enable_static_ip ? google_compute_address.static_ip[0].address : (var.enable_external_ip ? google_compute_instance.server.network_interface[0].access_config[0].nat_ip : null)
  description = "External IP address (null if not enabled)"
}

output "self_link" {
  value       = var.enable_static_ip ? google_compute_instance.server_with_static_ip[0].self_link : google_compute_instance.server.self_link
  description = "Server self link"
}

output "machine_type" {
  value       = local.machine_types[var.size]
  description = "Machine type used"
}

output "disk_size" {
  value       = local.disk_sizes[var.size]
  description = "Disk size in GB"
}
