output "vpc_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "vpc_id" {
  description = "VPC network ID"
  value       = google_compute_network.vpc.id
}

output "subnet_name" {
  description = "Subnet name"
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_cidr" {
  description = "Subnet CIDR range"
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}

output "instance_names" {
  description = "VM instance names"
  value       = google_compute_instance.vm[*].name
}

output "instance_ids" {
  description = "VM instance IDs"
  value       = google_compute_instance.vm[*].id
}

output "instance_ips" {
  description = "VM external IP addresses"
  value       = google_compute_instance.vm[*].network_interface[0].access_config[0].nat_ip
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}
