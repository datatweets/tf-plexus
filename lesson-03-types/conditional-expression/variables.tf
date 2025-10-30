# Variables for conditional expression example

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "instance_name" {
  type        = string
  description = "Name of the compute instance"
  default     = "conditional-demo"
}

variable "environment" {
  type        = string
  description = "Environment: dev or prod"
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod'."
  }
}

variable "zone" {
  type        = string
  description = "GCP zone"
  default     = "us-west1-a"
}

variable "region" {
  type        = string
  description = "GCP region"
  default     = "us-west1"
}

variable "zones" {
  type        = list(string)
  description = "List of zones for replicas"
  default     = ["us-west1-a", "us-west1-b", "us-west1-c"]
}

variable "boot_image" {
  type        = string
  description = "Boot disk image"
  default     = "debian-cloud/debian-11"
}

variable "dev_machine_type" {
  type        = string
  description = "Machine type for development"
  default     = "e2-micro"
}

variable "prod_machine_type" {
  type        = string
  description = "Machine type for production"
  default     = "e2-standard-4"
}

variable "assign_external_ip" {
  type        = bool
  description = "Whether to assign an external IP"
  default     = true
}

variable "assign_static_ip" {
  type        = bool
  description = "Whether to assign a static IP (requires assign_external_ip=true)"
  default     = false
}

variable "enable_startup_script" {
  type        = bool
  description = "Whether to run startup script"
  default     = true
}

variable "allow_http_traffic" {
  type        = bool
  description = "Whether to create firewall rule for HTTP"
  default     = true
}

variable "enable_backups" {
  type        = bool
  description = "Whether to create and attach backup disk"
  default     = false
}

variable "backup_disk_size" {
  type        = number
  description = "Backup disk size in GB"
  default     = 50
}

variable "replica_count" {
  type        = number
  description = "Number of replica instances in production"
  default     = 2

  validation {
    condition     = var.replica_count >= 0 && var.replica_count <= 10
    error_message = "Replica count must be between 0 and 10."
  }
}

variable "prod_allowed_ips" {
  type        = list(string)
  description = "Allowed IP ranges for production"
  default     = ["10.0.0.0/8"]
}
