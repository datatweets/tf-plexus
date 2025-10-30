output "vpc_name" {
  description = "VPC name"
  value       = module.infrastructure.vpc_name
}

output "instance_names" {
  description = "Instance names"
  value       = module.infrastructure.instance_names
}

output "instance_ips" {
  description = "Instance IPs"
  value       = module.infrastructure.instance_ips
}
