# main.tf (root module)

terraform {
  required_version = ">= 1.9"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
}

module "server1" {
  source       = "./modules/server"
  name         = "${var.server_name}-1"
  zone         = var.zone
  machine_type = var.machine_type
  static_ip    = true
}

module "server2" {
  source       = "./modules/server"
  name         = "${var.server_name}-2"
  zone         = var.zone
  machine_type = var.machine_type
  static_ip    = false
}

module "server3" {
  source       = "./modules/server"
  name         = "${var.server_name}-3"
  zone         = var.zone
  machine_type = "e2-small"
  static_ip    = true
}
