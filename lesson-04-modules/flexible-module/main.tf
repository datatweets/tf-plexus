# Flexible Module Example - Root Module
# Demonstrates advanced module patterns with T-shirt sizing and validation

# Small web server using sizing preset
module "web_small" {
  source = "./modules/flexible-compute"

  project_id  = var.project_id
  name        = "web-small"
  zone        = var.zone
  environment = "dev"
  
  # T-shirt sizing
  sizing = "small"
  
  # Network configuration
  network_tier = "standard"
  
  labels = {
    tier = "web"
  }
}

# Medium app server
module "app_medium" {
  source = "./modules/flexible-compute"

  project_id  = var.project_id
  name        = "app-medium"
  zone        = var.zone
  environment = "staging"
  
  sizing = "medium"
  
  # Enable monitoring
  enable_monitoring = true
  
  labels = {
    tier = "application"
  }
}

# Large database server with custom configuration
module "db_large" {
  source = "./modules/flexible-compute"

  project_id  = var.project_id
  name        = "db-large"
  zone        = var.zone
  environment = "production"
  
  sizing = "large"
  
  # Custom overrides
  disk_size_gb = 500
  disk_type    = "pd-ssd"
  
  # Additional disks
  attach_data_disks = true
  data_disk_count   = 2
  data_disk_size_gb = 1000
  
  # Backup configuration
  enable_backup = true
  backup_schedule = "0 2 * * *"  # Daily at 2 AM
  
  # Enhanced security
  enable_secure_boot    = true
  enable_vtpm           = true
  enable_integrity_monitoring = true
  
  labels = {
    tier        = "database"
    criticality = "high"
  }
}

# Custom configuration (not using sizing presets)
module "custom_server" {
  source = "./modules/flexible-compute"

  project_id  = var.project_id
  name        = "custom-server"
  zone        = var.zone
  environment = "production"
  
  # Specify exact machine type instead of sizing
  machine_type = "e2-standard-8"
  
  disk_size_gb = 200
  disk_type    = "pd-balanced"
  
  labels = {
    tier = "custom"
  }
}
