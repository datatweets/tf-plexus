variable "instance_name" {
  description = "Name of the compute instance"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.instance_name))
    error_message = "Instance name must start with a letter, contain only lowercase letters, numbers, and hyphens, and be 1-63 characters long"
  }
}

variable "machine_type" {
  description = "Machine type for the instance"
  type        = string
  default     = "e2-micro"
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.machine_type))
    error_message = "Machine type must be a valid GCP machine type"
  }
}

variable "zone" {
  description = "GCP zone for the instance"
  type        = string
  default     = "us-central1-a"
}

variable "tags" {
  description = "Network tags for the instance"
  type        = list(string)
  default     = []
}

variable "boot_image" {
  description = "Boot disk image"
  type        = string
  default     = "debian-cloud/debian-11"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 10
  
  validation {
    condition     = var.disk_size_gb >= 10 && var.disk_size_gb <= 10000
    error_message = "Disk size must be between 10 and 10000 GB"
  }
}

variable "disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-standard"
  
  validation {
    condition     = contains(["pd-standard", "pd-ssd", "pd-balanced"], var.disk_type)
    error_message = "Disk type must be pd-standard, pd-ssd, or pd-balanced"
  }
}

variable "network" {
  description = "Network to attach the instance to"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "Subnetwork to attach the instance to"
  type        = string
  default     = null
}

variable "assign_external_ip" {
  description = "Whether to assign an external IP address"
  type        = bool
  default     = true
}

variable "metadata" {
  description = "Instance metadata"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Labels to apply to the instance"
  type        = map(string)
  default     = {}
}

variable "allow_stopping_for_update" {
  description = "Allow stopping the instance to update properties"
  type        = bool
  default     = true
}

variable "enable_create_before_destroy" {
  description = "Enable create_before_destroy lifecycle rule"
  type        = bool
  default     = false
}
