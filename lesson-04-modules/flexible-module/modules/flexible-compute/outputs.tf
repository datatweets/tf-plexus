# Outputs for flexible-compute module

output "id" {
  value       = google_compute_instance.this.id
  description = "Instance ID"
}

output "name" {
  value       = google_compute_instance.this.name
  description = "Instance name"
}

output "zone" {
  value       = google_compute_instance.this.zone
  description = "Instance zone"
}

output "machine_type" {
  value       = google_compute_instance.this.machine_type
  description = "Instance machine type"
}

output "internal_ip" {
  value       = google_compute_instance.this.network_interface[0].network_ip
  description = "Internal IP address"
}

output "external_ip" {
  value       = var.enable_external_ip ? google_compute_instance.this.network_interface[0].access_config[0].nat_ip : "none"
  description = "External IP address"
}

output "self_link" {
  value       = google_compute_instance.this.self_link
  description = "Instance self link"
}

# Configuration details
output "sizing_used" {
  value       = local.use_sizing ? var.sizing : "custom"
  description = "Sizing configuration used"
}

output "disk_size_gb" {
  value       = local.final_disk_size
  description = "Boot disk size in GB"
}

output "disk_type" {
  value       = local.final_disk_type
  description = "Boot disk type"
}

# Optional features
output "data_disk_names" {
  value       = var.attach_data_disks ? google_compute_disk.data_disks[*].name : []
  description = "Names of attached data disks"
}

output "monitoring_enabled" {
  value       = var.enable_monitoring
  description = "Whether monitoring is enabled"
}

output "backup_enabled" {
  value       = var.enable_backup
  description = "Whether backup is enabled"
}

output "security_features" {
  value = {
    secure_boot          = var.enable_secure_boot
    vtpm                 = var.enable_vtpm
    integrity_monitoring = var.enable_integrity_monitoring
  }
  description = "Enabled security features"
}

# Cost estimate
output "monthly_cost_estimate" {
  value       = local.total_monthly_cost
  description = "Estimated monthly cost in USD"
}

# Full instance resource
output "instance" {
  value       = google_compute_instance.this
  description = "Full instance resource"
  sensitive   = true
}
