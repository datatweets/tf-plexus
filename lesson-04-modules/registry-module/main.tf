# Registry Module Example - Using Public Modules
# Demonstrates using modules from Terraform Registry

# Use Google's official MIG (Managed Instance Group) module from registry
# MIG is required for load balancer backend
module "web_servers" {
  source  = "terraform-google-modules/vm/google//modules/mig"
  version = "~> 11.0"

  project_id        = var.project_id
  region            = var.region
  hostname          = "web"
  instance_template = module.web_instance_template.self_link
  target_size       = 2
}

# Use official instance template module
module "web_instance_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "~> 11.0"

  project_id        = var.project_id
  region            = var.region
  subnetwork        = google_compute_subnetwork.main.name
  subnetwork_project = var.project_id
  service_account = {
    email  = ""
    scopes = ["cloud-platform"]
  }

  name_prefix          = "web-template"
  machine_type         = "e2-medium"
  source_image_family  = "debian-11"
  source_image_project = "debian-cloud"
  disk_size_gb         = 20
  disk_type            = "pd-standard"

  tags = ["web-server", "http-server"]

  labels = {
    environment = "demo"
    tier        = "web"
  }
}

# Use Google's network module
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 9.0"

  project_id   = var.project_id
  network_name = "${var.project_name}-vpc"
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name   = "${var.project_name}-subnet"
      subnet_ip     = "10.0.0.0/24"
      subnet_region = var.region
    }
  ]

  firewall_rules = [
    {
      name        = "allow-ssh"
      direction   = "INGRESS"
      priority    = 1000
      ranges      = ["0.0.0.0/0"]
      target_tags = ["web-server"]
      allow = [{
        protocol = "tcp"
        ports    = ["22"]
      }]
    },
    {
      name        = "allow-http"
      direction   = "INGRESS"
      priority    = 1000
      ranges      = ["0.0.0.0/0"]
      target_tags = ["web-server"]
      allow = [{
        protocol = "tcp"
        ports    = ["80", "443"]
      }]
    }
  ]
}

# Additional subnet created directly (not all resources need modules)
resource "google_compute_subnetwork" "main" {
  name          = "${var.project_name}-main-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = module.vpc.network_id
}

# Use Cloud SQL module for managed database
module "postgresql" {
  source  = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version = "~> 20.0"

  name                = "${var.project_name}-db"
  project_id          = var.project_id
  database_version    = "POSTGRES_15"
  region              = var.region
  tier                = "db-f1-micro"
  deletion_protection = false

  # Create postgres superuser with password
  user_name     = "postgres"
  user_password = "Postgres123!"

  ip_configuration = {
    ipv4_enabled        = true
    private_network     = null
    require_ssl         = false
    allocated_ip_range  = null
    authorized_networks = []
  }
}

# Use Cloud Storage module for file storage
module "gcs_buckets" {
  source  = "terraform-google-modules/cloud-storage/google"
  version = "~> 6.0"

  project_id = var.project_id
  names      = ["${var.project_name}-assets", "${var.project_name}-backups"]
  prefix     = var.project_name
  location   = var.region

  storage_class = "STANDARD"
  
  labels = {
    environment = "demo"
    managed_by  = "terraform"
  }

  lifecycle_rules = [{
    action = {
      type = "Delete"
    }
    condition = {
      age        = 90
      with_state = "ANY"
    }
  }]
}

# Use Load Balancer module
module "load_balancer" {
  source  = "GoogleCloudPlatform/lb-http/google"
  version = "~> 11.0"

  project = var.project_id
  name    = "${var.project_name}-lb"

  firewall_networks = [module.vpc.network_name]
  target_tags       = ["web-server"]

  backends = {
    default = {
      protocol    = "HTTP"
      port        = 80
      port_name   = "http"
      timeout_sec = 10
      enable_cdn  = false

      health_check = {
        request_path = "/"
        port         = 80
      }

      groups = [
        {
          group = module.web_servers.instance_group
        }
      ]

      iap_config = {
        enable = false
      }

      log_config = {
        enable = false
      }
    }
  }
}
