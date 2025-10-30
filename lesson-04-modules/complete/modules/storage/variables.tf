variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "project_name" {
  type        = string
  description = "Project name for bucket naming"
}

variable "environment" {
  type        = string
  description = "Environment (dev or production)"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "buckets" {
  type = map(object({
    storage_class     = string
    lifecycle_age_days = number
    versioning        = bool
  }))
  description = "Map of buckets to create"
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to resources"
  default     = {}
}
