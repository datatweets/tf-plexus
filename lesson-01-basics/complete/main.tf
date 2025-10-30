# ============================================================================
# Terraform Configuration Block
# ============================================================================
terraform {
  required_version = ">= 1.9.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.38"
    }
  }
}

# ============================================================================
# Provider Configuration
# ============================================================================
provider "google" {
  project = var.project_id  # Use variable instead of hardcoded value
  region  = "us-central1"
  zone    = "us-central1-a"
}

# ============================================================================
# Variables (Inputs)
# ============================================================================
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "dev"
}

variable "team" {
  description = "Team name"
  type        = string
  default     = "engineering"
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 2
}

# ============================================================================
# Local Values (Computed Variables)
# ============================================================================
locals {
  # Combine variables into useful values
  name_prefix = "${var.team}-${var.environment}"
  
  # Common labels for all resources
  common_labels = {
    environment = var.environment
    team        = var.team
    managed_by  = "terraform"
    created_at  = formatdate("YYYY-MM-DD", timestamp())
  }
  
  # Determine machine type based on environment
  machine_type = (
    var.environment == "production" ? "n1-standard-8" :
    var.environment == "staging"    ? "n1-standard-4" :
    "n1-standard-2"
  )
}

# ============================================================================
# Storage Bucket
# ============================================================================
resource "google_storage_bucket" "data" {
  # Use expression to create unique name
  name     = "${local.name_prefix}-data-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  location = var.environment == "production" ? "US" : "us-central1"
  
  # Different storage class per environment
  storage_class = var.environment == "production" ? "STANDARD" : "NEARLINE"
  
  # Apply common labels
  labels = merge(
    local.common_labels,
    {
      resource_type = "storage"
      purpose       = "data-storage"
    }
  )
  
  # Enable versioning for production only
  versioning {
    enabled = var.environment == "production"
  }
  
  # Lifecycle rule - delete old objects
  lifecycle_rule {
    condition {
      age = var.environment == "production" ? 365 : 90
    }
    action {
      type = "Delete"
    }
  }
  
  # Prevent accidental deletion
  force_destroy = var.environment != "production"
}

# ============================================================================
# Compute Instances
# ============================================================================
resource "google_compute_instance" "app" {
  count = var.instance_count
  
  # Create unique names using count index
  name         = format("${local.name_prefix}-app-%02d", count.index + 1)
  machine_type = local.machine_type
  zone         = "us-central1-a"
  
  # Boot disk configuration (nested block)
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = var.environment == "production" ? 100 : 50
      type  = "pd-ssd"
    }
  }
  
  # Network configuration (nested block)
  network_interface {
    network = "default"
    
    # Dynamic blocks enable conditional nested blocks
    # (You'll learn this pattern in detail in Lesson 3, Section 1)
    dynamic "access_config" {
      for_each = var.environment == "production" ? [1] : []
      content {
        # External IP will be assigned
      }
    }
  }
  
  # Metadata (using map and function)
  metadata = {
    ssh-keys       = "admin:${file("~/.ssh/id_rsa.pub")}"
    startup-script = file("startup.sh")
    environment    = var.environment
    team           = var.team
    instance_index = tostring(count.index + 1)
  }
  
  # Labels (using merge function and locals)
  labels = merge(
    local.common_labels,
    {
      resource_type  = "compute"
      purpose        = "application-server"
      instance_index = tostring(count.index + 1)
    }
  )
  
  # Scheduling (using conditional)
  # Note: Preemptible instances must have on_host_maintenance = "TERMINATE"
  scheduling {
    automatic_restart   = var.environment == "production"
    on_host_maintenance = var.environment != "production" ? "TERMINATE" : "MIGRATE"
    preemptible         = var.environment != "production"
  }
}
