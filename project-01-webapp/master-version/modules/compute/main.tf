# Compute Module - Main Configuration
# Purpose: Create web server instances and load balancer for Plexus app

# Local variables for consistent naming
locals {
  instance_name = "${var.app_name}-${var.environment}-web"
  startup_script = templatefile("${path.module}/startup.sh", {
    environment = var.environment
  })
}

# Web Server Instances
# Using count meta-argument (Lesson 2) to create multiple instances
resource "google_compute_instance" "web_servers" {
  count = var.instance_count
  
  name         = "${local.instance_name}-${count.index + 1}"
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id
  
  # Network tags for firewall rules
  tags = var.tags
  
  # Boot disk configuration
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
      type  = "pd-standard"
    }
  }
  
  # Network interface
  network_interface {
    subnetwork = var.subnet_self_link
    
    # Public IP for each instance
    # In production, you might want to remove this and use NAT
    access_config {
      // Ephemeral public IP
    }
  }
  
  # Metadata and startup script
  metadata = {
    startup-script = local.startup_script
    environment    = var.environment
    instance-index = count.index + 1
  }
  
  # Labels for resource organization
  labels = {
    environment = var.environment
    application = var.app_name
    managed_by  = "terraform"
    instance_id = tostring(count.index + 1)
  }
  
  # Service account for GCP API access
  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write"
    ]
  }
  
  # Lifecycle configuration (Lesson 2)
  # Prevent accidental deletion in production
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      metadata["ssh-keys"],
    ]
  }
  
  # Allow parallel creation
  allow_stopping_for_update = true
}

# Instance Group for Load Balancer
# This groups our instances for the load balancer backend
resource "google_compute_instance_group" "web_group" {
  count = var.enable_load_balancer ? 1 : 0
  
  name      = "${var.app_name}-${var.environment}-ig"
  zone      = var.zone
  project   = var.project_id
  
  instances = google_compute_instance.web_servers[*].id
  
  # Named port for HTTP traffic
  named_port {
    name = "http"
    port = "80"
  }
  
  # Ensure instances are created first
  depends_on = [google_compute_instance.web_servers]
  
  lifecycle {
    create_before_destroy = true
  }
}

# Health Check for Load Balancer
resource "google_compute_health_check" "http" {
  count = var.enable_load_balancer ? 1 : 0
  
  name    = "${var.app_name}-${var.environment}-hc"
  project = var.project_id
  
  timeout_sec        = 5
  check_interval_sec = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3
  
  http_health_check {
    port         = 80
    request_path = "/health"
  }
}

# Backend Service for Load Balancer
resource "google_compute_backend_service" "web_backend" {
  count = var.enable_load_balancer ? 1 : 0
  
  name          = "${var.app_name}-${var.environment}-backend"
  project       = var.project_id
  protocol      = "HTTP"
  port_name     = "http"
  timeout_sec   = 30
  health_checks = [google_compute_health_check.http[0].id]
  
  backend {
    group           = google_compute_instance_group.web_group[0].id
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0
  }
  
  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# URL Map for Load Balancer
resource "google_compute_url_map" "web_url_map" {
  count = var.enable_load_balancer ? 1 : 0
  
  name            = "${var.app_name}-${var.environment}-url-map"
  project         = var.project_id
  default_service = google_compute_backend_service.web_backend[0].id
}

# HTTP Proxy for Load Balancer
resource "google_compute_target_http_proxy" "web_proxy" {
  count = var.enable_load_balancer ? 1 : 0
  
  name    = "${var.app_name}-${var.environment}-proxy"
  project = var.project_id
  url_map = google_compute_url_map.web_url_map[0].id
}

# Global Forwarding Rule (Public IP for Load Balancer)
resource "google_compute_global_forwarding_rule" "web_forwarding_rule" {
  count = var.enable_load_balancer ? 1 : 0
  
  name       = "${var.app_name}-${var.environment}-lb"
  project    = var.project_id
  target     = google_compute_target_http_proxy.web_proxy[0].id
  port_range = "80"
  
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
}

# Firewall rule for Load Balancer health checks
resource "google_compute_firewall" "lb_health_check" {
  count = var.enable_load_balancer ? 1 : 0
  
  name    = "${var.vpc_name}-allow-lb-health-check"
  network = var.vpc_name
  project = var.project_id
  
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  
  # GCP health check IP ranges
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = var.tags
  
  description = "Allow health checks from GCP load balancers"
  priority    = 1000
}
