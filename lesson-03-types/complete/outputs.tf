# Comprehensive outputs for production infrastructure

# =============================================================================
# Project & Environment
# =============================================================================

output "deployment_info" {
  value = {
    project_id   = var.project_id
    project_name = var.project_name
    region       = var.region
    environment  = var.environment
    deployed_at  = timestamp()
  }
  description = "Deployment information"
}

# =============================================================================
# Discovered Data Sources
# =============================================================================

output "discovered_zones" {
  value       = data.google_compute_zones.available.names
  description = "Available zones discovered in region"
}

output "os_images_used" {
  value = {
    for key, image in data.google_compute_image.os_images :
    key => {
      name   = image.name
      family = image.family
    }
  }
  description = "OS images used for instances"
}

output "project_number" {
  value       = data.google_project.current.number
  description = "GCP project number"
}

# =============================================================================
# Network Infrastructure
# =============================================================================

output "vpc_info" {
  value = {
    name      = google_compute_network.main.name
    id        = google_compute_network.main.id
    self_link = google_compute_network.main.self_link
  }
  description = "VPC network information"
}

output "subnet_details" {
  value = {
    for key, subnet in google_compute_subnetwork.subnets :
    key => {
      name       = subnet.name
      cidr       = subnet.ip_cidr_range
      region     = subnet.region
      gateway_ip = subnet.gateway_address
    }
  }
  description = "Subnet configurations"
}

# =============================================================================
# Web Tier Outputs (using splat)
# =============================================================================

output "web_servers" {
  value = {
    count = length(google_compute_instance.web_servers)
    names = google_compute_instance.web_servers[*].name
    zones = google_compute_instance.web_servers[*].zone
    internal_ips = google_compute_instance.web_servers[*].network_interface[0].network_ip
    external_ips = var.enable_external_ips ? google_compute_instance.web_servers[*].network_interface[0].access_config[0].nat_ip : []
  }
  description = "Web server information"
}

output "web_server_details" {
  value = {
    for idx, instance in google_compute_instance.web_servers :
    instance.name => {
      zone         = instance.zone
      machine_type = instance.machine_type
      internal_ip  = instance.network_interface[0].network_ip
      external_ip  = var.enable_external_ips ? instance.network_interface[0].access_config[0].nat_ip : "none"
      disk_type    = instance.boot_disk[0].initialize_params[0].type
      disk_size    = instance.boot_disk[0].initialize_params[0].size
    }
  }
  description = "Detailed web server configurations"
}

output "web_static_ips" {
  value = var.use_static_ips && var.environment == "production" ? {
    for idx, addr in google_compute_address.web_static_ips :
    "web-${idx}" => addr.address
  } : {}
  description = "Static IPs assigned to web servers"
}

# =============================================================================
# Application Tier Outputs (for_each)
# =============================================================================

output "app_servers" {
  value = {
    for key, instance in google_compute_instance.app_servers :
    key => {
      name        = instance.name
      zone        = instance.zone
      internal_ip = instance.network_interface[0].network_ip
      app_type    = instance.metadata.app_type
      os_family   = instance.boot_disk[0].initialize_params[0].image
    }
  }
  description = "Application server details"
}

output "app_server_ips" {
  value = {
    for key, instance in google_compute_instance.app_servers :
    key => instance.network_interface[0].network_ip
  }
  description = "Application server internal IPs"
}

# =============================================================================
# Database Tier Outputs
# =============================================================================

output "db_servers" {
  value = {
    for key, instance in google_compute_instance.db_servers :
    key => {
      name         = instance.name
      zone         = instance.zone
      machine_type = instance.machine_type
      internal_ip  = instance.network_interface[0].network_ip
      role         = instance.metadata.db_role
      db_type      = instance.metadata.db_type
      disk_size    = instance.boot_disk[0].initialize_params[0].size
      disk_type    = instance.boot_disk[0].initialize_params[0].type
    }
  }
  description = "Database server details"
}

output "db_connection_ips" {
  value = {
    for key, instance in google_compute_instance.db_servers :
    instance.metadata.db_role => instance.network_interface[0].network_ip
  }
  description = "Database IPs by role (primary/replica)"
}

output "db_data_disks" {
  value = var.environment == "production" ? {
    for key, disk in google_compute_disk.db_data_disks :
    key => {
      name = disk.name
      size = disk.size
      type = disk.type
      zone = disk.zone
    }
  } : {}
  description = "Database data disks (production only)"
}

# =============================================================================
# Load Balancer Outputs (conditional)
# =============================================================================

output "load_balancer" {
  value = var.create_load_balancer ? {
    name         = google_compute_instance.load_balancer[0].name
    zone         = google_compute_instance.load_balancer[0].zone
    internal_ip  = google_compute_instance.load_balancer[0].network_interface[0].network_ip
    external_ip  = google_compute_instance.load_balancer[0].network_interface[0].access_config[0].nat_ip
    backend_count = google_compute_instance.load_balancer[0].metadata.backend_count
    backends     = google_compute_instance.load_balancer[0].metadata.backends
  } : null
  description = "Load balancer information"
}

output "lb_static_ip" {
  value       = var.create_load_balancer && var.use_static_ips && var.environment == "production" ? google_compute_address.lb_static_ip[0].address : null
  description = "Load balancer static IP"
}

# =============================================================================
# Monitoring (conditional)
# =============================================================================

output "monitoring" {
  value = var.enable_monitoring ? {
    name        = google_compute_instance.monitoring[0].name
    zone        = google_compute_instance.monitoring[0].zone
    internal_ip = google_compute_instance.monitoring[0].network_interface[0].network_ip
    external_ip = google_compute_instance.monitoring[0].network_interface[0].access_config[0].nat_ip
  } : null
  description = "Monitoring instance information"
}

# =============================================================================
# Resource Inventory - All Servers by Zone
# =============================================================================

output "servers_by_zone" {
  value = {
    for zone in distinct(concat(
      google_compute_instance.web_servers[*].zone,
      values(google_compute_instance.app_servers)[*].zone,
      values(google_compute_instance.db_servers)[*].zone
    )) : zone => {
      web_servers = [
        for instance in google_compute_instance.web_servers :
        instance.name if instance.zone == zone
      ]
      app_servers = [
        for key, instance in google_compute_instance.app_servers :
        instance.name if instance.zone == zone
      ]
      db_servers = [
        for key, instance in google_compute_instance.db_servers :
        instance.name if instance.zone == zone
      ]
      total = length([
        for instance in google_compute_instance.web_servers :
        instance.name if instance.zone == zone
      ]) + length([
        for key, instance in google_compute_instance.app_servers :
        instance.name if instance.zone == zone
      ]) + length([
        for key, instance in google_compute_instance.db_servers :
        instance.name if instance.zone == zone
      ])
    }
  }
  description = "All servers grouped by zone"
}

output "servers_by_tier" {
  value = {
    web         = length(google_compute_instance.web_servers)
    application = length(google_compute_instance.app_servers)
    database    = length(google_compute_instance.db_servers)
    load_balancer = var.create_load_balancer ? 1 : 0
    monitoring  = var.enable_monitoring ? 1 : 0
    total       = length(google_compute_instance.web_servers) + length(google_compute_instance.app_servers) + length(google_compute_instance.db_servers) + (var.create_load_balancer ? 1 : 0) + (var.enable_monitoring ? 1 : 0)
  }
  description = "Server count by tier"
}

# =============================================================================
# Complete Deployment Summary
# =============================================================================

output "deployment_summary" {
  value = {
    # Environment
    environment      = var.environment
    region           = var.region
    zones_used       = length(distinct(concat(
      google_compute_instance.web_servers[*].zone,
      values(google_compute_instance.app_servers)[*].zone,
      values(google_compute_instance.db_servers)[*].zone
    )))

    # Network
    vpc_created      = true
    subnets_created  = length(google_compute_subnetwork.subnets)

    # Compute
    web_servers      = length(google_compute_instance.web_servers)
    app_servers      = length(google_compute_instance.app_servers)
    db_servers       = length(google_compute_instance.db_servers)
    total_servers    = length(google_compute_instance.web_servers) + length(google_compute_instance.app_servers) + length(google_compute_instance.db_servers)

    # Storage
    data_disks       = var.attach_data_disks ? length(google_compute_disk.data_disks) : 0
    db_data_disks    = var.environment == "production" ? length(google_compute_disk.db_data_disks) : 0

    # Optional
    load_balancer    = var.create_load_balancer
    monitoring       = var.enable_monitoring
    static_ips       = var.use_static_ips && var.environment == "production"
    external_ips     = var.enable_external_ips

    # Configuration
    machine_types = {
      web_production = var.environment == "production" ? var.production_machine_type : var.dev_machine_type
      db_primary     = var.environment == "production" ? var.db_configs["db-primary"].production_machine_type : var.db_configs["db-primary"].dev_machine_type
    }
  }
  description = "Complete deployment summary"
}

# =============================================================================
# SSH Connection Commands
# =============================================================================

output "ssh_commands" {
  value = merge(
    {
      for idx, instance in google_compute_instance.web_servers :
      instance.name => var.enable_external_ips ? "ssh user@${instance.network_interface[0].access_config[0].nat_ip}" : "# No external IP"
    },
    var.create_load_balancer ? {
      "${google_compute_instance.load_balancer[0].name}" = "ssh user@${google_compute_instance.load_balancer[0].network_interface[0].access_config[0].nat_ip}"
    } : {},
    var.enable_monitoring ? {
      "${google_compute_instance.monitoring[0].name}" = "ssh user@${google_compute_instance.monitoring[0].network_interface[0].access_config[0].nat_ip}"
    } : {}
  )
  description = "SSH commands for instances with external IPs"
}

# =============================================================================
# Deployment Verification
# =============================================================================

output "deployment_complete" {
  value = "✅ Infrastructure deployed successfully at ${timestamp()}"
  depends_on = [
    google_compute_network.main,
    google_compute_subnetwork.subnets,
    google_compute_instance.web_servers,
    google_compute_instance.app_servers,
    google_compute_instance.db_servers
  ]
  description = "Deployment completion confirmation"
}
