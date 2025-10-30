# Database outputs (for compute layer to consume)
output "db_instance_name" {
  description = "Database instance name"
  value       = module.database.instance_name
}

output "db_connection_name" {
  description = "Database connection name"
  value       = module.database.instance_connection_name
}

output "db_private_ip" {
  description = "Database private IP"
  value       = module.database.private_ip
}

output "db_name" {
  description = "Database name"
  value       = module.database.database_name
}

# Summary
output "database_summary" {
  description = "Database deployment summary"
  value = {
    environment     = "dev"
    instance_name   = module.database.instance_name
    tier            = "db-f1-micro"
    disk_size       = "10GB"
    private_ip      = module.database.private_ip
    cost_estimate   = "$10/month"
  }
}
