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

variable "instance_count" {
  type        = number
  description = "Number of app instances to create"
}

variable "machine_type" {
  type        = string
  description = "Machine type for instances"
}

variable "network_id" {
  type        = string
  description = "VPC network ID"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for instances"
}

variable "db_host" {
  type        = string
  description = "Database host IP"
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to resources"
  default     = {}
}
