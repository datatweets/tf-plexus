# Database Module - Variables

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "database_name" {
  type    = string
  default = "plexus_db"
}

variable "database_version" {
  type    = string
  default = "POSTGRES_15"
}

variable "database_tier" {
  type    = string
  default = "db-f1-micro"
}

variable "database_disk_size" {
  type    = number
  default = 10
}

variable "enable_backups" {
  type    = bool
  default = false
}

variable "backup_start_time" {
  type    = string
  default = "03:00"
}

variable "database_user" {
  type    = string
  default = "admin"
}

variable "database_password" {
  type      = string
  sensitive = true
}

variable "enable_public_ip" {
  type    = bool
  default = true
}

variable "authorized_networks" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "environment" {
  type = string
}
