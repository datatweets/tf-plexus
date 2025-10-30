# Monitoring Module
# Creates monitoring/bastion server

resource "google_compute_instance" "monitoring" {
  name         = var.name
  machine_type = var.environment == "production" ? "e2-medium" : "e2-micro"
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

    # External IP for SSH access
    access_config {
      # Ephemeral IP
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y prometheus grafana monitoring-plugins
    
    # Configure Prometheus
    cat > /etc/prometheus/prometheus.yml <<CONFIG
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'infrastructure'
    static_configs:
      - targets: ${jsonencode(var.monitored_instances)}
CONFIG
    
    systemctl enable prometheus
    systemctl restart prometheus
    
    # Start Grafana
    systemctl enable grafana-server
    systemctl start grafana-server
  EOF

  tags = ["monitoring"]

  labels = var.labels
}
