# Example: Create VPC network and subnets using for_each
# This demonstrates the for_each meta-argument with maps

# Create a VPC network
resource "google_compute_network" "this" {
  name                    = var.network_name
  auto_create_subnetworks = false
  
  lifecycle {
    prevent_destroy = false  # Set to true in production!
  }
}

# Create subnetworks using for_each with a map
# Each subnet has a meaningful key (iowa, virginia, singapore)
# instead of numeric indices (0, 1, 2)
resource "google_compute_subnetwork" "this" {
  for_each = var.subnets
  
  # each.key = "iowa", "virginia", or "singapore"
  name = each.key
  
  # each.value = the object with region and ip_cidr_range
  region        = each.value.region
  ip_cidr_range = each.value.ip_cidr_range
  
  # Use self_link for unambiguous reference
  network = google_compute_network.this.self_link
  
  # Enable private Google access
  private_ip_google_access = true
  
  # Explicit dependency to ensure network is ready
  depends_on = [google_compute_network.this]
  
  lifecycle {
    ignore_changes = [
      secondary_ip_range,  # Allow external tools to manage secondary ranges
    ]
  }
}

# Create a VM in each subnet using for_each
resource "google_compute_instance" "vm" {
  for_each = var.subnets
  
  # Use the key for unique naming
  name         = "vm-${each.key}"
  machine_type = "e2-micro"
  
  # Extract zone from region (add -a to region name)
  zone = "${each.value.region}-a"
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }
  
  network_interface {
    # Reference the subnet with the same key using self_link
    subnetwork = google_compute_subnetwork.this[each.key].self_link
    
    access_config {
      // Ephemeral public IP
    }
  }
  
  metadata_startup_script = <<-EOF
    #!/bin/bash
    echo "Hello from ${each.key}!" > /tmp/hello.txt
    apt-get update
    apt-get install -y nginx
    echo "<h1>VM in ${each.key}</h1>" > /var/www/html/index.html
  EOF
  
  labels = {
    environment = "demo"
    region      = each.key
  }
  
  tags = ["${each.key}-vm", "web-server"]
  
  lifecycle {
    create_before_destroy = true
    
    ignore_changes = [
      labels,    # Allow cost management tools to add labels
      metadata,  # Allow monitoring tools to add metadata
    ]
  }
}

# Create a firewall rule to allow SSH
resource "google_compute_firewall" "ssh" {
  name    = "allow-ssh"
  network = google_compute_network.this.self_link
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  source_ranges = ["0.0.0.0/0"]  # Adjust for security!
  target_tags   = ["web-server"]
}

# Create a firewall rule to allow HTTP
resource "google_compute_firewall" "http" {
  name    = "allow-http"
  network = google_compute_network.this.self_link
  
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}
