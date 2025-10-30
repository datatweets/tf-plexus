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

variable "name" {
  type        = string
  description = "Name for monitoring instance"
}

variable "network_id" {
  type        = string
  description = "VPC network ID"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for instance"
}

variable "monitored_instances" {
  type        = list(string)
  description = "List of instance names to monitor"
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to resources"
  default     = {}
}
