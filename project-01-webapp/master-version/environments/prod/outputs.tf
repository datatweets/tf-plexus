# Production Environment - Outputs
# Purpose: Expose important information about the deployed infrastructure

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "region" {
  description = "GCP Region"
  value       = var.region
}

# Networking Outputs
output "vpc_name" {
  description = "VPC network name"
  value       = module.networking.vpc_name
}

output "vpc_id" {
  description = "VPC network ID"
  value       = module.networking.vpc_id
}

output "subnet_names" {
  description = "Names of created subnets"
  value       = module.networking.subnet_names
}

# Compute Outputs
output "web_server_names" {
  description = "Names of web server instances"
  value       = module.compute.instance_names
}

output "web_server_ips" {
  description = "Public IP addresses of web servers"
  value       = module.compute.instance_public_ips
  sensitive   = true # Hide in prod for security
}

output "load_balancer_ip" {
  description = "Load balancer public IP"
  value       = module.compute.load_balancer_ip
}

output "load_balancer_url" {
  description = "URL to access the application"
  value       = module.compute.load_balancer_url
}

# Database Outputs
output "database_instance_name" {
  description = "Cloud SQL instance name"
  value       = var.enable_database ? module.database[0].instance_name : "Database not enabled"
}

output "database_connection_name" {
  description = "Cloud SQL connection name"
  value       = var.enable_database ? module.database[0].instance_connection_name : "Database not enabled"
  sensitive   = true
}

output "database_ip" {
  description = "Database public IP address"
  value       = var.enable_database ? module.database[0].public_ip_address : "Database not enabled"
  sensitive   = true
}

output "database_connection_command" {
  description = "Command to connect to the database"
  value       = var.enable_database ? module.database[0].connection_command : "Database not enabled"
  sensitive   = true
}

# Storage Outputs
output "storage_bucket_names" {
  description = "Names of created storage buckets"
  value       = var.enable_storage ? module.storage[0].bucket_names : {}
}

output "storage_bucket_urls" {
  description = "URLs of created storage buckets"
  value       = var.enable_storage ? module.storage[0].bucket_urls : {}
}

# Comprehensive Summary
output "deployment_summary" {
  description = "Complete summary of the deployment"
  value = {
    environment = var.environment
    region      = var.region
    
    networking = {
      vpc_name     = module.networking.vpc_name
      subnet_count = length(module.networking.subnet_names)
      subnets      = module.networking.subnet_names
    }
    
    compute = {
      instance_count    = var.web_server_count
      machine_type      = var.machine_type
      instances         = module.compute.instance_names
      load_balancer_ip  = module.compute.load_balancer_ip
      load_balancer_url = module.compute.load_balancer_url
    }
    
    database = var.enable_database ? {
      enabled       = true
      instance_name = module.database[0].instance_name
      version       = module.database[0].database_version
      tier          = var.database_tier
      backups       = var.enable_database_backups
    } : {
      enabled = false
    }
    
    storage = var.enable_storage ? {
      enabled      = true
      bucket_count = length(module.storage[0].bucket_names)
      buckets      = module.storage[0].bucket_names
    } : {
      enabled = false
    }
    
    protection = {
      database_deletion_protection = var.enable_database
      storage_force_destroy        = false
    }
  }
}

# Quick Access Information
output "quick_access" {
  description = "Quick access URLs and commands"
  value = <<-EOT
    
    ═══════════════════════════════════════════════════════════
    🏢 Plexus Production Environment - Quick Access
    ═══════════════════════════════════════════════════════════
    
    📱 Application URL:
       ${module.compute.load_balancer_url}
    
    🔒 Security Notes:
       - Server IPs are hidden (use 'terraform output web_server_ips')
       - Database connection info is sensitive
       - Deletion protection is ENABLED
    
    💻 Infrastructure:
       - Web Servers: ${var.web_server_count}x ${var.machine_type}
       - Database: ${var.database_tier}
       - Backups: ${var.enable_database_backups ? "Enabled" : "Disabled"}
    
    ${var.enable_database ? "🗄️  Database: Use 'terraform output database_connection_command' to see connection details" : ""}
    
    ${var.enable_storage ? "📦 Storage Buckets: ${length(module.storage[0].bucket_names)} buckets created" : ""}
    
    ═══════════════════════════════════════════════════════════
    
    ⚠️  Production Warnings:
    - Always review terraform plan before applying
    - Database deletion protection is ENABLED
    - Storage buckets are protected from force destruction
    - Changes may cause downtime - plan maintenance windows
    
    ═══════════════════════════════════════════════════════════
  EOT
}
