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
  description = "Name for load balancer resources"
}

variable "network_id" {
  type        = string
  description = "VPC network ID"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID"
}

variable "backend_instances" {
  type        = list(string)
  description = "List of backend instance self links"
}

variable "use_static_ip" {
  type        = bool
  description = "Whether to use static IP"
  default     = false
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to resources"
  default     = {}
}
