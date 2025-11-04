# Compute Module - Outputs
# Purpose: Expose web server and load balancer information

output "instance_ids" {
  description = "IDs of the web server instances"
  value       = google_compute_instance.web_servers[*].id
}

output "instance_names" {
  description = "Names of the web server instances"
  value       = google_compute_instance.web_servers[*].name
}

output "instance_private_ips" {
  description = "Private IP addresses of web servers"
  value       = google_compute_instance.web_servers[*].network_interface[0].network_ip
}

output "instance_public_ips" {
  description = "Public IP addresses of web servers"
  value = [
    for instance in google_compute_instance.web_servers :
    try(instance.network_interface[0].access_config[0].nat_ip, "N/A")
  ]
}

output "load_balancer_ip" {
  description = "Public IP address of the load balancer"
  value       = var.enable_load_balancer ? google_compute_global_forwarding_rule.web_forwarding_rule[0].ip_address : "No load balancer configured"
}

output "load_balancer_url" {
  description = "URL to access the load balancer"
  value       = var.enable_load_balancer ? "http://${google_compute_global_forwarding_rule.web_forwarding_rule[0].ip_address}" : "No load balancer configured"
}

output "instance_group_id" {
  description = "ID of the instance group"
  value       = var.enable_load_balancer ? google_compute_instance_group.web_group[0].id : null
}

output "backend_service_id" {
  description = "ID of the backend service"
  value       = var.enable_load_balancer ? google_compute_backend_service.web_backend[0].id : null
}

output "web_servers_summary" {
  description = "Summary of web server deployment"
  value = {
    count        = var.instance_count
    machine_type = var.machine_type
    zone         = var.zone
    names        = google_compute_instance.web_servers[*].name
    private_ips  = google_compute_instance.web_servers[*].network_interface[0].network_ip
    public_ips   = [
      for instance in google_compute_instance.web_servers :
      try(instance.network_interface[0].access_config[0].nat_ip, "N/A")
    ]
    lb_enabled   = var.enable_load_balancer
    lb_ip        = var.enable_load_balancer ? google_compute_global_forwarding_rule.web_forwarding_rule[0].ip_address : null
  }
}
