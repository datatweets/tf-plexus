# Dynamic Blocks Example - Attach Multiple Disks to a VM
# This example demonstrates using dynamic blocks to generate repeated nested blocks

# Create multiple data disks
resource "google_compute_disk" "data_disks" {
  for_each = var.disks

  name = each.key
  type = each.value["type"]
  size = each.value["size"]
  zone = var.zone

  labels = {
    environment = "demo"
    managed_by  = "terraform"
    purpose     = each.key
  }
}

# Create VM with dynamically attached disks
resource "google_compute_instance" "server" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = var.boot_disk_size
    }
  }

  # Dynamic block - generates multiple attached_disk blocks
  dynamic "attached_disk" {
    for_each = var.disks
    
    content {
      source      = google_compute_disk.data_disks[attached_disk.key].name
      mode        = attached_disk.value["mode"]
      device_name = attached_disk.key
    }
  }

  network_interface {
    network = "default"
    access_config {
      # Ephemeral IP
    }
  }

  metadata = {
    startup-script = <<-EOT
      #!/bin/bash
      echo "Server with ${length(var.disks)} attached disks"
      lsblk
    EOT
  }

  tags = ["dynamic-block-demo"]

  labels = {
    environment = "demo"
    managed_by  = "terraform"
    demo_type   = "dynamic-blocks"
  }
}

# Example: Dynamic firewall rules
resource "google_compute_firewall" "allow_ports" {
  name    = "${var.instance_name}-allow-ports"
  network = "default"

  # Dynamic block for multiple allow rules
  dynamic "allow" {
    for_each = var.firewall_rules
    
    content {
      protocol = allow.value.protocol
      ports    = [allow.value.port]
    }
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["dynamic-block-demo"]

  description = "Allow multiple ports using dynamic blocks"
}

# Example: Instance with multiple network interfaces (advanced)
resource "google_compute_instance" "multi_nic" {
  count = var.create_multi_nic ? 1 : 0

  name         = "${var.instance_name}-multi-nic"
  machine_type = "e2-small"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.boot_image
    }
  }

  # Dynamic block for multiple network interfaces
  dynamic "network_interface" {
    for_each = var.network_interfaces
    
    content {
      network    = network_interface.value["network"]
      subnetwork = network_interface.value["subnetwork"]
      
      # Nested dynamic block for access_config
      dynamic "access_config" {
        for_each = network_interface.value["external_ip"] ? [1] : []
        
        content {
          # Ephemeral IP
        }
      }
    }
  }

  tags = ["multi-nic-demo"]
}
