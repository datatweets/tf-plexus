# Database Module - Main Configuration
# Purpose: Create Cloud SQL PostgreSQL instance for Plexus app

# Cloud SQL Instance
resource "google_sql_database_instance" "postgres" {
  name             = var.database_name
  database_version = var.database_version
  region           = var.region
  project          = var.project_id
  
  # Deletion protection (Lesson 2 - lifecycle)
  # Prevents accidental deletion in production
  deletion_protection = var.deletion_protection
  
  settings {
    tier = var.tier
    
    # Disk configuration
    disk_size       = var.disk_size
    disk_type       = "PD_SSD"
    disk_autoresize = true
    
    # Backup configuration
    backup_configuration {
      enabled            = var.enable_backups
      start_time         = var.backup_start_time
      point_in_time_recovery_enabled = var.environment == "prod" ? true : false
      transaction_log_retention_days = var.environment == "prod" ? 7 : 1
      
      backup_retention_settings {
        retained_backups = var.environment == "prod" ? 30 : 7
        retention_unit   = "COUNT"
      }
    }
    
    # IP configuration
    ip_configuration {
      ipv4_enabled    = var.enable_public_ip
      require_ssl     = false # Set to true in production
      
      # Authorized networks (if public IP enabled)
      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.value
        }
      }
      
      # Allow connections from anywhere (for learning)
      # In production, restrict this!
      dynamic "authorized_networks" {
        for_each = var.enable_public_ip && length(var.authorized_networks) == 0 ? [1] : []
        content {
          name  = "allow-all"
          value = "0.0.0.0/0"
        }
      }
    }
    
    # Maintenance window
    maintenance_window {
      day          = 7 # Sunday
      hour         = 3 # 3 AM UTC
      update_track = "stable"
    }
    
    # Labels
    user_labels = {
      environment = var.environment
      managed_by  = "terraform"
      application = "plexus"
    }
    
    # Availability type
    # ZONAL = single zone (dev)
    # REGIONAL = multi-zone HA (prod)
    availability_type = var.environment == "prod" ? "REGIONAL" : "ZONAL"
  }
  
  # Lifecycle rules (Lesson 2)
  lifecycle {
    prevent_destroy = false # Set to true for production
    ignore_changes = [
      settings[0].disk_size, # Ignore auto-resize changes
    ]
  }
  
  # Timeouts for long-running operations
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

# Database within the instance
resource "google_sql_database" "database" {
  count = var.create_database ? 1 : 0
  
  name     = "plexus_db"
  instance = google_sql_database_instance.postgres.name
  project  = var.project_id
  
  charset   = "UTF8"
  collation = "en_US.UTF8"
}

# Database user
resource "google_sql_user" "app_user" {
  name     = var.database_user
  instance = google_sql_database_instance.postgres.name
  project  = var.project_id
  password = var.database_password
  
  # In production, use Secret Manager instead:
  # password = data.google_secret_manager_secret_version.db_password.secret_data
}

# Example of how to use Secret Manager (commented out)
# data "google_secret_manager_secret_version" "db_password" {
#   secret  = "plexus-db-password"
#   project = var.project_id
# }
