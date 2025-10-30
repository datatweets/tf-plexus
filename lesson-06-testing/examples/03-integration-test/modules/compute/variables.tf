variable "network_id" {
  description = "ID of the network to attach instances to"
  type        = string
}

variable "subnetwork_id" {
  description = "ID of the subnetwork to attach instances to"
  type        = string
}

variable "instances" {
  description = "Map of instances to create"
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
  
  validation {
    condition     = length(var.instances) > 0
    error_message = "At least one instance must be defined"
  }
}
