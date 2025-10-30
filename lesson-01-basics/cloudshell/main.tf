# Configure the Google Cloud Provider
# This tells Terraform to use GCP and which project to deploy resources into
provider "google" {
  project = var.project_id  # Reference the variable defined below
  region  = "us-central1"   # Default region for resources
}

# Define a variable to accept the project ID as input
# This makes the code reusable across different projects
# The actual value comes from terraform.tfvars file
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

# Define a Compute Engine VM instance resource
resource "google_compute_instance" "this" {
  name         = "cloudshell"
  machine_type = "e2-small"
  zone         = "us-central1-a"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network = "default"
  }
}
