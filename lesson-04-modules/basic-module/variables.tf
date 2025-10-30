# variables.tf (root module)

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "server_name" {
  type        = string
  description = "Base name for servers"
  default     = "demo-server"
}

variable "zone" {
  type        = string
  description = "Default zone for servers"
  default     = "us-central1-c"
}

variable "machine_type" {
  type        = string
  description = "Default machine type"
  default     = "e2-micro"
}
