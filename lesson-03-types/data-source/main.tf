# Data Sources Example - Query Existing GCP Resources
# This example demonstrates using data sources to reference existing infrastructure

# Data source: Get available zones in a region
data "google_compute_zones" "available" {
  region = var.region
  status = "UP"
}

# Data source: Get latest Debian image
data "google_compute_image" "debian" {
  family  = "debian-11"
  project = "debian-cloud"
}

# Data source: Get latest Ubuntu image
data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

# Data source: Get current project information
data "google_project" "current" {
  project_id = var.project_id
}

# Data source: Look up existing network (if it exists)
data "google_compute_network" "existing" {
  count = var.use_existing_network ? 1 : 0
  name  = var.existing_network_name
}

# Data source: Get default network
data "google_compute_network" "default" {
  name = "default"
}

# Create instances using data from data sources
resource "google_compute_instance" "servers" {
  count = var.instance_count

  name         = "${var.instance_name}-${count.index}"
  machine_type = var.machine_type
  
  # Use discovered zone (round-robin distribution)
  zone = element(data.google_compute_zones.available.names, count.index)

  boot_disk {
    initialize_params {
      # Use the latest Debian image from data source
      image = data.google_compute_image.debian.self_link
      size  = 20
    }
  }

  network_interface {
    # Use existing network if specified, otherwise use default
    network = var.use_existing_network ? data.google_compute_network.existing[0].self_link : data.google_compute_network.default.self_link
    
    access_config {
      # Ephemeral IP
    }
  }

  metadata = {
    debian-version  = data.google_compute_image.debian.name
    ubuntu-version  = data.google_compute_image.ubuntu.name
    project-number  = data.google_project.current.number
    available-zones = join(",", data.google_compute_zones.available.names)
  }

  labels = {
    environment    = "demo"
    managed_by     = "terraform"
    image_family   = data.google_compute_image.debian.family
    project_name   = data.google_project.current.name
  }

  tags = ["data-source-demo"]
}

# Create instance using Ubuntu image
resource "google_compute_instance" "ubuntu_server" {
  count = var.create_ubuntu_instance ? 1 : 0

  name         = "${var.instance_name}-ubuntu"
  machine_type = var.machine_type
  zone         = data.google_compute_zones.available.names[0]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    network = data.google_compute_network.default.self_link
    access_config {}
  }

  labels = {
    os_type = "ubuntu"
  }
}

# Example: Create disk using discovered zone
resource "google_compute_disk" "data" {
  count = var.create_data_disk ? 1 : 0

  name = "${var.instance_name}-data-disk"
  type = "pd-standard"
  size = 50
  
  # Use first available zone
  zone = data.google_compute_zones.available.names[0]

  labels = {
    discovered_zone = replace(data.google_compute_zones.available.names[0], "-", "_")
  }
}
