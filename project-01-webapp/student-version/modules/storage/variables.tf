# Storage Module - Variables

variable "project_id" {
  type = string
}

variable "buckets" {
  description = "Map of storage buckets to create"
  type = map(object({
    location      = string
    storage_class = string
    versioning    = bool
    lifecycle_rules = list(object({
      action_type          = string
      age                  = number
      num_newer_versions   = number
    }))
  }))
}

variable "force_destroy" {
  type    = bool
  default = false
}

variable "environment" {
  type = string
}
