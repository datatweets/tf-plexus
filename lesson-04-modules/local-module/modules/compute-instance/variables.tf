# Variables for compute-instance module

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "name" {
  type        = string
  description = "Name of the instance"
}

variable "zone" {
  type        = string
  description = "GCP zone for the instance"
}

variable "machine_type" {
  type        = string
  description = "Machine type for the instance"
  default     = "e2-micro"
}

variable "boot_disk_image" {
  type        = string
  description = "Boot disk image"
  default     = "debian-cloud/debian-11"
}

variable "boot_disk_size" {
  type        = number
  description = "Boot disk size in GB"
  default     = 20
}

variable "boot_disk_type" {
  type        = string
  description = "Boot disk type"
  default     = "pd-standard"
}

variable "network" {
  type        = string
  description = "Network to attach to"
  default     = "default"
}

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

variable "service_account_email" {
  type        = string
  description = "Service account email"
  default     = ""
}

variable "service_account_scopes" {
  type        = list(string)
  description = "Service account scopes"
  default     = ["cloud-platform"]
}
