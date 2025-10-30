# Variables for output example

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "server_name" {
  type        = string
  description = "Base name for servers"
  default     = "output-demo"
}

variable "region" {
  type        = string
  description = "GCP region"
  default     = "us-west1"
}

variable "zones" {
  type        = list(string)
  description = "List of zones for server distribution"
  default     = ["us-west1-a", "us-west1-b", "us-west1-c"]
}

variable "server_count" {
  type        = number
  description = "Number of web servers to create"
  default     = 3

  validation {
    condition     = var.server_count >= 1 && var.server_count <= 10
    error_message = "Server count must be between 1 and 10."
  }
}

variable "machine_type" {
  type        = string
  description = "Machine type for web servers"
  default     = "e2-micro"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "demo"
}

variable "create_lb" {
  type        = bool
  description = "Whether to create load balancer"
  default     = true
}

variable "db_configs" {
  type = map(object({
    machine_type = string
    zone         = string
    disk_size    = number
    db_type      = string
  }))
  description = "Database server configurations"
  default = {
    "db-primary" = {
      machine_type = "e2-medium"
      zone         = "us-west1-a"
      disk_size    = 100
      db_type      = "postgresql"
    }
    "db-replica" = {
      machine_type = "e2-medium"
      zone         = "us-west1-b"
      disk_size    = 100
      db_type      = "postgresql"
    }
  }
}

variable "sensitive_api_key" {
  type        = string
  description = "API key (sensitive)"
  default     = "demo-api-key-12345"
  sensitive   = true
}
