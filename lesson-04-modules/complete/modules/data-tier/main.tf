# Data Tier Module
# Creates database server instance

resource "google_compute_instance" "database" {
  name         = "${var.project_id}-db-primary"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = var.disk_size_gb
    }
  }

  # Additional data disk
  attached_disk {
    source      = google_compute_disk.db_data.id
    device_name = "db-data"
    mode        = "READ_WRITE"
  }

  network_interface {
    network    = var.network_id
    subnetwork = var.subnet_id
    # No external IP for database
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y postgresql postgresql-contrib
    
    # Configure PostgreSQL
    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf
    
    # Allow connections from VPC
    echo "host    all    all    10.0.0.0/8    md5" >> /etc/postgresql/*/main/pg_hba.conf
    
    systemctl restart postgresql
    
    # Create database
    sudo -u postgres psql <<SQL
    CREATE DATABASE appdb;
    CREATE USER appuser WITH PASSWORD 'changeme';
    GRANT ALL PRIVILEGES ON DATABASE appdb TO appuser;
SQL
  EOF

  tags = concat(["database-tier"], var.labels != null ? [for k, v in var.labels : "${k}-${v}"] : [])

  labels = var.labels

  # Prevent accidental deletion in production
  lifecycle {
    prevent_destroy = false  # Set to true for production
  }
}

# Data disk for database
resource "google_compute_disk" "db_data" {
  name = "${var.project_id}-db-data"
  type = "pd-ssd"
  zone = var.zone
  size = var.disk_size_gb

  labels = var.labels
}

# Snapshot schedule for backups (if enabled)
resource "google_compute_resource_policy" "backup_policy" {
  count = var.enable_backup ? 1 : 0

  name   = "${var.project_id}-db-backup-policy"
  region = var.region

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "04:00"
      }
    }

    retention_policy {
      max_retention_days    = var.environment == "production" ? 30 : 7
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
  }
}

# Attach backup policy to disk
resource "google_compute_disk_resource_policy_attachment" "backup" {
  count = var.enable_backup ? 1 : 0

  name = google_compute_resource_policy.backup_policy[0].name
  disk = google_compute_disk.db_data.name
  zone = var.zone
}
