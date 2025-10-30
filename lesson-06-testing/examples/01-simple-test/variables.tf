variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone for the VM instance"
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "Machine type for the VM instance"
  type        = string
  default     = "e2-micro"
  
  validation {
    condition     = contains(["e2-micro", "e2-small", "e2-medium"], var.machine_type)
    error_message = "Machine type must be one of: e2-micro, e2-small, e2-medium."
  }
}

variable "tags" {
  description = "Network tags for the instance"
  type        = list(string)
  default     = ["web", "ssh"]
}
