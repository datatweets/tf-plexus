# Outputs for dynamic block example

output "instance_name" {
  value       = google_compute_instance.server.name
  description = "Name of the instance"
}

output "instance_ip" {
  value       = google_compute_instance.server.network_interface[0].access_config[0].nat_ip
  description = "External IP address"
}

output "instance_internal_ip" {
  value       = google_compute_instance.server.network_interface[0].network_ip
  description = "Internal IP address"
}

output "attached_disks" {
  value = {
    for name, disk in google_compute_disk.data_disks : name => {
      id   = disk.id
      size = disk.size
      type = disk.type
      mode = var.disks[name].mode
    }
  }
  description = "Details of all attached disks"
}

output "disk_names" {
  value       = [for disk in google_compute_disk.data_disks : disk.name]
  description = "List of all disk names"
}

output "disk_count" {
  value       = length(var.disks)
  description = "Number of attached disks"
}

output "firewall_rules" {
  value = {
    name  = google_compute_firewall.allow_ports.name
    ports = [for rule in var.firewall_rules : rule.port]
  }
  description = "Firewall rule details"
}

output "ssh_command" {
  value       = "gcloud compute ssh ${google_compute_instance.server.name} --zone=${google_compute_instance.server.zone}"
  description = "Command to SSH into the instance"
}

output "multi_nic_instance" {
  value = var.create_multi_nic ? {
    name = google_compute_instance.multi_nic[0].name
    zone = google_compute_instance.multi_nic[0].zone
  } : null
  description = "Multi-NIC instance details if created"
}
