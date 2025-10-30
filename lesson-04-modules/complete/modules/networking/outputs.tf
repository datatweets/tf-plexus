output "network_id" {
  value       = google_compute_network.vpc.id
  description = "VPC network ID"
}

output "network_name" {
  value       = google_compute_network.vpc.name
  description = "VPC network name"
}

output "frontend_subnet_id" {
  value       = google_compute_subnetwork.frontend.id
  description = "Frontend subnet ID"
}

output "application_subnet_id" {
  value       = google_compute_subnetwork.application.id
  description = "Application subnet ID"
}

output "database_subnet_id" {
  value       = google_compute_subnetwork.database.id
  description = "Database subnet ID"
}

output "management_subnet_id" {
  value       = google_compute_subnetwork.management.id
  description = "Management subnet ID"
}

output "firewall_rules" {
  value = {
    frontend_ingress  = google_compute_firewall.frontend_ingress.name
    frontend_to_app   = google_compute_firewall.frontend_to_app.name
    app_to_database   = google_compute_firewall.app_to_database.name
    management_ssh    = google_compute_firewall.management_ssh.name
    health_checks     = google_compute_firewall.health_checks.name
    internal          = google_compute_firewall.internal.name
  }
  description = "Created firewall rules"
}
