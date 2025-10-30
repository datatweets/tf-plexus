# Web Tier Module
# Creates web server instances with nginx

resource "google_compute_instance" "web" {
  count = var.instance_count

  name         = "${var.project_id}-web-${count.index + 1}"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
    }
  }

  network_interface {
    network    = var.network_id
    subnetwork = var.subnet_id

    # External IP for internet access
    access_config {
      # Ephemeral IP
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    
    # Create simple web page
    cat > /var/www/html/index.html <<HTML
    <!DOCTYPE html>
    <html>
    <head><title>Web Server $(hostname)</title></head>
    <body>
      <h1>Web Tier - Server $(hostname)</h1>
      <p>Instance: ${count.index + 1} of ${var.instance_count}</p>
      <p>Environment: ${var.environment}</p>
      <p>Timestamp: $(date)</p>
    </body>
    </html>
HTML
    
    systemctl enable nginx
    systemctl restart nginx
  EOF

  tags = concat(["web-tier"], var.labels != null ? [for k, v in var.labels : "${k}-${v}"] : [])

  labels = var.labels
}
