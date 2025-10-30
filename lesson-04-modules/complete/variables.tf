# Variables for complete multi-module example

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "project_name" {
  type        = string
  description = "Project name for resource naming"
  default     = "multi-tier-app"
}

variable "region" {
  type        = string
  description = "GCP region"
  default     = "us-west1"
}

variable "zone" {
  type        = string
  description = "GCP zone"
  default     = "us-west1-a"
}

variable "environment" {
  type        = string
  description = "Environment (dev or production)"
  default     = "dev"

  validation {
    condition     = contains(["dev", "production"], var.environment)
    error_message = "Environment must be dev or production."
  }
}

# Instance counts
variable "web_instance_count" {
  type        = number
  description = "Number of web tier instances"
  default     = 2

  validation {
    condition     = var.web_instance_count >= 1 && var.web_instance_count <= 10
    error_message = "Web instance count must be between 1 and 10."
  }
}

variable "app_instance_count" {
  type        = number
  description = "Number of application tier instances"
  default     = 2

  validation {
    condition     = var.app_instance_count >= 1 && var.app_instance_count <= 10
    error_message = "App instance count must be between 1 and 10."
  }
}

# Optional features
variable "enable_monitoring" {
  type        = bool
  description = "Whether to deploy monitoring instance"
  default     = true
}
