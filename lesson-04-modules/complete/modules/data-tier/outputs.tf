output "db_instance_name" {
  value       = google_compute_instance.database.name
  description = "Database instance name"
}

output "db_instance_id" {
  value       = google_compute_instance.database.id
  description = "Database instance ID"
}

output "db_private_ip" {
  value       = google_compute_instance.database.network_interface[0].network_ip
  description = "Database private IP address"
}

output "data_disk_name" {
  value       = google_compute_disk.db_data.name
  description = "Data disk name"
}

output "backup_enabled" {
  value       = var.enable_backup
  description = "Whether backups are enabled"
}

output "backup_policy_name" {
  value       = var.enable_backup ? google_compute_resource_policy.backup_policy[0].name : null
  description = "Backup policy name (if enabled)"
}
