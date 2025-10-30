# Variables for dynamic block example

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "instance_name" {
  type        = string
  description = "Name of the compute instance"
  default     = "dynamic-block-demo"
}

variable "machine_type" {
  type        = string
  description = "Machine type"
  default     = "e2-medium"
}

variable "zone" {
  type        = string
  description = "GCP zone"
  default     = "us-west1-a"
}

variable "boot_image" {
  type        = string
  description = "Boot disk image"
  default     = "debian-cloud/debian-11"
}

variable "boot_disk_size" {
  type        = number
  description = "Boot disk size in GB"
  default     = 20
}

variable "disks" {
  type = map(object({
    type = string
    size = number
    mode = string
  }))
  description = "Map of disks to create and attach"
  default = {
    data-disk-1 = {
      type = "pd-standard"
      size = 10
      mode = "READ_WRITE"
    }
    data-disk-2 = {
      type = "pd-balanced"
      size = 50
      mode = "READ_WRITE"
    }
    data-disk-3 = {
      type = "pd-ssd"
      size = 100
      mode = "READ_ONLY"
    }
  }

  validation {
    condition = alltrue([
      for disk in var.disks : contains(["READ_WRITE", "READ_ONLY"], disk.mode)
    ])
    error_message = "Disk mode must be either READ_WRITE or READ_ONLY."
  }
}

variable "firewall_rules" {
  type = list(object({
    protocol = string
    port     = number
  }))
  description = "List of firewall rules to create"
  default = [
    {
      protocol = "tcp"
      port     = 80
    },
    {
      protocol = "tcp"
      port     = 443
    },
    {
      protocol = "tcp"
      port     = 8080
    }
  ]
}

variable "create_multi_nic" {
  type        = bool
  description = "Whether to create multi-NIC instance"
  default     = false
}

variable "network_interfaces" {
  type = list(object({
    network     = string
    subnetwork  = string
    external_ip = bool
  }))
  description = "Network interfaces for multi-NIC instance"
  default = [
    {
      network     = "default"
      subnetwork  = ""
      external_ip = true
    }
  ]
}
