# Networking Module - Main Configuration
# Purpose: Create VPC, subnets, and firewall rules for Plexus infrastructure

# VPC Network
# This is the foundation of our network infrastructure
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false # We'll create custom subnets
  project                 = var.project_id
  
  description = "VPC network for ${var.environment} environment"
}

# Subnets
# Using for_each to create multiple subnets from a map
# This demonstrates advanced Terraform patterns from Lesson 2
resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets
  
  name          = "${var.vpc_name}-${each.key}-subnet"
  ip_cidr_range = each.value.ip_cidr_range
  region        = each.value.region
  network       = google_compute_network.vpc.id
  project       = var.project_id
  
  description = each.value.description
  
  # Enable private Google access for secure communication
  private_ip_google_access = true
  
  # Add labels for better resource management
  # This follows GCP best practices
  # labels = {
  #   environment = var.environment
  #   subnet_type = each.key
  #   managed_by  = "terraform"
  # }
}

# Firewall Rules
# Using for_each with dynamic blocks - advanced pattern from Lesson 3
# This allows flexible firewall rule creation from variables
resource "google_compute_firewall" "rules" {
  for_each = var.firewall_rules
  
  name        = "${var.vpc_name}-${each.key}"
  network     = google_compute_network.vpc.name
  project     = var.project_id
  description = each.value.description
  priority    = each.value.priority
  direction   = each.value.direction
  
  # Dynamic block for allow rules
  # This demonstrates the power of dynamic blocks
  # Instead of hardcoding rules, we generate them from data
  dynamic "allow" {
    for_each = each.value.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }
  
  source_ranges = each.value.source_ranges
  target_tags   = each.value.target_tags
  
  # Explicit dependency to ensure VPC is created first
  # This demonstrates depends_on from Lesson 2
  depends_on = [google_compute_network.vpc]
}

# Cloud Router (for NAT if needed in future)
# Currently commented out but shows how to extend
# resource "google_compute_router" "router" {
#   name    = "${var.vpc_name}-router"
#   region  = var.subnets["web"].region
#   network = google_compute_network.vpc.id
#   project = var.project_id
# }

# Cloud NAT (for private instances to reach internet)
# resource "google_compute_router_nat" "nat" {
#   name                               = "${var.vpc_name}-nat"
#   router                             = google_compute_router.router.name
#   region                             = google_compute_router.router.region
#   nat_ip_allocate_option             = "AUTO_ONLY"
#   source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
#   
#   log_config {
#     enable = true
#     filter = "ERRORS_ONLY"
#   }
# }
