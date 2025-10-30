variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.vpc_name))
    error_message = "VPC name must start with a letter, contain only lowercase letters, numbers, and hyphens"
  }
}

variable "routing_mode" {
  description = "Routing mode for the VPC"
  type        = string
  default     = "REGIONAL"
  
  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "Routing mode must be REGIONAL or GLOBAL"
  }
}

variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    cidr                  = string
    region                = string
    private_google_access = optional(bool, true)
  }))
  
  validation {
    condition     = length(var.subnets) > 0
    error_message = "At least one subnet must be defined"
  }
}
