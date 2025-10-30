variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "my-network"
}

variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    region        = string
    ip_cidr_range = string
  }))
  
  default = {
    "iowa" = {
      region        = "us-central1"
      ip_cidr_range = "192.168.1.0/24"
    }
    "virginia" = {
      region        = "us-east1"
      ip_cidr_range = "192.168.2.0/24"
    }
    "singapore" = {
      region        = "asia-southeast1"
      ip_cidr_range = "192.168.3.0/24"
    }
  }
}
