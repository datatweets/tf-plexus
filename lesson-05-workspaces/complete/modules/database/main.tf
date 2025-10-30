/**
 * Database Module
 * 
 * Creates a Cloud SQL (MySQL) database instance.
 * Uses random_string to ensure globally unique instance names.
 */

# Random suffix for unique database name
resource "random_string" "db_suffix" {
  length  = 6
  special = false
  upper   = false
  numeric = true
  lower   = true
}

# Cloud SQL Database Instance
resource "google_sql_database_instance" "main" {
  name             = "${var.environment}-mysql-${random_string.db_suffix.result}"
  database_version = var.database_version
  region           = var.region
  project          = var.project_id

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_size         = var.disk_size
    disk_type         = "PD_SSD"

    backup_configuration {
      enabled            = var.backup_enabled
      start_time         = "03:00"
      binary_log_enabled = true
    }

    ip_configuration {
      ipv4_enabled    = true
      private_network = var.network_self_link
      require_ssl     = var.require_ssl
    }

    database_flags {
      name  = "max_connections"
      value = var.max_connections
    }
  }

  deletion_protection = var.deletion_protection

  depends_on = [var.network_self_link]
}

# Database
resource "google_sql_database" "database" {
  name     = var.database_name
  instance = google_sql_database_instance.main.name
  project  = var.project_id
}

# Database User
resource "google_sql_user" "user" {
  name     = var.db_user
  instance = google_sql_database_instance.main.name
  password = var.db_password
  project  = var.project_id
}
