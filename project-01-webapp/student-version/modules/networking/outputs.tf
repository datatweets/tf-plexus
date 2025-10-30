# Networking Module - Outputs
# Purpose: Export important information for other modules to use

# ══════════════════════════════════════════════════════════════════════════════
# TODO #4: Create VPC Outputs
# ══════════════════════════════════════════════════════════════════════════════
# LEARNING OBJECTIVES:
# - Understand output blocks (Lesson 1)
# - Learn to reference resource attributes
# - Practice exporting module information
# 
# HINTS:
# - Use output blocks to export vpc_name, vpc_id, vpc_self_link
# - Reference the VPC resource: google_compute_network.vpc
# - Common attributes: name, id, self_link
# 
# EXAMPLE:
# output "vpc_name" {
#   description = "Name of the VPC network"
#   value       = google_compute_network.vpc.name
# }
# ══════════════════════════════════════════════════════════════════════════════

output "vpc_name" {
  description = "Name of the VPC network"
  value       = # YOUR CODE: Reference VPC name
}

output "vpc_id" {
  description = "ID of the VPC network"
  value       = # YOUR CODE: Reference VPC id
}

output "vpc_self_link" {
  description = "Self-link of the VPC network"
  value       = # YOUR CODE: Reference VPC self_link
}

# ══════════════════════════════════════════════════════════════════════════════
# TODO #5: Create Subnet Outputs using for Expression
# ══════════════════════════════════════════════════════════════════════════════
# LEARNING OBJECTIVES:
# - Master for expressions (Lesson 3)
# - Work with resource maps from for_each
# - Transform resource collections into useful outputs
# 
# HINTS:
# - When you use for_each, Terraform creates a map of resources
# - Access with: google_compute_subnetwork.subnets[key].attribute
# - Use for expression to transform: { for k, v in resource : k => v.attribute }
# 
# EXAMPLE:
# output "subnet_ids" {
#   description = "Map of subnet names to IDs"
#   value = {
#     for subnet_name, subnet in google_compute_subnetwork.subnets :
#     subnet_name => subnet.id
#   }
# }
# ══════════════════════════════════════════════════════════════════════════════

output "subnet_ids" {
  description = "Map of subnet names to subnet IDs"
  value = {
    # YOUR CODE: Use for expression to create map of subnet names to IDs
  }
}

output "subnet_self_links" {
  description = "Map of subnet names to self-links"
  value = {
    # YOUR CODE: Use for expression to create map of subnet names to self_links
  }
}

output "subnet_names" {
  description = "Map of subnet keys to names"
  value = {
    # YOUR CODE: Use for expression to create map of subnet keys to names
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# TODO #6: Create Summary Output
# ══════════════════════════════════════════════════════════════════════════════
# LEARNING OBJECTIVES:
# - Create complex output objects
# - Combine multiple resource attributes
# - Provide useful summary information
# 
# HINTS:
# - Create an object with vpc_name, subnet_count, and subnet_names
# - Use length() function to count subnets
# - Use keys() function to get subnet names
# 
# EXAMPLE:
# output "network_info" {
#   description = "Summary of network configuration"
#   value = {
#     vpc_name      = google_compute_network.vpc.name
#     vpc_id        = google_compute_network.vpc.id
#     subnet_count  = length(google_compute_subnetwork.subnets)
#     subnet_names  = keys(google_compute_subnetwork.subnets)
#   }
# }
# ══════════════════════════════════════════════════════════════════════════════

output "network_info" {
  description = "Summary of network configuration"
  value = {
    # YOUR CODE: Create summary object with VPC and subnet information
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# CHECKPOINT: Networking Outputs Complete!
# ══════════════════════════════════════════════════════════════════════════════
# 
# Once implemented, these outputs will:
# ✓ Allow other modules to reference your VPC
# ✓ Provide subnet information for compute resources
# ✓ Give a clear summary of the network configuration
# 
# Test your understanding:
# 1. Why do we output self_link instead of just ID?
# 2. How would you add firewall rule outputs?
# 3. What's the benefit of the network_info summary output?
# 
# Next Steps:
# 1. Test this module independently
# 2. Move to compute module
# 
# ══════════════════════════════════════════════════════════════════════════════
