/**
 * Compute Layer - Production Environment
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
    prefix = "lesson-05/remote-state/prod/compute"
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
    prefix = "lesson-05/remote-state/prod/networking"
  }
}

# Web Servers (public subnet) - 2 instances
module "web_server_1" {
  source = "../../modules/server"

  project_id          = var.project_id
  name                = "prod-web-server-1"
  environment         = "prod"
  tier                = "web"
  size                = "medium"
  zone                = var.zone
  subnetwork          = data.terraform_remote_state.networking.outputs.public_subnet_self_link
  enable_external_ip  = true
}

module "web_server_2" {
  source = "../../modules/server"

  project_id          = var.project_id
  name                = "prod-web-server-2"
  environment         = "prod"
  tier                = "web"
  size                = "medium"
  zone                = var.zone
  subnetwork          = data.terraform_remote_state.networking.outputs.public_subnet_self_link
  enable_external_ip  = true
}

# App Servers (private subnet) - 2 instances
module "app_server_1" {
  source = "../../modules/server"

  project_id          = var.project_id
  name                = "prod-app-server-1"
  environment         = "prod"
  tier                = "app"
  size                = "large"
  zone                = var.zone
  subnetwork          = data.terraform_remote_state.networking.outputs.private_subnet_self_link
  enable_external_ip  = false
}

module "app_server_2" {
  source = "../../modules/server"

  project_id          = var.project_id
  name                = "prod-app-server-2"
  environment         = "prod"
  tier                = "app"
  size                = "large"
  zone                = var.zone
  subnetwork          = data.terraform_remote_state.networking.outputs.private_subnet_self_link
  enable_external_ip  = false
}
