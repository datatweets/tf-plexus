# Networking Module - Outputs
# Purpose: Expose important network information to other modules

output "vpc_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "vpc_self_link" {
  description = "The self_link of the VPC network"
  value       = google_compute_network.vpc.self_link
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value = {
    for key, subnet in google_compute_subnetwork.subnets :
    key => subnet.id
  }
}

output "subnet_self_links" {
  description = "Map of subnet names to their self_links"
  value = {
    for key, subnet in google_compute_subnetwork.subnets :
    key => subnet.self_link
  }
}

output "subnet_names" {
  description = "Map of subnet keys to their full names"
  value = {
    for key, subnet in google_compute_subnetwork.subnets :
    key => subnet.name
  }
}

output "firewall_rule_names" {
  description = "List of firewall rule names created"
  value = [
    for rule in google_compute_firewall.rules :
    rule.name
  ]
}

output "network_info" {
  description = "Complete network information for reference"
  value = {
    vpc_name    = google_compute_network.vpc.name
    vpc_id      = google_compute_network.vpc.id
    subnets     = {
      for key, subnet in google_compute_subnetwork.subnets :
      key => {
        name          = subnet.name
        cidr          = subnet.ip_cidr_range
        region        = subnet.region
        gateway       = subnet.gateway_address
      }
    }
    environment = var.environment
  }
}
