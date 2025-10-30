# Configure the Google Cloud Provider
# This tells Terraform to use GCP and which project to deploy resources into
terraform {
  required_version = ">= 1.9"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id  # Reference the variable defined below
  region  = "us-central1"   # Default region for resources
  zone    = "us-central1-a"
}

# Define a variable to accept the project ID as input
# This makes the code reusable across different projects
# The actual value comes from terraform.tfvars file
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

# Define a Compute Engine VM instance resource
# This is used for demonstrating state management concepts
resource "google_compute_instance" "this" {
  name         = "state-file"
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
  
  metadata_startup_script = "echo 'Hello from Terraform!' > /tmp/hello.txt"
  
  tags = ["http-server"]
}

# Output the instance's external IP address
output "instance_ip" {
  description = "External IP address of the instance"
  value       = google_compute_instance.this.network_interface[0].access_config[0].nat_ip
}

# Output the instance's internal IP address
output "instance_internal_ip" {
  description = "Internal IP address of the instance"
  value       = google_compute_instance.this.network_interface[0].network_ip
}
