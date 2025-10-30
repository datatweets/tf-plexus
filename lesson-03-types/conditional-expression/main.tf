# Conditional Expression Example - Flexible Resource Creation
# This example demonstrates conditional logic with the ternary operator

# Conditionally create static IP address
resource "google_compute_address" "static" {
  count = var.assign_static_ip ? 1 : 0

  name         = "${var.instance_name}-static-ip"
  address_type = "EXTERNAL"
  region       = var.region
}

# Main compute instance with conditional configuration
resource "google_compute_instance" "server" {
  name         = var.instance_name
  machine_type = var.environment == "prod" ? var.prod_machine_type : var.dev_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = var.environment == "prod" ? 100 : 20
      type  = var.environment == "prod" ? "pd-ssd" : "pd-standard"
    }
  }

  network_interface {
    network = "default"

    # Conditionally create access_config block for external IP
    dynamic "access_config" {
      for_each = var.assign_external_ip ? [1] : []

      content {
        # If static IP exists, use it; otherwise use ephemeral
        nat_ip = var.assign_static_ip ? google_compute_address.static[0].address : null
      }
    }
  }

  # Conditional metadata
  metadata = merge(
    {
      environment = var.environment
    },
    var.enable_startup_script ? {
      startup-script = file("${path.module}/startup.sh")
    } : {}
  )

  # Conditional tags
  tags = concat(
    ["http-server"],
    var.environment == "prod" ? ["production", "critical"] : ["development"]
  )

  # Conditional labels
  labels = merge(
    {
      environment = var.environment
      managed_by  = "terraform"
    },
    var.environment == "prod" ? {
      tier     = "production"
      critical = "true"
      sla      = "99.9"
    } : {
      tier = "development"
      cost = "optimized"
    }
  )

  # Enable deletion protection only for production
  deletion_protection = var.environment == "prod" ? true : false
}

# Conditionally create firewall rule
resource "google_compute_firewall" "allow_http" {
  count = var.allow_http_traffic ? 1 : 0

  name    = "${var.instance_name}-allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = var.environment == "prod" ? var.prod_allowed_ips : ["0.0.0.0/0"]
  target_tags   = ["http-server"]

  description = "Allow HTTP/HTTPS traffic ${var.environment == "prod" ? "from allowed IPs only" : "from anywhere"}"
}

# Conditionally create backup disk
resource "google_compute_disk" "backup" {
  count = var.enable_backups ? 1 : 0

  name = "${var.instance_name}-backup"
  type = "pd-standard"
  size = var.backup_disk_size
  zone = var.zone

  labels = {
    purpose     = "backup"
    environment = var.environment
  }
}

# Conditionally attach backup disk
resource "google_compute_attached_disk" "backup_attachment" {
  count = var.enable_backups ? 1 : 0

  disk     = google_compute_disk.backup[0].id
  instance = google_compute_instance.server.id
  mode     = "READ_WRITE"
}

# Example: Multiple instances based on environment
resource "google_compute_instance" "replicas" {
  count = var.environment == "prod" ? var.replica_count : 0

  name         = "${var.instance_name}-replica-${count.index}"
  machine_type = var.prod_machine_type
  zone         = element(var.zones, count.index)

  boot_disk {
    initialize_params {
      image = var.boot_image
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  tags = ["replica", "production"]
}
