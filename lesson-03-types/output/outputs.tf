# Comprehensive output examples demonstrating various patterns

# =============================================================================
# Basic Outputs - Single Values
# =============================================================================

output "project_id" {
  value       = var.project_id
  description = "The GCP project ID"
}

output "region" {
  value       = var.region
  description = "Deployment region"
}

output "vpc_id" {
  value       = google_compute_network.vpc.id
  description = "VPC network ID"
}

output "vpc_self_link" {
  value       = google_compute_network.vpc.self_link
  description = "VPC self link"
}

# =============================================================================
# Splat Expressions - Extract attribute from all instances
# =============================================================================

output "web_server_names" {
  value       = google_compute_instance.web_servers[*].name
  description = "All web server names using splat [*]"
}

output "web_server_zones" {
  value       = google_compute_instance.web_servers[*].zone
  description = "All web server zones"
}

output "web_server_internal_ips" {
  value       = google_compute_instance.web_servers[*].network_interface[0].network_ip
  description = "All web server internal IPs"
}

output "web_server_external_ips" {
  value       = google_compute_instance.web_servers[*].network_interface[0].access_config[0].nat_ip
  description = "All web server external IPs"
}

output "data_disk_names" {
  value       = google_compute_disk.data_disks[*].name
  description = "All data disk names"
}

# =============================================================================
# For_each Outputs - Map resources
# =============================================================================

output "db_server_details" {
  value = {
    for key, instance in google_compute_instance.db_servers : key => {
      name        = instance.name
      zone        = instance.zone
      internal_ip = instance.network_interface[0].network_ip
      external_ip = instance.network_interface[0].access_config[0].nat_ip
      machine     = instance.machine_type
      db_type     = instance.metadata.db_type
    }
  }
  description = "Complete details of all database servers"
}

output "db_server_ips" {
  value = {
    for key, instance in google_compute_instance.db_servers :
    key => instance.network_interface[0].network_ip
  }
  description = "Database server internal IPs"
}

# Using values() to get list from map
output "db_server_names_list" {
  value       = values(google_compute_instance.db_servers)[*].name
  description = "List of database server names from map"
}

# =============================================================================
# Conditional Outputs - Handle optional resources
# =============================================================================

output "load_balancer_ip" {
  value       = var.create_lb ? google_compute_instance.load_balancer[0].network_interface[0].access_config[0].nat_ip : "not created"
  description = "Load balancer IP (conditional)"
}

output "load_balancer_info" {
  value = var.create_lb ? {
    name        = google_compute_instance.load_balancer[0].name
    zone        = google_compute_instance.load_balancer[0].zone
    external_ip = google_compute_instance.load_balancer[0].network_interface[0].access_config[0].nat_ip
    backend     = google_compute_instance.load_balancer[0].metadata.backend
  } : null
  description = "Load balancer details (null if not created)"
}

# =============================================================================
# Complex For Expressions - Advanced transformations
# =============================================================================

output "server_inventory" {
  value = merge(
    # Web servers
    {
      for idx, instance in google_compute_instance.web_servers : instance.name => {
        type        = "web"
        zone        = instance.zone
        internal_ip = instance.network_interface[0].network_ip
        external_ip = instance.network_interface[0].access_config[0].nat_ip
        index       = idx
      }
    },
    # Database servers
    {
      for key, instance in google_compute_instance.db_servers : instance.name => {
        type        = "database"
        zone        = instance.zone
        internal_ip = instance.network_interface[0].network_ip
        external_ip = instance.network_interface[0].access_config[0].nat_ip
        db_type     = instance.metadata.db_type
      }
    }
  )
  description = "Complete inventory of all servers"
}

output "servers_by_zone" {
  value = {
    for zone in distinct(concat(
      google_compute_instance.web_servers[*].zone,
      values(google_compute_instance.db_servers)[*].zone
    )) : zone => {
      web_servers = [
        for instance in google_compute_instance.web_servers :
        instance.name if instance.zone == zone
      ]
      db_servers = [
        for key, instance in google_compute_instance.db_servers :
        instance.name if instance.zone == zone
      ]
    }
  }
  description = "Servers grouped by zone"
}

output "subnet_cidrs" {
  value = {
    for subnet in google_compute_subnetwork.subnets :
    subnet.name => subnet.ip_cidr_range
  }
  description = "Subnet CIDR blocks"
}

# =============================================================================
# Computed/Calculated Outputs
# =============================================================================

output "total_servers" {
  value       = var.server_count + length(var.db_configs)
  description = "Total number of servers created"
}

output "total_disks" {
  value       = var.server_count
  description = "Total number of data disks"
}

output "deployment_summary" {
  value = {
    project           = var.project_id
    region            = var.region
    environment       = var.environment
    web_servers       = var.server_count
    db_servers        = length(var.db_configs)
    total_servers     = var.server_count + length(var.db_configs)
    load_balancer     = var.create_lb
    zones_used        = distinct(concat(
      google_compute_instance.web_servers[*].zone,
      values(google_compute_instance.db_servers)[*].zone
    ))
    vpc_created       = true
    subnets_created   = length(google_compute_subnetwork.subnets)
  }
  description = "Complete deployment summary"
}

# =============================================================================
# Formatted Outputs - For scripts/automation
# =============================================================================

output "web_servers_json" {
  value = jsonencode([
    for instance in google_compute_instance.web_servers : {
      name = instance.name
      ip   = instance.network_interface[0].access_config[0].nat_ip
    }
  ])
  description = "Web servers in JSON format"
}

output "ansible_inventory" {
  value = templatefile("${path.module}/templates/inventory.tpl", {
    web_servers = google_compute_instance.web_servers
    db_servers  = values(google_compute_instance.db_servers)
  })
  description = "Ansible inventory format"
}

output "ssh_commands" {
  value = [
    for instance in google_compute_instance.web_servers :
    "ssh user@${instance.network_interface[0].access_config[0].nat_ip}"
  ]
  description = "SSH commands for all web servers"
}

# =============================================================================
# Sensitive Outputs - Marked as sensitive
# =============================================================================

output "api_key" {
  value       = var.sensitive_api_key
  sensitive   = true
  description = "API key (marked sensitive, won't show in logs)"
}

output "connection_strings" {
  value = {
    for key, instance in google_compute_instance.db_servers :
    key => "postgresql://user:password@${instance.network_interface[0].network_ip}:5432/db"
  }
  sensitive   = true
  description = "Database connection strings (sensitive)"
}

# =============================================================================
# Depends_on Outputs - Wait for all resources
# =============================================================================

output "deployment_complete" {
  value = "All resources created successfully at ${timestamp()}"
  depends_on = [
    google_compute_instance.web_servers,
    google_compute_instance.db_servers,
    google_compute_disk.data_disks,
    google_compute_network.vpc,
    google_compute_subnetwork.subnets
  ]
  description = "Deployment completion message"
}
