terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

resource "google_compute_instance" "vm" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  
  tags = var.tags
  
  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = var.disk_size_gb
      type  = var.disk_type
    }
  }
  
  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    
    # Conditionally assign external IP
    dynamic "access_config" {
      for_each = var.assign_external_ip ? [1] : []
      content {
        # Ephemeral IP
      }
    }
  }
  
  metadata = var.metadata
  
  labels = merge(
    {
      managed_by = "terraform"
      module     = "compute"
    },
    var.labels
  )
  
  allow_stopping_for_update = var.allow_stopping_for_update
  
  lifecycle {
    create_before_destroy = var.enable_create_before_destroy
  }
}
