variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "name" {
  description = "Name of the server"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "tier" {
  description = "Server tier (web, app, db)"
  type        = string
}

variable "size" {
  description = "T-shirt size for the server"
  type        = string

  validation {
    condition     = contains(["micro", "small", "medium", "large"], var.size)
    error_message = "Size must be one of: micro, small, medium, large"
  }
}

variable "zone" {
  description = "GCP zone"
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork self link (from networking layer)"
  type        = string
}

variable "enable_external_ip" {
  description = "Whether to assign an external IP"
  type        = bool
  default     = false
}

variable "service_account_email" {
  description = "Service account email for the instance"
  type        = string
  default     = null
}

variable "custom_tags" {
  description = "Custom network tags"
  type        = list(string)
  default     = []
}

variable "custom_labels" {
  description = "Custom labels"
  type        = map(string)
  default     = {}
}
