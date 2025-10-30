# Production Multi-Module Architecture
# Demonstrates building complex infrastructure using multiple custom modules

# Web tier using compute module
module "web_tier" {
  source = "./modules/web-tier"

  project_id  = var.project_id
  environment = var.environment
  region      = var.region
  zone        = var.zone
  
  instance_count = var.web_instance_count
  machine_type   = var.environment == "production" ? "e2-medium" : "e2-micro"
  
  network_id = module.networking.network_id
  subnet_id  = module.networking.frontend_subnet_id
  
  labels = local.common_labels
}

# Application tier using compute module
module "app_tier" {
  source = "./modules/app-tier"

  project_id  = var.project_id
  environment = var.environment
  region      = var.region
  zone        = var.zone
  
  instance_count = var.app_instance_count
  machine_type   = var.environment == "production" ? "e2-standard-2" : "e2-small"
  
  network_id = module.networking.network_id
  subnet_id  = module.networking.application_subnet_id
  
  # Configuration from data tier
  db_host = module.data_tier.db_private_ip
  
  labels = local.common_labels
}

# Data tier using database module
module "data_tier" {
  source = "./modules/data-tier"

  project_id  = var.project_id
  environment = var.environment
  region      = var.region
  zone        = var.zone
  
  machine_type = var.environment == "production" ? "e2-standard-4" : "e2-medium"
  disk_size_gb = var.environment == "production" ? 200 : 50
  
  network_id = module.networking.network_id
  subnet_id  = module.networking.database_subnet_id
  
  # Backups only in production
  enable_backup = var.environment == "production"
  
  labels = local.common_labels
}

# Networking module
module "networking" {
  source = "./modules/networking"

  project_id   = var.project_id
  project_name = var.project_name
  environment  = var.environment
  region       = var.region
  
  # CIDR blocks for subnets
  frontend_cidr    = "10.0.1.0/24"
  application_cidr = "10.0.2.0/24"
  database_cidr    = "10.0.3.0/24"
  management_cidr  = "10.0.4.0/24"
}

# Load balancer module
module "load_balancer" {
  source = "./modules/load-balancer"

  project_id  = var.project_id
  environment = var.environment
  region      = var.region
  zone        = var.zone
  
  name       = "${var.project_name}-lb"
  network_id = module.networking.network_id
  subnet_id  = module.networking.frontend_subnet_id
  
  # Backend servers from web tier
  backend_instances = module.web_tier.instance_self_links
  
  # Static IP only in production
  use_static_ip = var.environment == "production"
  
  labels = local.common_labels
}

# Monitoring module (optional)
module "monitoring" {
  count = var.enable_monitoring ? 1 : 0
  
  source = "./modules/monitoring"

  project_id  = var.project_id
  environment = var.environment
  region      = var.region
  zone        = var.zone
  
  name       = "${var.project_name}-monitoring"
  network_id = module.networking.network_id
  subnet_id  = module.networking.management_subnet_id
  
  # Instances to monitor
  monitored_instances = concat(
    module.web_tier.instance_names,
    module.app_tier.instance_names,
    [module.data_tier.db_instance_name]
  )
  
  labels = local.common_labels
}

# Storage module for shared assets
module "storage" {
  source = "./modules/storage"

  project_id   = var.project_id
  project_name = var.project_name
  environment  = var.environment
  region       = var.region
  
  # Bucket configurations
  buckets = {
    assets = {
      storage_class     = "STANDARD"
      lifecycle_age_days = 90
      versioning        = true
    }
    backups = {
      storage_class     = "NEARLINE"
      lifecycle_age_days = 180
      versioning        = true
    }
    logs = {
      storage_class     = "COLDLINE"
      lifecycle_age_days = 365
      versioning        = false
    }
  }
  
  labels = local.common_labels
}

# Local values
locals {
  common_labels = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
    lesson      = "lesson-04"
  }
}
