# Development Environment - Variables
# Purpose: Define all inputs for the dev environment

variable "project_id" {
  description = "GCP project ID"
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

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# Networking Variables
variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "plexus-dev-vpc"
}

# Compute Variables
variable "web_server_count" {
  description = "Number of web servers"
  type        = number
  default     = 2 # Smaller for dev
}

variable "machine_type" {
  description = "Machine type for web servers"
  type        = string
  default     = "e2-micro" # Small for dev
}

# Database Variables
variable "database_tier" {
  description = "Database instance tier"
  type        = string
  default     = "db-f1-micro" # Smallest for dev
}

variable "enable_database_backups" {
  description = "Enable automated database backups"
  type        = bool
  default     = false # Disabled for dev to save costs
}

# Feature Flags
variable "enable_load_balancer" {
  description = "Enable load balancer"
  type        = bool
  default     = true
}

variable "enable_database" {
  description = "Enable database creation"
  type        = bool
  default     = true
}

variable "enable_storage" {
  description = "Enable storage buckets"
  type        = bool
  default     = true
}
