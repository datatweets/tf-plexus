variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
  default     = "us-west1"
}

variable "zone" {
  type        = string
  description = "GCP zone"
  default     = "us-west1-a"
}
