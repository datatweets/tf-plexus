# Load Balancer Module
# Creates HTTP load balancer for web tier

# Static IP (optional)
resource "google_compute_address" "lb" {
  count = var.use_static_ip ? 1 : 0

  name   = "${var.name}-ip"
  region = var.region
}

# Health check for backends
resource "google_compute_health_check" "http" {
  name = "${var.name}-health-check"

  http_health_check {
    port         = 80
    request_path = "/"
  }

  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

# Backend service
resource "google_compute_backend_service" "web" {
  name          = "${var.name}-backend"
  health_checks = [google_compute_health_check.http.id]
  port_name     = "http"
  protocol      = "HTTP"
  timeout_sec   = 30

  dynamic "backend" {
    for_each = var.backend_instances
    content {
      group = google_compute_instance_group.web[backend.key].id
    }
  }

  log_config {
    enable = true
  }
}

# Instance groups for each backend instance
resource "google_compute_instance_group" "web" {
  count = length(var.backend_instances)

  name      = "${var.name}-ig-${count.index}"
  zone      = var.zone
  instances = [var.backend_instances[count.index]]

  named_port {
    name = "http"
    port = 80
  }
}

# URL map
resource "google_compute_url_map" "default" {
  name            = "${var.name}-url-map"
  default_service = google_compute_backend_service.web.id
}

# HTTP proxy
resource "google_compute_target_http_proxy" "default" {
  name    = "${var.name}-http-proxy"
  url_map = google_compute_url_map.default.id
}

# Forwarding rule
resource "google_compute_global_forwarding_rule" "http" {
  name       = "${var.name}-forwarding-rule"
  target     = google_compute_target_http_proxy.default.id
  port_range = "80"
  ip_address = var.use_static_ip ? google_compute_address.lb[0].address : null
}
