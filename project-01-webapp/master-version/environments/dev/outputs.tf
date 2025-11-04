# Development Environment - Outputs
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
}

output "database_ip" {
  description = "Database public IP address"
  value       = var.enable_database ? module.database[0].public_ip_address : "Database not enabled"
}

output "database_connection_command" {
  description = "Command to connect to the database"
  value       = var.enable_database ? module.database[0].connection_command : "Database not enabled"
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
      ip_address    = module.database[0].public_ip_address
      version       = module.database[0].database_version
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
  }
}

# Quick Access Information
output "quick_access" {
  description = "Quick access URLs and commands"
  value = <<-EOT
    
    ═══════════════════════════════════════════════════════════
    🚀 Plexus Dev Environment - Quick Access
    ═══════════════════════════════════════════════════════════
    
    📱 Application URL:
       ${module.compute.load_balancer_url}
    
    💻 Web Servers:
       ${join("\n       ", [for ip in module.compute.instance_public_ips : "http://${ip}"])}
    
    ${var.enable_database ? "🗄️  Database Connection:\n       ${module.database[0].connection_command}\n       Password: PlexusDB2025!" : "🗄️  Database: Not enabled"}
    
    ${var.enable_storage ? "📦 Storage Buckets:\n       ${join("\n       ", [for name in values(module.storage[0].bucket_names) : "gs://${name}"])}" : "📦 Storage: Not enabled"}
    
    ═══════════════════════════════════════════════════════════
    
    💡 Tips:
    - Wait 2-3 minutes after deployment for services to start
    - Database creation takes 10-15 minutes
    - Check health: curl ${module.compute.load_balancer_url}/health
    
    ═══════════════════════════════════════════════════════════
  EOT
}
