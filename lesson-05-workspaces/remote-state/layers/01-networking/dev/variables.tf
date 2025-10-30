variable "project_id" {
  description = "GCP project ID for dev environment"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}
