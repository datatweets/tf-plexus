# Variables for flexible-compute module

# Required variables
variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "name" {
  type        = string
  description = "Name of the instance"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.name))
    error_message = "Name must start with lowercase letter, contain only lowercase letters, numbers, and hyphens, max 63 chars."
  }
}

variable "zone" {
  type        = string
  description = "GCP zone for the instance"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, production)"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

# Sizing configuration (T-shirt sizes)
variable "sizing" {
  type        = string
  description = "T-shirt sizing: small, medium, large, xlarge"
  default     = "small"

  validation {
    condition     = contains(["small", "medium", "large", "xlarge"], var.sizing)
    error_message = "Sizing must be small, medium, large, or xlarge."
  }
}

# Custom configuration (overrides sizing)
variable "machine_type" {
  type        = string
  description = "Custom machine type (overrides sizing if provided)"
  default     = ""
}

variable "disk_size_gb" {
  type        = number
  description = "Boot disk size in GB (0 = use sizing default)"
  default     = 0

  validation {
    condition     = var.disk_size_gb == 0 || (var.disk_size_gb >= 10 && var.disk_size_gb <= 10000)
    error_message = "Disk size must be 0 (use default) or between 10 and 10000 GB."
  }
}

variable "disk_type" {
  type        = string
  description = "Boot disk type (empty = use sizing default)"
  default     = ""

  validation {
    condition     = var.disk_type == "" || contains(["pd-standard", "pd-balanced", "pd-ssd"], var.disk_type)
    error_message = "Disk type must be empty, pd-standard, pd-balanced, or pd-ssd."
  }
}

# Boot disk image
variable "boot_disk_image" {
  type        = string
  description = "Boot disk image"
  default     = "debian-cloud/debian-11"
}

# Network configuration
variable "network" {
  type        = string
  description = "Network to attach to"
  default     = "default"
}

variable "enable_external_ip" {
  type        = bool
  description = "Whether to assign external IP"
  default     = true
}

variable "network_tier" {
  type        = string
  description = "Network tier (PREMIUM or STANDARD)"
  default     = "PREMIUM"

  validation {
    condition     = contains(["PREMIUM", "STANDARD"], var.network_tier)
    error_message = "Network tier must be PREMIUM or STANDARD."
  }
}

# Data disks
variable "attach_data_disks" {
  type        = bool
  description = "Whether to attach additional data disks"
  default     = false
}

variable "data_disk_count" {
  type        = number
  description = "Number of data disks to attach"
  default     = 1

  validation {
    condition     = var.data_disk_count >= 1 && var.data_disk_count <= 10
    error_message = "Data disk count must be between 1 and 10."
  }
}

variable "data_disk_size_gb" {
  type        = number
  description = "Size of each data disk in GB"
  default     = 100

  validation {
    condition     = var.data_disk_size_gb >= 10 && var.data_disk_size_gb <= 10000
    error_message = "Data disk size must be between 10 and 10000 GB."
  }
}

# Backup configuration
variable "enable_backup" {
  type        = bool
  description = "Whether to enable automated backups"
  default     = false
}

variable "backup_schedule" {
  type        = string
  description = "Backup schedule in cron format"
  default     = "0 2 * * *"  # Daily at 2 AM
}

variable "backup_retention_days" {
  type        = number
  description = "Number of days to retain backups"
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 365
    error_message = "Backup retention must be between 1 and 365 days."
  }
}

# Monitoring
variable "enable_monitoring" {
  type        = bool
  description = "Whether to install monitoring agent"
  default     = false
}

# Security
variable "enable_secure_boot" {
  type        = bool
  description = "Enable secure boot"
  default     = false
}

variable "enable_vtpm" {
  type        = bool
  description = "Enable virtual TPM"
  default     = false
}

variable "enable_integrity_monitoring" {
  type        = bool
  description = "Enable integrity monitoring"
  default     = false
}

# Metadata and labels
variable "metadata" {
  type        = map(string)
  description = "Instance metadata"
  default     = {}
}

variable "tags" {
  type        = list(string)
  description = "Network tags"
  default     = []
}

variable "labels" {
  type        = map(string)
  description = "Resource labels"
  default     = {}
}
