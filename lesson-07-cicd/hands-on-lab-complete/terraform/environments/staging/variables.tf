variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "subnet_cidr" {
  description = "Subnet CIDR"
  type        = string
  default     = "10.1.1.0/24"
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Machine type"
  type        = string
  default     = "e2-small"
}

variable "disk_size_gb" {
  description = "Disk size"
  type        = number
  default     = 20
}
