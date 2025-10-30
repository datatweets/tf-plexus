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
