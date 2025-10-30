# Variables demonstrating Terraform types

# ============================================
# String Type Variables
# ============================================

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "instance_name" {
  type        = string
  description = "Name of the compute instance"
  default     = "types-demo-server"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.instance_name))
    error_message = "Instance name must start with a letter, contain only lowercase letters, numbers, and hyphens, and be up to 63 characters."
  }
}

variable "zone" {
  type        = string
  description = "GCP zone for resources"
  default     = "us-west1-a"
}

variable "environment" {
  type        = string
  description = "Environment name (dev or prod)"
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod'."
  }
}

# ============================================
# Number Type Variables
# ============================================

variable "disk_size" {
  type        = number
  description = "Boot disk size in GB"
  default     = 20

  validation {
    condition     = var.disk_size >= 10 && var.disk_size <= 1000
    error_message = "Disk size must be between 10 and 1000 GB."
  }
}

variable "instance_count" {
  type        = number
  description = "Number of instances to create"
  default     = 1

  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

# ============================================
# Bool Type Variables
# ============================================

variable "assign_external_ip" {
  type        = bool
  description = "Whether to assign an external IP to the instance"
  default     = true
}

variable "enable_monitoring" {
  type        = bool
  description = "Enable monitoring for the instance"
  default     = false
}

variable "enable_ip_forwarding" {
  type        = bool
  description = "Enable IP forwarding on the instance"
  default     = false
}

variable "create_typed_server" {
  type        = bool
  description = "Whether to create the typed server example"
  default     = true
}

# ============================================
# List Type Variables
# ============================================

variable "allowed_ports" {
  type        = list(number)
  description = "List of ports to allow in firewall rules"
  default     = [80, 443, 8080]

  validation {
    condition = alltrue([
      for port in var.allowed_ports : port > 0 && port <= 65535
    ])
    error_message = "All ports must be between 1 and 65535."
  }
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
  default     = ["us-west1-a", "us-west1-b", "us-west1-c"]
}

variable "allowed_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks allowed to access resources"
  default     = ["0.0.0.0/0"]
}

# ============================================
# Map Type Variables
# ============================================

variable "disk_configs" {
  type = map(object({
    type = string
    size = number
  }))
  description = "Map of disk configurations"
  default = {
    small-disk = {
      type = "pd-standard"
      size = 10
    }
    medium-disk = {
      type = "pd-balanced"
      size = 50
    }
    large-disk = {
      type = "pd-ssd"
      size = 100
    }
  }
}

variable "machine_types" {
  type        = map(string)
  description = "Map of environment to machine type"
  default = {
    dev  = "e2-micro"
    prod = "e2-standard-4"
  }
}

variable "region_names" {
  type        = map(string)
  description = "Map of region code to full name"
  default = {
    us-west1 = "Oregon"
    us-west2 = "Los Angeles"
    us-east1 = "South Carolina"
  }
}

# ============================================
# Object Type Variables
# ============================================

variable "typed_config" {
  type = object({
    name     = string
    location = string
    regions  = list(string)
  })
  description = "Structured configuration with strict type checking"
  default = {
    name     = "production-server"
    location = "US"
    regions  = ["us-west1", "us-east1"]
  }

  validation {
    condition     = length(var.typed_config.regions) > 0
    error_message = "At least one region must be specified."
  }
}

variable "server_specs" {
  type = object({
    cpu_count    = number
    memory_gb    = number
    disk_size_gb = number
    os_image     = string
  })
  description = "Server specifications"
  default = {
    cpu_count    = 2
    memory_gb    = 8
    disk_size_gb = 50
    os_image     = "debian-cloud/debian-11"
  }
}

# ============================================
# Nested Map Type Variables
# ============================================

variable "regional_zones" {
  type        = map(list(string))
  description = "Map of regions to their availability zones"
  default = {
    americas = ["us-west1", "us-west2", "us-central1"]
    europe   = ["europe-west1", "europe-west2", "europe-north1"]
    apac     = ["asia-south1", "asia-southeast1", "asia-east1"]
  }
}

variable "region_group" {
  type        = string
  description = "Region group to use (americas, europe, or apac)"
  default     = "americas"

  validation {
    condition     = contains(["americas", "europe", "apac"], var.region_group)
    error_message = "Region group must be one of: americas, europe, apac."
  }
}

# ============================================
# Complex Nested Type Variables
# ============================================

variable "environment_configs" {
  type = map(object({
    machine_type = string
    disk_size    = number
    auto_scaling = object({
      min_replicas = number
      max_replicas = number
    })
    labels = map(string)
  }))
  description = "Complex nested configuration per environment"
  default = {
    dev = {
      machine_type = "e2-micro"
      disk_size    = 20
      auto_scaling = {
        min_replicas = 1
        max_replicas = 2
      }
      labels = {
        tier        = "development"
        cost_center = "engineering"
      }
    }
    prod = {
      machine_type = "e2-standard-4"
      disk_size    = 100
      auto_scaling = {
        min_replicas = 3
        max_replicas = 10
      }
      labels = {
        tier        = "production"
        cost_center = "operations"
      }
    }
  }
}
