# Variables for production-ready infrastructure

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
  default     = "prod-app"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "region" {
  type        = string
  description = "GCP region for deployment"
  default     = "us-west1"
}

variable "environment" {
  type        = string
  description = "Environment name (dev or production)"
  default     = "production"

  validation {
    condition     = contains(["dev", "production"], var.environment)
    error_message = "Environment must be either 'dev' or 'production'."
  }
}

# Network Configuration
variable "subnet_configs" {
  type = map(object({
    cidr             = string
    enable_secondary = bool
  }))
  description = "Subnet configurations for different tiers"
  default = {
    frontend = {
      cidr             = "10.0.1.0/24"
      enable_secondary = false
    }
    application = {
      cidr             = "10.0.2.0/24"
      enable_secondary = true
    }
    database = {
      cidr             = "10.0.3.0/24"
      enable_secondary = false
    }
    management = {
      cidr             = "10.0.4.0/24"
      enable_secondary = false
    }
  }
}

variable "firewall_rules" {
  type = list(object({
    protocol = string
    ports    = list(string)
  }))
  description = "Firewall rules for ingress traffic"
  default = [
    {
      protocol = "tcp"
      ports    = ["80", "443"]
    },
    {
      protocol = "tcp"
      ports    = ["22"]
    }
  ]
}

variable "allowed_ip_ranges" {
  type        = list(string)
  description = "Allowed IP ranges for firewall rules"
  default     = ["0.0.0.0/0"]
}

# Web Tier Configuration
variable "web_server_count" {
  type        = number
  description = "Number of web servers in production"
  default     = 3

  validation {
    condition     = var.web_server_count >= 1 && var.web_server_count <= 10
    error_message = "Web server count must be between 1 and 10."
  }
}

variable "production_machine_type" {
  type        = string
  description = "Machine type for production servers"
  default     = "e2-medium"
}

variable "dev_machine_type" {
  type        = string
  description = "Machine type for dev servers"
  default     = "e2-micro"
}

variable "enable_external_ips" {
  type        = bool
  description = "Whether to assign external IPs to web servers"
  default     = true
}

variable "use_static_ips" {
  type        = bool
  description = "Whether to use static IPs in production"
  default     = true
}

variable "attach_data_disks" {
  type        = bool
  description = "Whether to attach data disks to web servers"
  default     = true
}

variable "data_disk_size_gb" {
  type        = number
  description = "Size of data disks in GB"
  default     = 100

  validation {
    condition     = var.data_disk_size_gb >= 10 && var.data_disk_size_gb <= 1000
    error_message = "Data disk size must be between 10 and 1000 GB."
  }
}

# Application Tier Configuration
variable "app_server_configs" {
  type = map(object({
    machine_type = string
    zone         = string
    disk_size    = number
    os_family    = string
    app_type     = string
  }))
  description = "Application server configurations"
  default = {
    "app-api" = {
      machine_type = "e2-medium"
      zone         = "us-west1-a"
      disk_size    = 50
      os_family    = "debian-11"
      app_type     = "api"
    }
    "app-worker" = {
      machine_type = "e2-medium"
      zone         = "us-west1-b"
      disk_size    = 50
      os_family    = "ubuntu-2204-lts"
      app_type     = "worker"
    }
  }
}

# Database Tier Configuration
variable "db_configs" {
  type = map(object({
    role                     = string
    db_type                  = string
    zone                     = string
    production_machine_type  = string
    dev_machine_type         = string
    production_disk_size     = number
    dev_disk_size            = number
    num_data_disks           = number
    data_disk_size_gb        = number
  }))
  description = "Database server configurations"
  default = {
    "db-primary" = {
      role                    = "primary"
      db_type                 = "postgresql"
      zone                    = "us-west1-a"
      production_machine_type = "e2-standard-4"
      dev_machine_type        = "e2-micro"
      production_disk_size    = 200
      dev_disk_size           = 20
      num_data_disks          = 2
      data_disk_size_gb       = 500
    }
    "db-replica" = {
      role                    = "replica"
      db_type                 = "postgresql"
      zone                    = "us-west1-b"
      production_machine_type = "e2-standard-4"
      dev_machine_type        = "e2-micro"
      production_disk_size    = 200
      dev_disk_size           = 20
      num_data_disks          = 2
      data_disk_size_gb       = 500
    }
  }
}

# Optional Components
variable "create_load_balancer" {
  type        = bool
  description = "Whether to create load balancer"
  default     = true
}

variable "enable_monitoring" {
  type        = bool
  description = "Whether to create monitoring instance"
  default     = true
}

# Common Labels
variable "common_labels" {
  type        = map(string)
  description = "Common labels applied to all resources"
  default = {
    managed_by = "terraform"
    project    = "prod-app"
  }
}

# Service Account
variable "service_account_email" {
  type        = string
  description = "Service account email for instances"
  default     = ""
}
