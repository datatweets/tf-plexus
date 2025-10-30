variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "project_name" {
  type        = string
  description = "Project name for resource naming"
}

variable "environment" {
  type        = string
  description = "Environment (dev or production)"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "frontend_cidr" {
  type        = string
  description = "CIDR block for frontend subnet"
}

variable "application_cidr" {
  type        = string
  description = "CIDR block for application subnet"
}

variable "database_cidr" {
  type        = string
  description = "CIDR block for database subnet"
}

variable "management_cidr" {
  type        = string
  description = "CIDR block for management subnet"
}
