/**
 * Data Layer - Dev Environment
 * Layer 02: Cloud SQL Database
 * 
 * Depends on: Layer 01 (networking)
 * Creates: MySQL database instance
 */

terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "gcs" {
    bucket = "your-terraform-state-bucket"
    prefix = "lesson-05/complete/dev/data"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Read networking layer outputs
data "terraform_remote_state" "networking" {
  backend = "gcs"
  
  config = {
    bucket = "your-terraform-state-bucket"
    prefix = "lesson-05/complete/dev/networking"
  }
}

# Database Module
module "database" {
  source = "../../modules/database"

  project_id          = var.project_id
  environment         = "dev"
  region              = var.region
  tier                = "db-f1-micro"  # Cheapest for dev
  availability_type   = "ZONAL"        # No HA for dev
  disk_size           = 10
  network_self_link   = data.terraform_remote_state.networking.outputs.network_self_link
  database_name       = "appdb"
  db_user             = "admin"
  db_password         = var.db_password
  deletion_protection = false  # Allow easy cleanup in dev
}
