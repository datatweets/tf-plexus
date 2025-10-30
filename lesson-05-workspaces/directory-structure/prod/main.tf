# Production Environment
# High-availability 3-tier setup with database

module "web_server_1" {
  source = "../modules/server"

  name        = "prod-web-1"
  size        = "medium"
  environment = "prod"
  tier        = "web"
  zone        = var.zone
  region      = var.region

  enable_external_ip = true
  enable_static_ip   = true
  startup_script     = "${path.module}/../modules/server/startup.sh.tftpl"

  custom_labels = {
    team    = "production"
    project = var.project_name
  }
}

module "web_server_2" {
  source = "../modules/server"

  name        = "prod-web-2"
  size        = "medium"
  environment = "prod"
  tier        = "web"
  zone        = var.zone
  region      = var.region

  enable_external_ip = true
  enable_static_ip   = true
  startup_script     = "${path.module}/../modules/server/startup.sh.tftpl"

  custom_labels = {
    team    = "production"
    project = var.project_name
  }
}

module "app_server_1" {
  source = "../modules/server"

  name        = "prod-app-1"
  size        = "large"
  environment = "prod"
  tier        = "app"
  zone        = var.zone
  region      = var.region

  enable_external_ip = false
  startup_script     = "${path.module}/../modules/server/startup.sh.tftpl"

  custom_labels = {
    team    = "production"
    project = var.project_name
  }
}

module "app_server_2" {
  source = "../modules/server"

  name        = "prod-app-2"
  size        = "large"
  environment = "prod"
  tier        = "app"
  zone        = var.zone
  region      = var.region

  enable_external_ip = false
  startup_script     = "${path.module}/../modules/server/startup.sh.tftpl"

  custom_labels = {
    team    = "production"
    project = var.project_name
  }
}

# Database server
module "db_server" {
  source = "../modules/server"

  name        = "prod-db"
  size        = "xlarge"
  environment = "prod"
  tier        = "database"
  zone        = var.zone
  region      = var.region

  enable_external_ip = false
  startup_script     = "${path.module}/../modules/server/startup.sh.tftpl"

  custom_labels = {
    team    = "production"
    project = var.project_name
  }
}

# Production-only: Monitoring server
resource "google_compute_instance" "monitoring" {
  name         = "prod-monitoring"
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

  tags = ["monitoring", "prod-tier"]

  labels = {
    environment = "prod"
    tier        = "monitoring"
    managed_by  = "terraform"
    team        = "production"
    project     = var.project_name
  }
}
