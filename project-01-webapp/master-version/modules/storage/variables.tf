# Storage Module - Variables
# Purpose: Define inputs for GCS buckets

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "region" {
  description = "GCP region for storage buckets"
  type        = string
  default     = "us-west1"
}

variable "buckets" {
  description = "Map of GCS buckets to create"
  type = map(object({
    location      = string
    storage_class = string
    versioning    = bool
    lifecycle_rules = list(object({
      action_type          = string
      age_days             = optional(number)
      num_newer_versions   = optional(number)
    }))
  }))
  
  # Example:
  # {
  #   "assets" = {
  #     location      = "US"
  #     storage_class = "STANDARD"
  #     versioning    = true
  #     lifecycle_rules = [{
  #       action_type = "Delete"
  #       age_days    = 365
  #     }]
  #   }
  # }
}

variable "force_destroy" {
  description = "Allow bucket deletion even if not empty (use false in production)"
  type        = bool
  default     = true # For learning purposes
}

variable "uniform_bucket_level_access" {
  description = "Enable uniform bucket-level access"
  type        = bool
  default     = true
}

variable "public_access_prevention" {
  description = "Prevent public access to buckets"
  type        = string
  default     = "enforced" # enforced or inherited
}
