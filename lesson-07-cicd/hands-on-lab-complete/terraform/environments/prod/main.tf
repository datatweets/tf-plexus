terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "infrastructure" {
  source = "../../modules/compute"

  project_id     = var.project_id
  environment    = var.environment
  region         = var.region
  subnet_cidr    = var.subnet_cidr
  instance_count = var.instance_count
  machine_type   = var.machine_type
  disk_size_gb   = var.disk_size_gb
}
