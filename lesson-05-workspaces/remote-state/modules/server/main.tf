/**
 * Server Module
 * 
 * Creates compute instances with configurable sizes.
 * Used in compute layer that depends on networking layer.
 */

# T-shirt sizing for machine types and disks
locals {
  machine_types = {
    micro  = "e2-micro"
    small  = "e2-small"
    medium = "e2-medium"
    large  = "e2-standard-2"
  }

  disk_sizes = {
    micro  = 10
    small  = 20
    medium = 50
    large  = 100
  }

  machine_type = local.machine_types[var.size]
  disk_size    = local.disk_sizes[var.size]
}

# Compute Instance
resource "google_compute_instance" "server" {
  name         = var.name
  machine_type = local.machine_type
  zone         = var.zone
  project      = var.project_id

  tags = concat(
    [var.environment, var.tier],
    var.enable_external_ip ? ["web", "ssh"] : [],
    var.custom_tags
  )

  labels = merge(
    {
      environment = var.environment
      tier        = var.tier
      managed_by  = "terraform"
      size        = var.size
    },
    var.custom_labels
  )

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = local.disk_size
      type  = "pd-standard"
    }
  }

  # Network interface (uses subnet from networking layer)
  network_interface {
    subnetwork = var.subnetwork
    
    # Conditionally add external IP
    dynamic "access_config" {
      for_each = var.enable_external_ip ? [1] : []
      content {
        # Ephemeral IP
      }
    }
  }

  # Startup script
  metadata_startup_script = templatefile("${path.module}/startup.sh.tftpl", {
    environment = var.environment
    tier        = var.tier
    name        = var.name
  })

  metadata = {
    enable-oslogin = "TRUE"
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }
}
