# Example: lifecycle meta-argument demonstrations
# This shows create_before_destroy, prevent_destroy, and ignore_changes

# Example 1: create_before_destroy - Zero downtime updates
resource "google_compute_instance" "web" {
  name         = "web-server-ha"
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
  
  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    echo "<h1>Web Server - High Availability</h1>" > /var/www/html/index.html
  EOF
  
  tags = ["web-server"]
  
  lifecycle {
    # Create new instance before destroying old one
    # Ensures zero downtime during updates that require replacement
    create_before_destroy = true
  }
}

# Example 2: prevent_destroy - Protect critical resources
resource "google_storage_bucket" "critical_data" {
  name          = "${var.project_id}-critical-data"
  location      = "US"
  force_destroy = false
  
  versioning {
    enabled = true
  }
  
  lifecycle {
    # Prevent accidental deletion of production data
    prevent_destroy = true
  }
}

# Example 3: ignore_changes - Harmony with external tools
resource "google_compute_instance" "monitored" {
  name         = "monitored-server"
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
  
  labels = {
    environment = "production"
    managed_by  = "terraform"
  }
  
  metadata = {
    created_by = "terraform"
  }
  
  tags = ["monitored"]
  
  lifecycle {
    # Ignore changes made by external monitoring and cost management tools
    ignore_changes = [
      labels,    # Cost management tools may add labels
      metadata,  # Monitoring tools may add metadata
      tags,      # Security tools may add tags
    ]
  }
}

# Example 4: Combined lifecycle rules
resource "google_compute_instance" "production_db" {
  name         = "production-database"
  machine_type = "n1-standard-2"
  zone         = "us-central1-a"
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 100
    }
  }
  
  network_interface {
    network = "default"
  }
  
  labels = {
    environment = "production"
    purpose     = "database"
  }
  
  tags = ["database", "production"]
  
  lifecycle {
    # Protect from accidental deletion
    prevent_destroy = true
    
    # Zero downtime updates
    create_before_destroy = true
    
    # Allow external tools to manage certain attributes
    ignore_changes = [
      labels["cost-center"],  # Cost management adds this
      metadata["monitoring"], # Monitoring adds this
    ]
  }
}
