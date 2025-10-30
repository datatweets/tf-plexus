terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "${var.environment}-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.environment}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id
}

# Firewall - Allow SSH
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.environment}-allow-ssh"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

# VM Instances
resource "google_compute_instance" "vm" {
  count        = var.instance_count
  name         = "${var.environment}-vm-${count.index + 1}"
  machine_type = var.machine_type
  zone         = "${var.region}-a"
  project      = var.project_id

  tags = [var.environment, "managed-by-terraform", "ssh"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = var.disk_size_gb
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
      # Ephemeral public IP
    }
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
    deployed_by = "azure-pipelines"
  }

  metadata = {
    environment = var.environment
    enable-oslogin = "TRUE"
  }

  lifecycle {
    create_before_destroy = true
  }
}
