/**
 * Networking Layer - Dev Environment
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
    prefix = "lesson-05/remote-state/dev/networking"
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
  environment          = "dev"
  region               = var.region
  public_subnet_cidr   = "10.0.1.0/24"
  private_subnet_cidr  = "10.0.2.0/24"
  ssh_source_ranges    = ["0.0.0.0/0"]
}
