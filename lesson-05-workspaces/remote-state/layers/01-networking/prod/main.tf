/**
 * Networking Layer - Production Environment
 * 
 * Creates VPC, subnets, and firewall rules.
 * This layer must be deployed first.
 */

terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "your-terraform-state-bucket"
    prefix = "lesson-05/remote-state/prod/networking"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_id           = var.project_id
  environment          = "prod"
  region               = var.region
  public_subnet_cidr   = "10.1.1.0/24"
  private_subnet_cidr  = "10.1.2.0/24"
  ssh_source_ranges    = ["YOUR_OFFICE_IP/32"]  # Restrict SSH in production
}
