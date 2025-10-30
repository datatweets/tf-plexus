# Networking Module - Input Variables
# These variables define the configuration for VPC and networking resources

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
}

# Map of subnets to create
# Each subnet needs: name, cidr_range, description
variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    cidr_range  = string
    description = string
  }))
  
  # Example structure:
  # {
  #   "web-subnet" = {
  #     cidr_range  = "10.0.1.0/24"
  #     description = "Subnet for web servers"
  #   }
  # }
}

# Map of firewall rules
# Each rule needs: priority, direction, allowed protocols/ports, source_ranges, target_tags
variable "firewall_rules" {
  description = "Map of firewall rules to create"
  type = map(object({
    priority      = number
    direction     = string
    description   = string
    source_ranges = list(string)
    target_tags   = list(string)
    allow = list(object({
      protocol = string
      ports    = list(string)
    }))
  }))
  
  # Example structure:
  # {
  #   "allow-ssh" = {
  #     priority      = 1000
  #     direction     = "INGRESS"
  #     description   = "Allow SSH from anywhere"
  #     source_ranges = ["0.0.0.0/0"]
  #     target_tags   = ["web-server"]
  #     allow = [{
  #       protocol = "tcp"
  #       ports    = ["22"]
  #     }]
  #   }
  # }
  
  validation {
    condition = alltrue([
      for rule in var.firewall_rules : rule.priority >= 0 && rule.priority <= 65535
    ])
    error_message = "Firewall rule priority must be between 0 and 65535."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}
