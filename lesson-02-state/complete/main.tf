# Create a VPC network
resource "google_compute_network" "main" {
  name                    = "main-network"
  auto_create_subnetworks = false
  
  lifecycle {
    prevent_destroy = false  # Set to true in production!
  }
}

# Create subnetworks using for_each
resource "google_compute_subnetwork" "regional" {
  for_each = var.regions
  
  name                     = "subnet-${each.key}"
  region                   = replace(each.value.zone, "/-[a-z]$/", "")  # Extract region from zone
  network                  = google_compute_network.main.self_link  # Use self_link!
  ip_cidr_range            = each.value.ip_cidr_range
  private_ip_google_access = true
  
  depends_on = [google_compute_network.main]  # Explicit dependency
  
  lifecycle {
    ignore_changes = [
      secondary_ip_range,  # Allow external tools to manage this
    ]
  }
}

# Create VMs in each subnet using for_each
resource "google_compute_instance" "regional" {
  for_each = var.regions
  
  name         = "vm-${each.key}"
  machine_type = "e2-micro"
  zone         = each.value.zone
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }
  
  network_interface {
    subnetwork = google_compute_subnetwork.regional[each.key].self_link  # Use self_link!
    
    access_config {
      // Ephemeral public IP
    }
  }
  
  metadata = {
    region = each.key
    startup-script = <<-EOF
      #!/bin/bash
      echo "Hello from ${each.key}!" > /tmp/hello.txt
      apt-get update
      apt-get install -y nginx
      echo "<h1>VM in ${each.key}</h1>" > /var/www/html/index.html
    EOF
  }
  
  labels = {
    environment = "demo"
    region      = each.key
  }
  
  tags = ["${each.key}-vm", "web-server"]
  
  lifecycle {
    create_before_destroy = true  # Zero downtime updates
    
    ignore_changes = [
      labels,    # Allow cost management tools to add labels
      metadata,  # Allow monitoring tools to add metadata
    ]
  }
}

# Create firewall rule for SSH access using count
resource "google_compute_firewall" "ssh" {
  count = 1  # Conditional: Only create if needed
  
  name    = "allow-ssh"
  network = google_compute_network.main.self_link  # Use self_link!
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  source_ranges = ["0.0.0.0/0"]  # Allow from anywhere (adjust for security!)
  target_tags   = ["web-server"]
}

# Create firewall rule for HTTP
resource "google_compute_firewall" "http" {
  name    = "allow-http"
  network = google_compute_network.main.self_link
  
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}
