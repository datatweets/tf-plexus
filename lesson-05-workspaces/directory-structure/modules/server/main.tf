# Server Module
# Reusable compute instance module

resource "google_compute_instance" "server" {
  name         = var.name
  machine_type = local.machine_types[var.size]
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
      size  = local.disk_sizes[var.size]
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork

    dynamic "access_config" {
      for_each = var.enable_external_ip ? [1] : []
      content {
        # Ephemeral external IP
      }
    }
  }

  metadata_startup_script = templatefile(var.startup_script, {
    environment = var.environment
    tier        = var.tier
    name        = var.name
  })

  tags = concat(
    ["${var.environment}-tier"],
    var.tier != "" ? ["${var.tier}-server"] : [],
    var.custom_tags
  )

  labels = merge(
    {
      environment = var.environment
      tier        = var.tier
      size        = var.size
      managed_by  = "terraform"
    },
    var.custom_labels
  )

  lifecycle {
    create_before_destroy = var.environment == "prod" ? true : false
  }
}

# Static IP (optional)
resource "google_compute_address" "static_ip" {
  count = var.enable_static_ip ? 1 : 0

  name   = "${var.name}-ip"
  region = var.region
}

# Attach static IP if requested
resource "google_compute_instance" "server_with_static_ip" {
  count = var.enable_static_ip ? 1 : 0

  name         = var.name
  machine_type = local.machine_types[var.size]
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
      size  = local.disk_sizes[var.size]
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork

    access_config {
      nat_ip = google_compute_address.static_ip[0].address
    }
  }

  tags   = concat(["${var.environment}-tier"], var.tier != "" ? ["${var.tier}-server"] : [], var.custom_tags)
  labels = merge({ environment = var.environment, tier = var.tier, size = var.size, managed_by = "terraform" }, var.custom_labels)
}

# T-shirt sizing configuration
locals {
  machine_types = {
    micro  = "e2-micro"
    small  = "e2-small"
    medium = "e2-medium"
    large  = "e2-standard-2"
    xlarge = "e2-standard-4"
  }

  disk_sizes = {
    micro  = 10
    small  = 20
    medium = 50
    large  = 100
    xlarge = 200
  }
}
