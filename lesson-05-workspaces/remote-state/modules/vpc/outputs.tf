output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "network_self_link" {
  description = "Self link of the VPC network"
  value       = google_compute_network.vpc.self_link
}

output "public_subnet_name" {
  description = "Name of the public subnet"
  value       = google_compute_subnetwork.public.name
}

output "public_subnet_cidr" {
  description = "CIDR block of the public subnet"
  value       = google_compute_subnetwork.public.ip_cidr_range
}

output "private_subnet_name" {
  description = "Name of the private subnet"
  value       = google_compute_subnetwork.private.name
}

output "private_subnet_cidr" {
  description = "CIDR block of the private subnet"
  value       = google_compute_subnetwork.private.ip_cidr_range
}
