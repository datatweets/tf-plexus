variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "bucket_name" {
  description = "Bucket name suffix"
  type        = string
}

variable "location" {
  description = "Bucket location"
  type        = string
  default     = "US"
}

variable "storage_class" {
  description = "Storage class (STANDARD, NEARLINE, COLDLINE, ARCHIVE)"
  type        = string
  default     = "STANDARD"
}

variable "force_destroy" {
  description = "Allow bucket destruction even with objects"
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable object versioning"
  type        = bool
  default     = false
}

variable "lifecycle_rules" {
  description = "Lifecycle rules for the bucket"
  type = list(object({
    action = object({
      type          = string
      storage_class = optional(string)
    })
    condition = object({
      age                = optional(number)
      num_newer_versions = optional(number)
      with_state         = optional(string)
    })
  }))
  default = []
}

variable "purpose" {
  description = "Purpose of the bucket (app-data, static-assets, backups)"
  type        = string
}

variable "custom_labels" {
  description = "Custom labels"
  type        = map(string)
  default     = {}
}
