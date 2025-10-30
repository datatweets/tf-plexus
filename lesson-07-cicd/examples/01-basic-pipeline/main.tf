terraform {
  required_version = ">= 1.6"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  
  # Backend configuration
  # Bucket name provided at runtime: terraform init -backend-config="bucket=BUCKET_NAME"
  backend "gcs" {
    # prefix = "examples/01-basic-pipeline"  # Set in pipeline
  }
}

# Provider configuration
provider "google" {
  project = var.project_id
  region  = var.region
}

# Simple test VM - for validation only (CI/CD Pipeline Auto-Trigger Test)
resource "google_compute_instance" "pipeline_test_vm" {
  name         = "pipeline-test-vm-${var.environment}"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    
    # No external IP (more secure and cost-effective)
    # access_config {}  # Uncomment to add external IP
  }

  # Tags for firewall rules
  tags = ["pipeline-test", var.environment]

  # Labels for resource management
  labels = {
    environment = var.environment
    managed_by  = "terraform HCL"
    project     = "cicd-tutorial"
  }

  # Metadata
  metadata = {
    enable-oslogin = "true"
    env            = var.environment
  }

  # Lifecycle
  lifecycle {
    create_before_destroy = true
  }

  # Allow stopping for updates
  allow_stopping_for_update = true
}

# Firewall rule example (commented out to avoid conflicts with default rules)
# Uncomment if you need custom firewall rules
/*
resource "google_compute_firewall" "ssh" {
  name    = "allow-ssh-${var.environment}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]  # Restrict in production!
  target_tags   = ["pipeline-test"]
}
*/
