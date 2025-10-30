# ============================================================================
# Outputs
# ============================================================================
output "bucket_name" {
  description = "Name of the created storage bucket"
  value       = google_storage_bucket.data.name
}

output "bucket_url" {
  description = "URL of the storage bucket"
  value       = google_storage_bucket.data.url
}

output "instance_names" {
  description = "Names of all created instances"
  value       = google_compute_instance.app[*].name
}

output "instance_ips" {
  description = "Internal IP addresses of instances"
  value       = google_compute_instance.app[*].network_interface[0].network_ip
}

output "instance_details" {
  description = "Detailed instance information"
  value = {
    for instance in google_compute_instance.app :
    instance.name => {
      zone         = instance.zone
      machine_type = instance.machine_type
      internal_ip  = instance.network_interface[0].network_ip
    }
  }
}
