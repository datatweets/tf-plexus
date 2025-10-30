terraform {
  required_version = ">= 1.6"
  
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

# Create networking infrastructure
module "networking" {
  source = "./modules/networking"
  
  vpc_name     = var.vpc_name
  routing_mode = var.routing_mode
  subnets      = var.subnets
}

# Create compute instances using the network
module "compute" {
  source = "./modules/compute"
  
  network_id    = module.networking.vpc_id
  subnetwork_id = module.networking.subnet_ids[var.primary_subnet_name]
  instances     = var.instances
  
  # Ensure networking is created first
  depends_on = [module.networking]
}
