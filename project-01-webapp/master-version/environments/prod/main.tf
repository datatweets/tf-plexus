# Production Environment - Main Configuration
# Purpose: Orchestrate all modules for the prod environment

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Local variables for consistent configuration
locals {
  common_tags = {
    environment = var.environment
    managed_by  = "terraform"
    project     = "plexus-webapp"
    criticality = "high"
  }
  
  # Subnet configuration - Larger IP ranges for production
  subnets = {
    web = {
      ip_cidr_range = "10.1.1.0/24"
      region        = var.region
      description   = "Subnet for web servers in production"
    }
    data = {
      ip_cidr_range = "10.1.2.0/24"
      region        = var.region
      description   = "Subnet for database and backend services in production"
    }
  }
  
  # Firewall rules configuration - More restrictive in prod
  firewall_rules = {
    allow-ssh = {
      description   = "Allow SSH from specific IPs only"
      priority      = 1000
      direction     = "INGRESS"
      allow = [{
        protocol = "tcp"
        ports    = ["22"]
      }]
      # In production, restrict to office/VPN IPs
      # Example: source_ranges = ["203.0.113.0/24"]
      source_ranges = ["0.0.0.0/0"] # Change this in real prod!
      target_tags   = ["web-server"]
    }
    allow-http = {
      description   = "Allow HTTP/HTTPS traffic"
      priority      = 1000
      direction     = "INGRESS"
      allow = [{
        protocol = "tcp"
        ports    = ["80", "443"]
      }]
      source_ranges = ["0.0.0.0/0"]
      target_tags   = ["web-server", "http-server"]
    }
    allow-internal = {
      description   = "Allow internal communication"
      priority      = 1000
      direction     = "INGRESS"
      allow = [
        {
          protocol = "tcp"
          ports    = ["0-65535"]
        },
        {
          protocol = "udp"
          ports    = ["0-65535"]
        },
        {
          protocol = "icmp"
          ports    = []
        }
      ]
      source_ranges = ["10.1.0.0/16"]
      target_tags   = ["web-server"]
    }
  }
  
  # Storage buckets configuration - Enhanced retention for prod
  storage_buckets = {
    assets = {
      location      = "US"
      storage_class = "STANDARD"
      versioning    = true # Always enabled in prod
      lifecycle_rules = [{
        action_type = "Delete"
        age_days    = 365 # Longer retention in prod
      }]
    }
    backups = {
      location      = "US"
      storage_class = "NEARLINE"
      versioning    = true
      lifecycle_rules = [
        {
          action_type = "Delete"
          age_days    = 90 # Longer retention in prod
        },
        {
          action_type        = "Delete"
          num_newer_versions = 10 # Keep more versions
        }
      ]
    }
  }
}

# Networking Module
module "networking" {
  source = "../../modules/networking"
  
  project_id     = var.project_id
  environment    = var.environment
  vpc_name       = var.vpc_name
  subnets        = local.subnets
  firewall_rules = local.firewall_rules
}

# Compute Module
module "compute" {
  source = "../../modules/compute"
  
  project_id          = var.project_id
  environment         = var.environment
  region              = var.region
  zone                = var.zone
  instance_count      = var.web_server_count
  machine_type        = var.machine_type
  subnet_self_link    = module.networking.subnet_self_links["web"]
  vpc_name            = module.networking.vpc_name
  enable_load_balancer = var.enable_load_balancer
  app_name            = "plexus-app"
  
  tags = ["web-server", "http-server", var.environment]
  
  # Explicit dependency on networking
  depends_on = [module.networking]
}

# Database Module
module "database" {
  count = var.enable_database ? 1 : 0
  
  source = "../../modules/database"
  
  project_id        = var.project_id
  environment       = var.environment
  region            = var.region
  database_name     = "plexus-${var.environment}-db"
  database_version  = "POSTGRES_15"
  tier              = var.database_tier
  disk_size         = 20 # Larger disk for prod
  enable_backups    = var.enable_database_backups
  backup_start_time = "03:00"
  
  # Enable public IP but with restricted access
  # In real production, use private IP with Cloud SQL Proxy
  enable_public_ip     = true
  deletion_protection  = true # Protect production database
  
  # Restrict access to specific IPs in production
  authorized_networks = []
  
  # Explicit dependency on networking
  depends_on = [module.networking]
}

# Storage Module
module "storage" {
  count = var.enable_storage ? 1 : 0
  
  source = "../../modules/storage"
  
  project_id                   = var.project_id
  environment                  = var.environment
  region                       = var.region
  buckets                      = local.storage_buckets
  force_destroy                = false # Protect production data
  uniform_bucket_level_access  = true
  public_access_prevention     = "enforced"
}
