variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "server_count" {
  description = "Number of servers to create"
  type        = number
  default     = 3
}

variable "zones" {
  description = "List of zones to distribute servers across"
  type        = list(string)
  default     = ["us-central1-a", "us-central1-b", "us-central1-c"]
}
