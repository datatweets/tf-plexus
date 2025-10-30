# Outputs for data source example

# Outputs from data sources
output "discovered_zones" {
  value       = data.google_compute_zones.available.names
  description = "All available zones discovered in the region"
}

output "zone_count" {
  value       = length(data.google_compute_zones.available.names)
  description = "Number of available zones"
}

output "debian_image_info" {
  value = {
    name        = data.google_compute_image.debian.name
    family      = data.google_compute_image.debian.family
    description = data.google_compute_image.debian.description
    self_link   = data.google_compute_image.debian.self_link
  }
  description = "Information about the latest Debian image"
}

output "ubuntu_image_info" {
  value = {
    name        = data.google_compute_image.ubuntu.name
    family      = data.google_compute_image.ubuntu.family
    description = data.google_compute_image.ubuntu.description
    self_link   = data.google_compute_image.ubuntu.self_link
  }
  description = "Information about the latest Ubuntu image"
}

output "project_info" {
  value = {
    project_id     = data.google_project.current.project_id
    project_number = data.google_project.current.number
    project_name   = data.google_project.current.name
  }
  description = "Current GCP project information"
}

output "default_network_info" {
  value = {
    name      = data.google_compute_network.default.name
    id        = data.google_compute_network.default.id
    self_link = data.google_compute_network.default.self_link
  }
  description = "Default network information"
}

# Outputs from created resources
output "server_distribution" {
  value = {
    for idx, instance in google_compute_instance.servers : instance.name => {
      zone        = instance.zone
      internal_ip = instance.network_interface[0].network_ip
      external_ip = instance.network_interface[0].access_config[0].nat_ip
    }
  }
  description = "Distribution of servers across discovered zones"
}

output "zone_distribution" {
  value = {
    for zone in data.google_compute_zones.available.names :
    zone => length([for instance in google_compute_instance.servers : instance if instance.zone == zone])
  }
  description = "Number of instances per zone"
}

output "all_server_names" {
  value       = [for instance in google_compute_instance.servers : instance.name]
  description = "Names of all created servers"
}

output "all_server_zones" {
  value       = [for instance in google_compute_instance.servers : instance.zone]
  description = "Zones of all created servers"
}

output "ubuntu_server_info" {
  value = var.create_ubuntu_instance ? {
    name        = google_compute_instance.ubuntu_server[0].name
    zone        = google_compute_instance.ubuntu_server[0].zone
    external_ip = google_compute_instance.ubuntu_server[0].network_interface[0].access_config[0].nat_ip
    image       = data.google_compute_image.ubuntu.name
  } : null
  description = "Ubuntu server information (null if not created)"
}

output "data_disk_info" {
  value = var.create_data_disk ? {
    name = google_compute_disk.data[0].name
    zone = google_compute_disk.data[0].zone
    size = google_compute_disk.data[0].size
  } : null
  description = "Data disk information (null if not created)"
}

output "data_source_summary" {
  value = {
    region            = var.region
    zones_discovered  = length(data.google_compute_zones.available.names)
    zones_list        = data.google_compute_zones.available.names
    debian_image      = data.google_compute_image.debian.name
    ubuntu_image      = data.google_compute_image.ubuntu.name
    project_id        = data.google_project.current.project_id
    project_number    = data.google_project.current.number
    network_used      = var.use_existing_network ? var.existing_network_name : "default"
    servers_created   = var.instance_count
    ubuntu_created    = var.create_ubuntu_instance
    data_disk_created = var.create_data_disk
  }
  description = "Summary of all data sources used and resources created"
}
