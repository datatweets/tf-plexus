# Compute Instance Module
# This is a reusable child module for creating GCP compute instances

resource "google_compute_instance" "this" {
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.boot_disk_image
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  network_interface {
    network = var.network

    access_config {
      # Ephemeral IP
    }
  }

  metadata = var.metadata

  tags = var.tags

  labels = var.labels

  service_account {
    email  = var.service_account_email
    scopes = var.service_account_scopes
  }

  allow_stopping_for_update = true
}
