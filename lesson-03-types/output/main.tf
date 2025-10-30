# Output Example - Master Output Expressions
# This example demonstrates various output patterns and expressions

# Create multiple VM instances for output demonstrations
resource "google_compute_instance" "web_servers" {
  count = var.server_count

  name         = "${var.server_name}-${count.index}"
  machine_type = var.machine_type
  zone         = element(var.zones, count.index)

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }

  network_interface {
    network = "default"
    
    access_config {
      # Ephemeral IP
    }
  }

  metadata = {
    server_index = count.index
    server_role  = "web"
  }

  labels = {
    environment = var.environment
    tier        = "frontend"
    index       = count.index
  }

  tags = ["http-server", "web-tier"]
}

# Create database servers with for_each
resource "google_compute_instance" "db_servers" {
  for_each = var.db_configs

  name         = each.key
  machine_type = each.value.machine_type
  zone         = each.value.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = each.value.disk_size
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    role     = "database"
    db_type  = each.value.db_type
  }

  labels = {
    environment = var.environment
    tier        = "backend"
    db_type     = each.value.db_type
  }

  tags = ["db-server", "backend-tier"]
}

# Create load balancer instance
resource "google_compute_instance" "load_balancer" {
  count = var.create_lb ? 1 : 0

  name         = "${var.server_name}-lb"
  machine_type = "e2-small"
  zone         = var.zones[0]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    role    = "load_balancer"
    backend = join(",", google_compute_instance.web_servers[*].name)
  }

  labels = {
    environment = var.environment
    tier        = "frontend"
  }

  tags = ["lb-server", "http-server"]
}

# Create disks for attachment examples
resource "google_compute_disk" "data_disks" {
  count = var.server_count

  name = "${var.server_name}-data-${count.index}"
  type = "pd-standard"
  zone = element(var.zones, count.index)
  size = 50

  labels = {
    attached_to = "${var.server_name}-${count.index}"
  }
}

# Create VPC for networking outputs
resource "google_compute_network" "vpc" {
  name                    = "${var.server_name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnets" {
  count = 2

  name          = "${var.server_name}-subnet-${count.index}"
  ip_cidr_range = cidrsubnet("10.0.0.0/16", 8, count.index)
  region        = var.region
  network       = google_compute_network.vpc.id
}
