output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "subnet_ids" {
  description = "Subnet IDs"
  value       = module.networking.subnet_ids
}

output "instance_ids" {
  description = "Instance IDs"
  value       = module.compute.instance_ids
}

output "instance_internal_ips" {
  description = "Instance internal IPs"
  value       = module.compute.internal_ips
}
