# Networking Module - Main Resources
# Purpose: Create VPC, subnets, and firewall rules

# ══════════════════════════════════════════════════════════════════════════════
# TODO #1: Create VPC Network
# ══════════════════════════════════════════════════════════════════════════════
# LEARNING OBJECTIVES:
# - Understand google_compute_network resource
# - Learn about auto_create_subnetworks setting
# - Practice using variables
# 
# HINTS:
# - Use resource type: google_compute_network
# - Resource name should be: "vpc"
# - Set name = var.vpc_name
# - Set project = var.project_id
# - Set auto_create_subnetworks = false (we'll create custom subnets)
# 
# DOCUMENTATION:
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network
# 
# VALIDATION:
# After applying, run: gcloud compute networks describe <vpc-name>
# ══════════════════════════════════════════════════════════════════════════════

resource "google_compute_network" "vpc" {
  # YOUR CODE HERE
  # Remove this comment and implement the resource
}

# ══════════════════════════════════════════════════════════════════════════════
# TODO #2: Create Subnets using for_each
# ══════════════════════════════════════════════════════════════════════════════
# LEARNING OBJECTIVES:
# - Master for_each meta-argument (Lesson 2)
# - Work with map variables
# - Reference resources
# 
# HINTS:
# - Use resource type: google_compute_subnetwork
# - Resource name should be: "subnets"
# - Use for_each = var.subnets to iterate over the map
# - Access map key with: each.key
# - Access map values with: each.value.cidr_range, each.value.description
# - Reference VPC with: google_compute_network.vpc.id
# 
# DOCUMENTATION:
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork
# https://developer.hashicorp.com/terraform/language/meta-arguments/for_each
# 
# VALIDATION:
# After applying, run: gcloud compute networks subnets list --network=<vpc-name>
# ══════════════════════════════════════════════════════════════════════════════

resource "google_compute_subnetwork" "subnets" {
  # YOUR CODE HERE
  # Implement for_each loop to create multiple subnets
  
  # for_each = ?
  
  # name          = ?
  # ip_cidr_range = ?
  # region        = ?
  # network       = ?
  # description   = ?
  # project       = ?
}

# ══════════════════════════════════════════════════════════════════════════════
# TODO #3: Create Firewall Rules with Dynamic Blocks
# ══════════════════════════════════════════════════════════════════════════════
# LEARNING OBJECTIVES:
# - Master dynamic blocks (Lesson 3)
# - Combine for_each with dynamic blocks
# - Understand firewall rule structure
# 
# HINTS:
# - Use resource type: google_compute_firewall
# - Resource name should be: "rules"
# - Use for_each = var.firewall_rules
# - Create a dynamic "allow" block that iterates over each.value.allow
# - The dynamic block syntax is:
#     dynamic "allow" {
#       for_each = each.value.allow
#       content {
#         protocol = allow.value.protocol
#         ports    = allow.value.ports
#       }
#     }
# 
# DOCUMENTATION:
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall
# https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks
# 
# VALIDATION:
# After applying, run: gcloud compute firewall-rules list --filter="network:<vpc-name>"
# ══════════════════════════════════════════════════════════════════════════════

resource "google_compute_firewall" "rules" {
  # YOUR CODE HERE
  # Implement firewall rules with dynamic allow blocks
  
  # for_each = ?
  
  # name          = ?
  # network       = ?
  # project       = ?
  # description   = ?
  # priority      = ?
  # direction     = ?
  # source_ranges = ?
  # target_tags   = ?
  
  # dynamic "allow" {
  #   for_each = ?
  #   content {
  #     protocol = ?
  #     ports    = ?
  #   }
  # }
}

# ══════════════════════════════════════════════════════════════════════════════
# CHECKPOINT: Networking Module Complete!
# ══════════════════════════════════════════════════════════════════════════════
# 
# Once you've implemented all TODOs above, you should be able to:
# ✓ Create a custom VPC network
# ✓ Create multiple subnets using for_each
# ✓ Create firewall rules with dynamic allow blocks
# 
# Test your understanding:
# 1. What happens if you add a new subnet to the subnets variable?
# 2. How would you add a new protocol to a firewall rule?
# 3. Why use for_each instead of count for these resources?
# 
# Next Steps:
# 1. Complete outputs.tf to expose resource information
# 2. Move to compute module
# 
# ══════════════════════════════════════════════════════════════════════════════
