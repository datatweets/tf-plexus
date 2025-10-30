# Configure the Google Cloud Provider with remote backend
terraform {
  required_version = ">= 1.9"
  
  # Backend configuration - where to store state
  # This enables team collaboration and state locking
  backend "gcs" {
    bucket = "my-terraform-prj-476214-terraform-state"  # Your state bucket name
    prefix = "terraform/state"                # Path within the bucket
  }
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
}

# Define a variable to accept the project ID as input
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

# Simple compute instance for demonstrating backend state
resource "google_compute_instance" "this" {
  name         = "backend-demo"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  
  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }
  
  tags = ["backend-demo"]
}

# Output the instance details
output "instance_name" {
  description = "Name of the instance"
  value       = google_compute_instance.this.name
}

output "instance_ip" {
  description = "External IP address"
  value       = google_compute_instance.this.network_interface[0].access_config[0].nat_ip
}
