# Compute Module - Variables
# Purpose: Define inputs for web servers and load balancer

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-west1"
}

variable "zone" {
  description = "GCP zone for compute instances"
  type        = string
  default     = "us-west1-a"
}

variable "instance_count" {
  description = "Number of web server instances to create"
  type        = number
  default     = 2
  
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "machine_type" {
  description = "Machine type for web servers"
  type        = string
  default     = "e2-micro"
}

variable "subnet_self_link" {
  description = "Self-link of the subnet for instances"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "tags" {
  description = "Network tags for instances"
  type        = list(string)
  default     = ["web-server", "http-server"]
}

variable "enable_load_balancer" {
  description = "Whether to create a load balancer"
  type        = bool
  default     = true
}

variable "app_name" {
  description = "Application name for resource naming"
  type        = string
  default     = "plexus-app"
}
