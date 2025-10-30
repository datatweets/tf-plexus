/**
 * Compute Layer - Dev Environment
 * 
 * Creates compute instances using networking from layer 01.
 * Uses terraform_remote_state to read networking outputs.
 * Deploy this AFTER the networking layer.
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
    prefix = "lesson-05/remote-state/dev/compute"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Read networking layer outputs using terraform_remote_state
data "terraform_remote_state" "networking" {
  backend = "gcs"
  
  config = {
    bucket = "your-terraform-state-bucket"
    prefix = "lesson-05/remote-state/dev/networking"
  }
}

# Web Server (public subnet)
module "web_server" {
  source = "../../modules/server"

  project_id          = var.project_id
  name                = "dev-web-server"
  environment         = "dev"
  tier                = "web"
  size                = "micro"
  zone                = var.zone
  subnetwork          = data.terraform_remote_state.networking.outputs.public_subnet_self_link
  enable_external_ip  = true
}

# App Server (private subnet)
module "app_server" {
  source = "../../modules/server"

  project_id          = var.project_id
  name                = "dev-app-server"
  environment         = "dev"
  tier                = "app"
  size                = "small"
  zone                = var.zone
  subnetwork          = data.terraform_remote_state.networking.outputs.private_subnet_self_link
  enable_external_ip  = false
}
