# Networking Module
# Creates VPC network with multiple subnets and firewall rules

resource "google_compute_network" "vpc" {
  name                    = "${var.project_name}-${var.environment}-network"
  auto_create_subnetworks = false
}

# Frontend subnet (for web tier)
resource "google_compute_subnetwork" "frontend" {
  name          = "${var.project_name}-${var.environment}-frontend"
  ip_cidr_range = var.frontend_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Application subnet (for app tier)
resource "google_compute_subnetwork" "application" {
  name          = "${var.project_name}-${var.environment}-application"
  ip_cidr_range = var.application_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Database subnet (for data tier)
resource "google_compute_subnetwork" "database" {
  name          = "${var.project_name}-${var.environment}-database"
  ip_cidr_range = var.database_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Management subnet (for monitoring/bastion)
resource "google_compute_subnetwork" "management" {
  name          = "${var.project_name}-${var.environment}-management"
  ip_cidr_range = var.management_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Firewall rules

# Allow HTTP/HTTPS from internet to frontend
resource "google_compute_firewall" "frontend_ingress" {
  name    = "${var.project_name}-${var.environment}-frontend-ingress"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-tier"]
}

# Allow traffic from frontend to application
resource "google_compute_firewall" "frontend_to_app" {
  name    = "${var.project_name}-${var.environment}-frontend-to-app"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["8080", "8443"]
  }

  source_tags = ["web-tier"]
  target_tags = ["app-tier"]
}

# Allow traffic from application to database
resource "google_compute_firewall" "app_to_database" {
  name    = "${var.project_name}-${var.environment}-app-to-database"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["5432", "3306"]
  }

  source_tags = ["app-tier"]
  target_tags = ["database-tier"]
}

# Allow SSH from management subnet
resource "google_compute_firewall" "management_ssh" {
  name    = "${var.project_name}-${var.environment}-management-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.management_cidr]
  target_tags   = ["web-tier", "app-tier", "database-tier"]
}

# Allow health checks from GCP
resource "google_compute_firewall" "health_checks" {
  name    = "${var.project_name}-${var.environment}-health-checks"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"]
  }

  # GCP health check ranges
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["web-tier", "app-tier"]
}

# Allow internal communication
resource "google_compute_firewall" "internal" {
  name    = "${var.project_name}-${var.environment}-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = [
    var.frontend_cidr,
    var.application_cidr,
    var.database_cidr,
    var.management_cidr
  ]
}
