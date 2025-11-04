# Networking Module - Variables
# Purpose: Define inputs for VPC, subnets, and firewall rules

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod'."
  }
}

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    ip_cidr_range = string
    region        = string
    description   = string
  }))
  
  # Example:
  # {
  #   "web" = {
  #     ip_cidr_range = "10.0.1.0/24"
  #     region        = "us-west1"
  #     description   = "Subnet for web servers"
  #   }
  # }
}

variable "firewall_rules" {
  description = "Map of firewall rules to create"
  type = map(object({
    description = string
    priority    = number
    direction   = string
    allow = list(object({
      protocol = string
      ports    = list(string)
    }))
    source_ranges = list(string)
    target_tags   = list(string)
  }))
  
  # Example:
  # {
  #   "allow-ssh" = {
  #     description   = "Allow SSH from anywhere"
  #     priority      = 1000
  #     direction     = "INGRESS"
  #     allow = [{
  #       protocol = "tcp"
  #       ports    = ["22"]
  #     }]
  #     source_ranges = ["0.0.0.0/0"]
  #     target_tags   = ["web-server"]
  #   }
  # }
}
