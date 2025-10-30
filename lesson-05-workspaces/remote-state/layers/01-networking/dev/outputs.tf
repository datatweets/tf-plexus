output "network_name" {
  description = "VPC network name"
  value       = module.vpc.network_name
}

output "network_self_link" {
  description = "VPC network self link"
  value       = module.vpc.network_self_link
}

output "public_subnet_name" {
  description = "Public subnet name"
  value       = module.vpc.public_subnet_name
}

output "public_subnet_cidr" {
  description = "Public subnet CIDR"
  value       = module.vpc.public_subnet_cidr
}

output "private_subnet_name" {
  description = "Private subnet name"
  value       = module.vpc.private_subnet_name
}

output "private_subnet_cidr" {
  description = "Private subnet CIDR"
  value       = module.vpc.private_subnet_cidr
}

# These outputs will be consumed by compute layer via terraform_remote_state
output "public_subnet_self_link" {
  description = "Public subnet self link (for compute layer)"
  value       = "projects/${var.project_id}/regions/${var.region}/subnetworks/${module.vpc.public_subnet_name}"
}

output "private_subnet_self_link" {
  description = "Private subnet self link (for compute layer)"
  value       = "projects/${var.project_id}/regions/${var.region}/subnetworks/${module.vpc.private_subnet_name}"
}
