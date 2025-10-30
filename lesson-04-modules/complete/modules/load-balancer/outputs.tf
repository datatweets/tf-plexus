output "name" {
  value       = var.name
  description = "Load balancer name"
}

output "external_ip" {
  value       = google_compute_global_forwarding_rule.http.ip_address
  description = "Load balancer external IP"
}

output "backend_count" {
  value       = length(var.backend_instances)
  description = "Number of backend instances"
}

output "health_check_name" {
  value       = google_compute_health_check.http.name
  description = "Health check name"
}

output "backend_service_name" {
  value       = google_compute_backend_service.web.name
  description = "Backend service name"
}
