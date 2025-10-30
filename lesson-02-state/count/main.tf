# Example: Create multiple web servers using count
# This demonstrates the count meta-argument for creating multiple resources

resource "google_compute_instance" "web" {
  count = var.server_count
  
  # Use count.index to create unique names
  # format() with %02d ensures two-digit numbering: 01, 02, 03...
  name         = format("web-server-%02d", count.index + 1)
  machine_type = "e2-micro"
  
  # Distribute servers across zones using modulo operator
  # This cycles through zones: 0 % 3 = 0, 1 % 3 = 1, 2 % 3 = 2, 3 % 3 = 0...
  zone = var.zones[count.index % length(var.zones)]
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }
  
  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }
  
  # Add metadata with the server index
  metadata = {
    server_index = count.index
    server_name  = format("web-server-%02d", count.index + 1)
  }
  
  # Startup script that runs when instance starts
  metadata_startup_script = <<-EOF
    #!/bin/bash
    echo "Hello from server ${count.index + 1}!" > /tmp/hello.txt
    apt-get update
    apt-get install -y nginx
    echo "<h1>Web Server ${count.index + 1}</h1>" > /var/www/html/index.html
  EOF
  
  tags = ["web-server", "server-${count.index}"]
}
