output "server_details" {
  description = "Details of all web servers"
  value = {
    names        = google_compute_instance.web[*].name
    zones        = google_compute_instance.web[*].zone
    internal_ips = google_compute_instance.web[*].network_interface[0].network_ip
    external_ips = google_compute_instance.web[*].network_interface[0].access_config[0].nat_ip
  }
}

output "server_names" {
  description = "List of server names"
  value       = google_compute_instance.web[*].name
}

output "first_server_ip" {
  description = "External IP of the first server"
  value       = google_compute_instance.web[0].network_interface[0].access_config[0].nat_ip
}

output "ssh_commands" {
  description = "SSH commands to connect to each server"
  value = [
    for instance in google_compute_instance.web :
    "gcloud compute ssh ${instance.name} --zone=${instance.zone}"
  ]
}
