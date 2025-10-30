variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "environment" {
  type        = string
  description = "Environment (dev or production)"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "zone" {
  type        = string
  description = "GCP zone"
}

variable "machine_type" {
  type        = string
  description = "Machine type for database instance"
}

variable "disk_size_gb" {
  type        = number
  description = "Size of data disk in GB"
}

variable "network_id" {
  type        = string
  description = "VPC network ID"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for instance"
}

variable "enable_backup" {
  type        = bool
  description = "Whether to enable automated backups"
  default     = false
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to resources"
  default     = {}
}
