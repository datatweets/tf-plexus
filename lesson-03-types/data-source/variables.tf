# Variables for data source example

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "instance_name" {
  type        = string
  description = "Base name for instances"
  default     = "data-source-demo"
}

variable "region" {
  type        = string
  description = "GCP region to discover zones"
  default     = "us-west1"
}

variable "machine_type" {
  type        = string
  description = "Machine type for instances"
  default     = "e2-micro"
}

variable "instance_count" {
  type        = number
  description = "Number of instances to create (distributed across discovered zones)"
  default     = 3

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "use_existing_network" {
  type        = bool
  description = "Whether to use an existing network"
  default     = false
}

variable "existing_network_name" {
  type        = string
  description = "Name of existing network (if use_existing_network is true)"
  default     = "default"
}

variable "create_ubuntu_instance" {
  type        = bool
  description = "Whether to create Ubuntu instance"
  default     = true
}

variable "create_data_disk" {
  type        = bool
  description = "Whether to create data disk"
  default     = true
}
