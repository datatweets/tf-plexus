# Database Module - Variables
# Purpose: Define inputs for Cloud SQL PostgreSQL instance

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "region" {
  description = "GCP region for the database"
  type        = string
  default     = "us-west1"
}

variable "database_name" {
  description = "Name of the database instance"
  type        = string
}

variable "database_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "POSTGRES_15"
}

variable "tier" {
  description = "Machine tier for the database"
  type        = string
  default     = "db-f1-micro" # Smallest tier for dev/testing
  
  # Common tiers:
  # db-f1-micro - 0.6 GB RAM (dev)
  # db-g1-small - 1.7 GB RAM (small prod)
  # db-n1-standard-1 - 3.75 GB RAM (prod)
}

variable "disk_size" {
  description = "Size of the database disk in GB"
  type        = number
  default     = 10
  
  validation {
    condition     = var.disk_size >= 10 && var.disk_size <= 1000
    error_message = "Disk size must be between 10 GB and 1000 GB."
  }
}

variable "enable_backups" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "backup_start_time" {
  description = "Start time for backups in HH:MM format (UTC)"
  type        = string
  default     = "03:00"
}

variable "enable_public_ip" {
  description = "Enable public IP for the database"
  type        = bool
  default     = true # For learning purposes; use false in real production
}

variable "authorized_networks" {
  description = "List of authorized networks for database access"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
  
  # Example:
  # [
  #   {
  #     name  = "office"
  #     value = "203.0.113.0/24"
  #   }
  # ]
}

variable "deletion_protection" {
  description = "Enable deletion protection for the database"
  type        = bool
  default     = false # Set to true for production
}

variable "create_database" {
  description = "Whether to create the default database"
  type        = bool
  default     = true
}

variable "database_user" {
  description = "Database username"
  type        = string
  default     = "plexus_app"
}

variable "database_password" {
  description = "Database password (use secret manager in production)"
  type        = string
  default     = "PlexusDB2025!" # For learning only!
  sensitive   = true
}
