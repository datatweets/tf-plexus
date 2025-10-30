# Outputs for conditional expression example

output "instance_name" {
  value       = google_compute_instance.server.name
  description = "Name of the instance"
}

output "environment" {
  value       = var.environment
  description = "Current environment"
}

output "machine_type" {
  value       = google_compute_instance.server.machine_type
  description = "Machine type used (conditional based on environment)"
}

output "external_ip" {
  value       = var.assign_external_ip ? google_compute_instance.server.network_interface[0].access_config[0].nat_ip : null
  description = "External IP address (null if not assigned)"
}

output "static_ip_address" {
  value       = var.assign_static_ip ? google_compute_address.static[0].address : null
  description = "Static IP address (null if not created)"
}

output "internal_ip" {
  value       = google_compute_instance.server.network_interface[0].network_ip
  description = "Internal IP address"
}

output "has_static_ip" {
  value       = var.assign_static_ip
  description = "Whether instance has static IP"
}

output "has_external_ip" {
  value       = var.assign_external_ip
  description = "Whether instance has external IP"
}

output "boot_disk_size" {
  value       = google_compute_instance.server.boot_disk[0].initialize_params[0].size
  description = "Boot disk size (conditional: prod=100GB, dev=20GB)"
}

output "boot_disk_type" {
  value       = google_compute_instance.server.boot_disk[0].initialize_params[0].type
  description = "Boot disk type (conditional: prod=pd-ssd, dev=pd-standard)"
}

output "deletion_protection" {
  value       = google_compute_instance.server.deletion_protection
  description = "Whether deletion protection is enabled (prod only)"
}

output "http_firewall_created" {
  value       = var.allow_http_traffic
  description = "Whether HTTP firewall rule was created"
}

output "backup_disk_created" {
  value       = var.enable_backups
  description = "Whether backup disk was created"
}

output "replica_count" {
  value       = length(google_compute_instance.replicas)
  description = "Number of replica instances created (prod only)"
}

output "replica_names" {
  value       = [for instance in google_compute_instance.replicas : instance.name]
  description = "Names of all replica instances"
}

output "all_instance_ips" {
  value = concat(
    [var.assign_external_ip ? google_compute_instance.server.network_interface[0].access_config[0].nat_ip : "no-external-ip"],
    [for instance in google_compute_instance.replicas : instance.network_interface[0].access_config[0].nat_ip]
  )
  description = "All instance external IPs (main + replicas)"
}

output "configuration_summary" {
  value = {
    environment         = var.environment
    machine_type        = google_compute_instance.server.machine_type
    has_static_ip       = var.assign_static_ip
    has_external_ip     = var.assign_external_ip
    boot_disk_size_gb   = google_compute_instance.server.boot_disk[0].initialize_params[0].size
    boot_disk_type      = google_compute_instance.server.boot_disk[0].initialize_params[0].type
    deletion_protection = google_compute_instance.server.deletion_protection
    backup_enabled      = var.enable_backups
    http_allowed        = var.allow_http_traffic
    replica_count       = length(google_compute_instance.replicas)
  }
  description = "Complete configuration summary showing all conditional values"
}

output "ssh_command" {
  value       = "gcloud compute ssh ${google_compute_instance.server.name} --zone=${google_compute_instance.server.zone}"
  description = "Command to SSH into the main instance"
}

output "conditional_logic_demo" {
  value = {
    environment_is_prod     = var.environment == "prod"
    uses_prod_machine_type  = var.environment == "prod" ? "yes" : "no"
    uses_ssd_disk          = var.environment == "prod" ? "yes" : "no"
    has_deletion_protection = var.environment == "prod" ? "yes" : "no"
    replica_behavior        = var.environment == "prod" ? "creates ${var.replica_count} replicas" : "creates 0 replicas"
  }
  description = "Demonstration of conditional logic results"
}
