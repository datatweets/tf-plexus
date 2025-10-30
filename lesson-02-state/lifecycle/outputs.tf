output "web_server_ip" {
  description = "External IP of the high-availability web server"
  value       = google_compute_instance.web.network_interface[0].access_config[0].nat_ip
}

output "critical_bucket" {
  description = "Name of the protected critical data bucket"
  value       = google_storage_bucket.critical_data.name
}

output "monitored_server_details" {
  description = "Details of the monitored server"
  value = {
    name        = google_compute_instance.monitored.name
    internal_ip = google_compute_instance.monitored.network_interface[0].network_ip
    external_ip = google_compute_instance.monitored.network_interface[0].access_config[0].nat_ip
  }
}

output "production_db_details" {
  description = "Details of the production database server"
  value = {
    name        = google_compute_instance.production_db.name
    internal_ip = google_compute_instance.production_db.network_interface[0].network_ip
  }
}
