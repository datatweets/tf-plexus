# Variables for root module

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "zone" {
  type        = string
  description = "GCP zone for instances"
  default     = "us-west1-a"
}

variable "worker_count" {
  type        = number
  description = "Number of worker instances to create"
  default     = 2

  validation {
    condition     = var.worker_count >= 1 && var.worker_count <= 5
    error_message = "Worker count must be between 1 and 5."
  }
}
