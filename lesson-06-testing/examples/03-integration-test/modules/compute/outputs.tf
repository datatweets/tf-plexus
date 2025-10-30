output "instance_ids" {
  description = "Map of instance names to their IDs"
  value       = { for k, v in google_compute_instance.instances : k => v.instance_id }
}

output "instance_names" {
  description = "Map of instance keys to their names"
  value       = { for k, v in google_compute_instance.instances : k => v.name }
}

output "internal_ips" {
  description = "Map of instance names to internal IPs"
  value       = { for k, v in google_compute_instance.instances : k => v.network_interface[0].network_ip }
}

output "external_ips" {
  description = "Map of instance names to external IPs (if assigned)"
  value = { 
    for k, v in google_compute_instance.instances : 
    k => length(v.network_interface[0].access_config) > 0 ? v.network_interface[0].access_config[0].nat_ip : null 
  }
}
