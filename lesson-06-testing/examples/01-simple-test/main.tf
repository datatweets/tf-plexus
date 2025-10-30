terraform {
  required_version = ">= 1.6"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_instance" "test_vm" {
  name         = "test-instance"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 10
    }
  }

  network_interface {
    network = "default"
    
    # No external IP for cost savings in tests
    access_config {
      # Ephemeral IP
    }
  }

  tags = var.tags

  labels = {
    environment = "test"
    managed_by  = "terraform"
  }

  metadata = {
    enable-oslogin = "true"
  }

  # Allow Terraform to destroy this instance
  allow_stopping_for_update = true
}
