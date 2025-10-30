# Terraform Types and Values - Demonstration
# This example showcases all Terraform data types with real GCP resources

# Local values demonstrating different types
locals {
  # String type
  string_value = "This is a string"
  project_name = "my-gcp-project"

  # Number type
  number_value    = 14
  port            = 8080
  disk_size_gb    = 100
  memory_gb_float = 16.5

  # Bool type
  bool_value        = true
  is_production     = false
  enable_monitoring = true

  # List type (ordered collection)
  list_value  = ["us-west1", "us-west2", "us-east1"]
  allowed_ips = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  tags        = ["production", "web-server", "critical"]

  # Map type (key-value pairs)
  map_value = {
    us-west1 = "Oregon"
    us-west2 = "Los Angeles"
    us-east1 = "South Carolina"
  }

  environment_config = {
    dev  = "e2-micro"
    prod = "e2-standard-4"
  }

  # Nested map (map containing lists)
  nested_map = {
    americas = ["us-west1", "us-west2", "us-central1"]
    europe   = ["europe-west1", "europe-west2", "europe-north1"]
    apac     = ["asia-south1", "asia-southeast1", "asia-east1"]
  }

  # Object type (structured data with type constraints)
  server_config = {
    name     = "production-server"
    location = "US"
    regions  = ["us-west1", "us-east1"]
    settings = {
      cpu    = 4
      memory = 16
    }
  }

  # Common labels using map
  common_labels = {
    managed_by  = "terraform"
    team        = "platform"
    environment = var.environment
    created_on  = formatdate("YYYY-MM-DD", timestamp())
  }
}

# Resource demonstrating string, number, and bool types
resource "google_compute_instance" "demo_server" {
  # String variables
  name    = var.instance_name # String type
  project = var.project_id    # String type
  zone    = var.zone          # String type

  # Using a map to select machine type based on environment
  machine_type = local.environment_config[var.environment]

  # Bool variable usage in tags
  can_ip_forward = var.enable_ip_forwarding # Bool type

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = local.disk_size_gb # Number type
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"

    # Conditional block - demonstrates bool usage
    dynamic "access_config" {
      for_each = var.assign_external_ip ? [1] : []
      content {
        # Empty block for ephemeral IP
      }
    }
  }

  # Labels demonstrate map usage
  labels = merge(
    local.common_labels,
    {
      instance_type   = "demo"
      has_external_ip = var.assign_external_ip ? "true" : "false"
    }
  )

  # Metadata demonstrates map with string values
  metadata = {
    startup-script = "#!/bin/bash\necho 'Hello from Terraform!'"
    environment    = var.environment
    managed-by     = "terraform"
  }

  # Tags demonstrate list type
  tags = local.tags
}

# Resource demonstrating list iteration with count
resource "google_compute_firewall" "allow_ports" {
  count = length(var.allowed_ports) # Number from list length

  name    = "allow-port-${var.allowed_ports[count.index]}"
  network = "default"
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = [tostring(var.allowed_ports[count.index])]
  }

  source_ranges = local.allowed_ips # List type

  # Shows which port this rule is for
  description = "Allow incoming traffic on port ${var.allowed_ports[count.index]}"

  # Demonstrates accessing list elements by index
  target_tags = [element(local.tags, count.index)]
}

# Resource demonstrating map iteration with for_each
resource "google_compute_disk" "data_disks" {
  for_each = var.disk_configs # Map type

  name    = each.key # Map key as disk name
  project = var.project_id
  zone    = var.zone
  type    = each.value.type # Accessing map value properties
  size    = each.value.size

  labels = merge(
    local.common_labels,
    {
      disk_purpose = each.key
      disk_type    = each.value.type
    }
  )
}

# Resource demonstrating nested map access
resource "google_compute_address" "regional_ips" {
  for_each = toset(local.nested_map[var.region_group])

  name         = "ip-${each.value}"
  project      = var.project_id
  address_type = "EXTERNAL"
  region       = each.value

  labels = local.common_labels
}

# Resource demonstrating object type with validation
resource "google_compute_instance" "typed_server" {
  count = var.create_typed_server ? 1 : 0

  name         = var.typed_config.name
  project      = var.project_id
  zone         = var.zone
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  labels = merge(
    local.common_labels,
    { # GCP labels must be lowercase, but you're using "US" (uppercase) as a label value. 
      # Google Cloud has strict label format requirements.
      config_location = lower(var.typed_config.location)
      region_count    = tostring(length(var.typed_config.regions))
    }
  )

  metadata = {
    regions = join(",", var.typed_config.regions)
  }
}
