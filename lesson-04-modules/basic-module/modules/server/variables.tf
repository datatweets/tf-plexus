# modules/server/variables.tf

variable "name" {
  type        = string
  description = "Name of the server"
}

variable "machine_type" {
  type        = string
  description = "GCP machine type (e2-micro, e2-small, etc.)"
  default     = "e2-micro"
}

variable "zone" {
  type        = string
  description = "GCP zone where server will be created"
  default     = "us-central1-a"
}

variable "static_ip" {
  type        = bool
  description = "Whether to assign a static IP address"
  default     = false
}
