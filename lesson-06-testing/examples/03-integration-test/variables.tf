variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "routing_mode" {
  description = "VPC routing mode"
  type        = string
  default     = "REGIONAL"
}

variable "subnets" {
  description = "Subnets to create"
  type = map(object({
    cidr                  = string
    region                = string
    private_google_access = optional(bool, true)
  }))
}

variable "primary_subnet_name" {
  description = "Name of the primary subnet for instances"
  type        = string
}

variable "instances" {
  description = "Instances to create"
  type = map(object({
    machine_type       = string
    zone               = string
    tags               = optional(list(string), [])
    boot_image         = optional(string, "debian-cloud/debian-11")
    disk_size_gb       = optional(number, 10)
    disk_type          = optional(string, "pd-standard")
    assign_external_ip = optional(bool, false)
    metadata           = optional(map(string), {})
    labels             = optional(map(string), {})
  }))
}
