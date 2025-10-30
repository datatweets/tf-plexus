# Compute Module - Input Variables

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "zone" {
  description = "GCP zone for compute instances"
  type        = string
}

variable "instance_count" {
  description = "Number of web server instances to create"
  type        = number
  default     = 2
  
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "machine_type" {
  description = "Machine type for instances"
  type        = string
  default     = "e2-micro"
}

variable "instance_name_prefix" {
  description = "Prefix for instance names"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where instances will be created"
  type        = string
}

variable "network_tags" {
  description = "Network tags for instances"
  type        = list(string)
  default     = ["web-server"]
}

variable "enable_load_balancer" {
  description = "Whether to create a load balancer"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Environment name"
  type        = string
}
