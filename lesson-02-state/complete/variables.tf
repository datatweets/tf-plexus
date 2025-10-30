variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "regions" {
  description = "Map of regions and their configurations"
  type = map(object({
    zone          = string
    ip_cidr_range = string
  }))
  
  default = {
    iowa = {
      zone          = "us-central1-a"
      ip_cidr_range = "192.168.1.0/24"
    }
    virginia = {
      zone          = "us-east1-b"
      ip_cidr_range = "192.168.2.0/24"
    }
    singapore = {
      zone          = "asia-southeast1-a"
      ip_cidr_range = "192.168.3.0/24"
    }
  }
}
