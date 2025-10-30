# Outputs demonstrating different data types

# ============================================
# String Outputs
# ============================================

output "instance_name" {
  value       = google_compute_instance.demo_server.name
  description = "Name of the demo server (string type)"
}

output "instance_zone" {
  value       = google_compute_instance.demo_server.zone
  description = "Zone where the server is deployed (string type)"
}

output "instance_self_link" {
  value       = google_compute_instance.demo_server.self_link
  description = "Self link of the instance (string type)"
}

# ============================================
# Number Outputs
# ============================================

output "disk_count" {
  value       = length(var.disk_configs)
  description = "Number of data disks created (number type)"
}

output "firewall_rule_count" {
  value       = length(var.allowed_ports)
  description = "Number of firewall rules created (number type)"
}

output "total_disk_size_gb" {
  value       = sum([for disk in var.disk_configs : disk.size])
  description = "Total size of all data disks in GB (number type)"
}

# ============================================
# Bool Outputs
# ============================================

output "has_external_ip" {
  value       = var.assign_external_ip
  description = "Whether instance has external IP (bool type)"
}

output "monitoring_enabled" {
  value       = var.enable_monitoring
  description = "Whether monitoring is enabled (bool type)"
}

output "ip_forwarding_enabled" {
  value       = var.enable_ip_forwarding
  description = "Whether IP forwarding is enabled (bool type)"
}

# ============================================
# List Outputs
# ============================================

output "disk_names" {
  value       = [for disk in google_compute_disk.data_disks : disk.name]
  description = "List of all data disk names (list of strings)"
}

output "firewall_rule_names" {
  value       = [for fw in google_compute_firewall.allow_ports : fw.name]
  description = "List of all firewall rule names (list of strings)"
}

output "allowed_ports" {
  value       = var.allowed_ports
  description = "List of allowed ports (list of numbers)"
}

output "configured_zones" {
  value       = var.availability_zones
  description = "List of availability zones (list of strings)"
}

# ============================================
# Map Outputs
# ============================================

output "disk_configurations" {
  value       = var.disk_configs
  description = "Map of disk configurations (map of objects)"
}

output "disk_details" {
  value = {
    for name, disk in google_compute_disk.data_disks : name => {
      id   = disk.id
      size = disk.size
      type = disk.type
      zone = disk.zone
    }
  }
  description = "Detailed map of all disks (map of objects)"
}

output "regional_ip_addresses" {
  value = {
    for name, ip in google_compute_address.regional_ips : name => ip.address
  }
  description = "Map of regional IP addresses (map of strings)"
}

output "machine_type_mapping" {
  value       = var.machine_types
  description = "Environment to machine type mapping (map of strings)"
}

# ============================================
# Object/Complex Outputs
# ============================================

output "server_summary" {
  value = {
    name              = google_compute_instance.demo_server.name
    zone              = google_compute_instance.demo_server.zone
    machine_type      = google_compute_instance.demo_server.machine_type
    has_external_ip   = var.assign_external_ip
    external_ip       = var.assign_external_ip ? google_compute_instance.demo_server.network_interface[0].access_config[0].nat_ip : null
    internal_ip       = google_compute_instance.demo_server.network_interface[0].network_ip
    boot_disk_size_gb = google_compute_instance.demo_server.boot_disk[0].initialize_params[0].size
    labels            = google_compute_instance.demo_server.labels
    tags              = google_compute_instance.demo_server.tags
  }
  description = "Complete server summary (structured object)"
}

output "infrastructure_summary" {
  value = {
    environment = var.environment
    project_id  = var.project_id
    zone        = var.zone
    resources = {
      instances      = 1 + (var.create_typed_server ? 1 : 0)
      disks          = length(var.disk_configs)
      firewall_rules = length(var.allowed_ports)
      ip_addresses   = length(local.nested_map[var.region_group])
    }
    configurations = {
      external_ip_enabled = var.assign_external_ip
      monitoring_enabled  = var.enable_monitoring
      disk_configs        = var.disk_configs
    }
  }
  description = "Complete infrastructure summary (nested object)"
}

# ============================================
# Nested Collection Outputs
# ============================================

output "regional_zones" {
  value       = var.regional_zones
  description = "Map of region groups to zones (map of lists)"
}

output "active_region_zones" {
  value       = local.nested_map[var.region_group]
  description = "Active zones for selected region group (list)"
}

# ============================================
# Conditional Outputs
# ============================================

output "typed_server_details" {
  value = var.create_typed_server ? {
    name    = google_compute_instance.typed_server[0].name
    zone    = google_compute_instance.typed_server[0].zone
    regions = var.typed_config.regions
  } : null
  description = "Typed server details if created, otherwise null"
}

# ============================================
# Formatted Outputs
# ============================================

output "connection_command" {
  value       = var.assign_external_ip ? "gcloud compute ssh ${google_compute_instance.demo_server.name} --zone=${google_compute_instance.demo_server.zone}" : "Instance has no external IP - use IAP tunneling"
  description = "Command to connect to the instance (formatted string)"
}

output "resource_labels" {
  value = merge(
    {
      environment = var.environment
      managed_by  = "terraform"
      team        = "platform"
    },
    {
      created_date = formatdate("YYYY-MM-DD", timestamp())
    }
  )
  description = "Common resource labels (merged map)"
}

# ============================================
# Statistics Outputs
# ============================================

output "type_statistics" {
  value = {
    total_variables_used = 20
    string_vars          = 4
    number_vars          = 3
    bool_vars            = 4
    list_vars            = 3
    map_vars             = 3
    object_vars          = 3
    types_demonstrated   = ["string", "number", "bool", "list", "map", "object", "nested_map"]
  }
  description = "Statistics about types used in this example (object)"
}
