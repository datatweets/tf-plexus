# Production-Ready Multi-Tier Infrastructure
# Combines: types, dynamic blocks, conditionals, data sources, functions, outputs

# Data source: Discover available zones
data "google_compute_zones" "available" {
  region = var.region
  status = "UP"
}

# Data source: Latest OS images
data "google_compute_image" "os_images" {
  for_each = toset(["debian-11", "ubuntu-2204-lts"])

  family  = each.key
  project = each.key == "debian-11" ? "debian-cloud" : "ubuntu-os-cloud"
}

# Data source: Current project
data "google_project" "current" {
  project_id = var.project_id
}

# VPC Network
resource "google_compute_network" "main" {
  name                    = "${var.project_name}-vpc"
  auto_create_subnetworks = false
}

# Subnets using for_each
resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnet_configs

  name          = "${var.project_name}-${each.key}"
  ip_cidr_range = each.value.cidr
  region        = var.region
  network       = google_compute_network.main.id

  # Use dynamic block for secondary IP ranges
  # Using a separate /20 range to avoid overlap with primary subnet
  dynamic "secondary_ip_range" {
    for_each = each.value.enable_secondary ? [1] : []
    content {
      range_name    = "${each.key}-pods"
      ip_cidr_range = cidrsubnet(replace(each.value.cidr, "/24", "/20"), 4, 15)
    }
  }
}

# Firewall rules using dynamic blocks
resource "google_compute_firewall" "ingress_rules" {
  name    = "${var.project_name}-ingress"
  network = google_compute_network.main.name

  # Dynamic blocks for multiple allow rules
  dynamic "allow" {
    for_each = var.firewall_rules
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  source_ranges = var.allowed_ip_ranges
  target_tags   = ["web-server"]
}

# Web Tier - Multiple servers with conditional configuration
resource "google_compute_instance" "web_servers" {
  count = var.environment == "production" ? var.web_server_count : 1

  name         = "${var.project_name}-web-${count.index}"
  machine_type = var.environment == "production" ? var.production_machine_type : var.dev_machine_type
  zone         = element(data.google_compute_zones.available.names, count.index)

  # Conditional boot disk size
  boot_disk {
    initialize_params {
      image = data.google_compute_image.os_images["debian-11"].self_link
      size  = var.environment == "production" ? 50 : 20
      type  = "pd-standard"  # Changed from conditional pd-ssd to avoid quota
    }
  }

  # Dynamic data disk attachments
  dynamic "attached_disk" {
    for_each = var.attach_data_disks ? [1, 2] : []
    content {
      source = google_compute_disk.data_disks[format("%s-web-%d-disk-%d", var.project_name, count.index, attached_disk.value)].self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnets["frontend"].self_link

    # Conditional external IP
    dynamic "access_config" {
      for_each = var.enable_external_ips ? [1] : []
      content {
        nat_ip = var.use_static_ips && var.environment == "production" ? google_compute_address.web_static_ips[count.index].address : null
      }
    }
  }

  metadata = {
    environment     = var.environment
    tier            = "web"
    server_index    = count.index
    zone_discovered = data.google_compute_zones.available.names[count.index % length(data.google_compute_zones.available.names)]
    startup-script  = templatefile("${path.module}/scripts/web-startup.sh", {
      environment = var.environment
      server_name = "${var.project_name}-web-${count.index}"
      db_hosts    = join(",", values(google_compute_instance.db_servers)[*].network_interface[0].network_ip)
    })
  }

  labels = merge(
    var.common_labels,
    {
      environment = var.environment
      tier        = "web"
      managed_by  = "terraform"
    }
  )

  tags = concat(["web-server", "http-server"], var.environment == "production" ? ["production"] : ["dev"])

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }
}

# Static IPs for production web servers
resource "google_compute_address" "web_static_ips" {
  count = var.use_static_ips && var.environment == "production" ? var.web_server_count : 0

  name   = "${var.project_name}-web-ip-${count.index}"
  region = var.region
}

# Data disks with conditional creation
resource "google_compute_disk" "data_disks" {
  for_each = var.attach_data_disks ? {
    for combo in flatten([
      for i in range(var.environment == "production" ? var.web_server_count : 1) : [
        for disk_num in [1, 2] : {
          key       = format("%s-web-%d-disk-%d", var.project_name, i, disk_num)
          zone      = element(data.google_compute_zones.available.names, i)
          server    = i
          disk_num  = disk_num
        }
      ]
    ]) : combo.key => combo
  } : {}

  name = each.key
  type = "pd-standard"  # Changed from conditional pd-ssd to avoid quota issues
  size = var.data_disk_size_gb
  zone = each.value.zone

  labels = {
    server = "web-${each.value.server}"
  }
}

# Application Tier - Using for_each with object types
resource "google_compute_instance" "app_servers" {
  for_each = var.app_server_configs

  name         = each.key
  machine_type = each.value.machine_type
  zone         = each.value.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.os_images[each.value.os_family].self_link
      size  = each.value.disk_size
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnets["application"].self_link
  }

  metadata = {
    app_type    = each.value.app_type
    environment = var.environment
  }

  labels = merge(var.common_labels, {
    tier = "application"
    type = each.value.app_type
  })

  tags = ["app-server", each.value.app_type]
}

# Database Tier - For_each with conditional configuration
resource "google_compute_instance" "db_servers" {
  for_each = var.db_configs

  name         = "${var.project_name}-${each.key}"
  machine_type = var.environment == "production" ? each.value.production_machine_type : each.value.dev_machine_type
  zone         = each.value.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.os_images["debian-11"].self_link
      size  = var.environment == "production" ? each.value.production_disk_size : each.value.dev_disk_size
      type  = "pd-standard"  # Changed from conditional pd-ssd to avoid quota
    }
  }

  # Dynamic attached disks for database storage
  dynamic "attached_disk" {
    for_each = var.environment == "production" ? range(each.value.num_data_disks) : []
    content {
      source = google_compute_disk.db_data_disks["${each.key}-disk-${attached_disk.value}"].self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnets["database"].self_link
  }

  metadata = {
    db_role      = each.value.role
    db_type      = each.value.db_type
    environment  = var.environment
    replication  = each.value.role == "replica" ? "enabled" : "disabled"
  }

  labels = merge(var.common_labels, {
    tier    = "database"
    db_type = each.value.db_type
    role    = each.value.role
  })

  tags = ["db-server", each.value.db_type]

  depends_on = [google_compute_disk.db_data_disks]
}

# Database data disks (only in production)
resource "google_compute_disk" "db_data_disks" {
  for_each = var.environment == "production" ? {
    for combo in flatten([
      for db_key, db_config in var.db_configs : [
        for disk_idx in range(db_config.num_data_disks) : {
          key  = "${db_key}-disk-${disk_idx}"
          zone = db_config.zone
          size = db_config.data_disk_size_gb
        }
      ]
    ]) : combo.key => combo
  } : {}

  name = "${var.project_name}-${each.key}"
  type = "pd-standard"  # Changed from pd-ssd to avoid quota issues
  size = each.value.size
  zone = each.value.zone

  labels = {
    purpose = "database"
  }
}

# Load Balancer (conditional)
resource "google_compute_instance" "load_balancer" {
  count = var.create_load_balancer ? 1 : 0

  name         = "${var.project_name}-lb"
  machine_type = "e2-small"
  zone         = data.google_compute_zones.available.names[0]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.os_images["debian-11"].self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnets["frontend"].self_link
    
    access_config {
      nat_ip = var.use_static_ips && var.environment == "production" ? google_compute_address.lb_static_ip[0].address : null
    }
  }

  metadata = {
    role           = "load_balancer"
    backend_count  = length(google_compute_instance.web_servers)
    backends       = join(",", google_compute_instance.web_servers[*].network_interface[0].network_ip)
    startup-script = templatefile("${path.module}/scripts/lb-startup.sh", {
      backend_ips = google_compute_instance.web_servers[*].network_interface[0].network_ip
    })
  }

  labels = merge(var.common_labels, {
    tier = "loadbalancer"
  })

  tags = ["lb-server", "http-server"]
}

# Load balancer static IP
resource "google_compute_address" "lb_static_ip" {
  count = var.create_load_balancer && var.use_static_ips && var.environment == "production" ? 1 : 0

  name   = "${var.project_name}-lb-ip"
  region = var.region
}

# Monitoring instance (conditional)
resource "google_compute_instance" "monitoring" {
  count = var.enable_monitoring ? 1 : 0

  name         = "${var.project_name}-monitoring"
  machine_type = "e2-small"
  zone         = data.google_compute_zones.available.names[0]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.os_images["ubuntu-2204-lts"].self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnets["management"].self_link
    access_config {}
  }

  labels = merge(var.common_labels, {
    tier = "monitoring"
  })

  tags = ["monitoring"]
}
