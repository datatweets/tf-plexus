# Compute Module - Main Resources
# Purpose: Create web server instances and load balancer

# ══════════════════════════════════════════════════════════════════════════════
# TODO #7: Create Multiple Compute Instances using count
# ══════════════════════════════════════════════════════════════════════════════
# LEARNING OBJECTIVES:
# - Master count meta-argument (Lesson 2)
# - Use count.index for unique naming
# - Configure instance metadata and startup scripts
# - Implement lifecycle rules
# 
# HINTS:
# - Use resource: google_compute_instance
# - Use count = var.instance_count
# - Name instances with: "${var.instance_name_prefix}-${count.index + 1}"
# - Reference startup script: file("${path.module}/startup.sh")
# - Set lifecycle: create_before_destroy = true
# - Add ignore_changes for metadata.ssh-keys
# 
# REQUIRED FIELDS:
# - name, machine_type, zone, tags
# - boot_disk with initialize_params (image = "debian-cloud/debian-11")
# - network_interface with subnetwork and access_config
# - metadata_startup_script
# 
# DOCUMENTATION:
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance
# https://developer.hashicorp.com/terraform/language/meta-arguments/count
# ══════════════════════════════════════════════════════════════════════════════

resource "google_compute_instance" "web_servers" {
  # YOUR CODE HERE
  # Implement multiple instances using count
  
  # count = ?
  
  # name         = ?
  # machine_type = ?
  # zone         = ?
  # project      = ?
  # tags         = ?
  
  # boot_disk {
  #   initialize_params {
  #     image = "debian-cloud/debian-11"
  #   }
  # }
  
  # network_interface {
  #   subnetwork = ?
  #   access_config {
  #     # Ephemeral public IP
  #   }
  # }
  
  # metadata_startup_script = ?
  
  # lifecycle {
  #   create_before_destroy = ?
  #   ignore_changes = [metadata["ssh-keys"]]
  # }
}

# ══════════════════════════════════════════════════════════════════════════════
# TODO #8: Create Instance Group for Load Balancer (Conditional)
# ══════════════════════════════════════════════════════════════════════════════
# LEARNING OBJECTIVES:
# - Use count for conditional resource creation (Lesson 2)
# - Reference instances created with count
# - Understand instance groups
# 
# HINTS:
# - Use resource: google_compute_instance_group
# - Use count = var.enable_load_balancer ? 1 : 0 for conditional creation
# - Reference instances: google_compute_instance.web_servers[*].self_link
# - The [*] splat operator gets all instances
# 
# DOCUMENTATION:
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group
# ══════════════════════════════════════════════════════════════════════════════

resource "google_compute_instance_group" "web_group" {
  # YOUR CODE HERE
  # Implement conditional instance group
  
  # count = ?
  
  # name    = ?
  # zone    = ?
  # project = ?
  
  # instances = ?
}

# ══════════════════════════════════════════════════════════════════════════════
# TODO #9: Create Health Check (Conditional)
# ══════════════════════════════════════════════════════════════════════════════
# LEARNING OBJECTIVES:
# - Configure health checks for load balancers
# - Use conditional resource creation
# 
# HINTS:
# - Use resource: google_compute_health_check
# - Count: var.enable_load_balancer ? 1 : 0
# - Configure http_health_check block with:
#   - port = 80
#   - request_path = "/health"
#   - check_interval_sec = 5
#   - timeout_sec = 5
# 
# DOCUMENTATION:
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_health_check
# ══════════════════════════════════════════════════════════════════════════════

resource "google_compute_health_check" "http" {
  # YOUR CODE HERE
}

# ══════════════════════════════════════════════════════════════════════════════
# TODO #10: Create Backend Service (Conditional)
# ══════════════════════════════════════════════════════════════════════════════
# LEARNING OBJECTIVES:
# - Configure load balancer backend
# - Reference conditionally created resources
# - Use balancing_mode and capacity settings
# 
# HINTS:
# - Use resource: google_compute_backend_service
# - Reference health check: google_compute_health_check.http[0].id
# - Backend block references instance group: google_compute_instance_group.web_group[0].id
# - Set balancing_mode = "UTILIZATION"
# - Set max_utilization = 0.8
# 
# DOCUMENTATION:
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_service
# ══════════════════════════════════════════════════════════════════════════════

resource "google_compute_backend_service" "web" {
  # YOUR CODE HERE
  
  # backend {
  #   group = ?
  #   balancing_mode = ?
  #   max_utilization = ?
  # }
  
  # health_checks = [?]
}

# ══════════════════════════════════════════════════════════════════════════════
# TODO #11: Create URL Map, HTTP Proxy, and Forwarding Rule
# ══════════════════════════════════════════════════════════════════════════════
# LEARNING OBJECTIVES:
# - Complete load balancer configuration
# - Chain multiple resources together
# - Understand load balancer architecture
# 
# HINTS:
# You need three resources:
# 1. google_compute_url_map - Routes requests to backend service
# 2. google_compute_target_http_proxy - HTTP protocol handler
# 3. google_compute_global_forwarding_rule - Public IP and forwarding
# 
# DOCUMENTATION:
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_url_map
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_target_http_proxy
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_forwarding_rule
# ══════════════════════════════════════════════════════════════════════════════

resource "google_compute_url_map" "web" {
  # YOUR CODE HERE
}

resource "google_compute_target_http_proxy" "web" {
  # YOUR CODE HERE
}

resource "google_compute_global_forwarding_rule" "web" {
  # YOUR CODE HERE
  # port_range = "80"
  # target = google_compute_target_http_proxy.web[0].id
}

# ══════════════════════════════════════════════════════════════════════════════
# TODO #12: Create Firewall Rule for Health Checks (Conditional)
# ══════════════════════════════════════════════════════════════════════════════
# LEARNING OBJECTIVES:
# - Configure firewall for Google health check sources
# - Use source_ranges for GCP health check IPs
# 
# HINTS:
# - Use resource: google_compute_firewall
# - Google health check source ranges: ["35.191.0.0/16", "130.211.0.0/22"]
# - Allow TCP port 80
# - Target tags: var.network_tags
# 
# DOCUMENTATION:
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall
# ══════════════════════════════════════════════════════════════════════════════

resource "google_compute_firewall" "allow_health_check" {
  # YOUR CODE HERE
}

# ══════════════════════════════════════════════════════════════════════════════
# CHECKPOINT: Compute Module Complete!
# ══════════════════════════════════════════════════════════════════════════════
# 
# You've learned:
# ✓ Using count for multiple instances
# ✓ Conditional resource creation
# ✓ Complex load balancer configuration
# ✓ Resource chaining and dependencies
# 
# Test your understanding:
# 1. What's the difference between count and for_each?
# 2. Why use create_before_destroy lifecycle rule?
# 3. How does the load balancer health check work?
# 
# Next: Complete outputs.tf, then move to database module
# ══════════════════════════════════════════════════════════════════════════════
