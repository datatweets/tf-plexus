variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "database_version" {
  description = "MySQL version"
  type        = string
  default     = "MYSQL_8_0"
}

variable "tier" {
  description = "Machine tier (db-f1-micro, db-n1-standard-1, etc.)"
  type        = string
  default     = "db-f1-micro"
}

variable "availability_type" {
  description = "Availability type: ZONAL or REGIONAL (for HA)"
  type        = string
  default     = "ZONAL"
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 10
}

variable "network_self_link" {
  description = "VPC network self link for private IP"
  type        = string
}

variable "backup_enabled" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "require_ssl" {
  description = "Require SSL for connections"
  type        = bool
  default     = false
}

variable "max_connections" {
  description = "Maximum number of connections"
  type        = string
  default     = "100"
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "appdb"
}

variable "db_user" {
  description = "Database user name"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database user password"
  type        = string
  sensitive   = true
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}
