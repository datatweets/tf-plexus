variable "name" {
  type        = string
  description = "Server name"
}

variable "size" {
  type        = string
  description = "T-shirt size: micro, small, medium, large, xlarge"
  default     = "small"

  validation {
    condition     = contains(["micro", "small", "medium", "large", "xlarge"], var.size)
    error_message = "Size must be one of: micro, small, medium, large, xlarge."
  }
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

variable "tier" {
  type        = string
  description = "Application tier (web, app, db, etc.)"
  default     = ""
}

variable "zone" {
  type        = string
  description = "GCP zone"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "network" {
  type        = string
  description = "Network name or self link"
  default     = "default"
}

variable "subnetwork" {
  type        = string
  description = "Subnetwork name or self link"
  default     = null
}

variable "image" {
  type        = string
  description = "Boot disk image"
  default     = "debian-cloud/debian-12"
}

variable "enable_external_ip" {
  type        = bool
  description = "Whether to enable external IP"
  default     = false
}

variable "enable_static_ip" {
  type        = bool
  description = "Whether to use static IP (requires enable_external_ip)"
  default     = false
}

variable "startup_script" {
  type        = string
  description = "Path to startup script template"
  default     = ""
}

variable "custom_tags" {
  type        = list(string)
  description = "Additional network tags"
  default     = []
}

variable "custom_labels" {
  type        = map(string)
  description = "Additional labels"
  default     = {}
}
