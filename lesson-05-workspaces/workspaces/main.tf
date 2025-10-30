# Terraform Workspaces for Environment Management

resource "google_compute_instance" "web" {
  count = local.config.web_count

  name         = "${terraform.workspace}-web-${count.index + 1}"
  machine_type = local.config.web_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = local.config.web_disk_size
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    cat > /var/www/html/index.html <<HTML
    <!DOCTYPE html>
    <html>
    <head><title>Web Server - ${terraform.workspace}</title></head>
    <body>
      <h1>${terraform.workspace} Environment</h1>
      <h2>Web Server ${count.index + 1}</h2>
      <p>Workspace: ${terraform.workspace}</p>
      <p>Instance: $(hostname)</p>
      <p>Machine Type: ${local.config.web_machine_type}</p>
    </body>
    </html>
HTML
    systemctl enable nginx
    systemctl restart nginx
  EOF

  tags = ["web-server", "${terraform.workspace}-tier"]

  labels = {
    environment = terraform.workspace
    tier        = "web"
    managed_by  = "terraform"
  }
}

resource "google_compute_instance" "app" {
  count = local.config.app_count

  name         = "${terraform.workspace}-app-${count.index + 1}"
  machine_type = local.config.app_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = local.config.app_disk_size
    }
  }

  network_interface {
    network = "default"
    # No external IP for app servers
  }

  tags = ["app-server", "${terraform.workspace}-tier"]

  labels = {
    environment = terraform.workspace
    tier        = "app"
    managed_by  = "terraform"
  }
}

# Monitoring server (only in production)
resource "google_compute_instance" "monitoring" {
  count = terraform.workspace == "prod" ? 1 : 0

  name         = "${terraform.workspace}-monitoring"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 30
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y prometheus grafana
    systemctl enable prometheus grafana-server
    systemctl start prometheus grafana-server
  EOF

  tags = ["monitoring-server"]

  labels = {
    environment = terraform.workspace
    tier        = "monitoring"
    managed_by  = "terraform"
  }
}

# Workspace-specific configuration
locals {
  # Configuration per workspace
  workspace_config = {
    default = {
      web_count        = 1
      web_machine_type = "e2-micro"
      web_disk_size    = 10
      app_count        = 1
      app_machine_type = "e2-micro"
      app_disk_size    = 10
    }
    dev = {
      web_count        = 2
      web_machine_type = "e2-micro"
      web_disk_size    = 10
      app_count        = 2
      app_machine_type = "e2-small"
      app_disk_size    = 20
    }
    staging = {
      web_count        = 2
      web_machine_type = "e2-small"
      web_disk_size    = 20
      app_count        = 2
      app_machine_type = "e2-medium"
      app_disk_size    = 30
    }
    prod = {
      web_count        = 3
      web_machine_type = "e2-medium"
      web_disk_size    = 50
      app_count        = 3
      app_machine_type = "e2-standard-2"
      app_disk_size    = 100
    }
  }

  # Select configuration for current workspace
  config = local.workspace_config[terraform.workspace]
}
