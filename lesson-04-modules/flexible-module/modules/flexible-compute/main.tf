# Flexible Compute Module
# Advanced module with T-shirt sizing, validation, and optional features

# Local values for sizing presets
locals {
  # T-shirt sizing configurations
  sizing_configs = {
    small = {
      machine_type = "e2-micro"
      disk_size_gb = 20
      disk_type    = "pd-standard"
      cost_per_month = 8
    }
    medium = {
      machine_type = "e2-medium"
      disk_size_gb = 50
      disk_type    = "pd-balanced"
      cost_per_month = 35
    }
    large = {
      machine_type = "e2-standard-4"
      disk_size_gb = 100
      disk_type    = "pd-ssd"
      cost_per_month = 150
    }
    xlarge = {
      machine_type = "e2-standard-8"
      disk_size_gb = 200
      disk_type    = "pd-ssd"
      cost_per_month = 300
    }
  }

  # Determine configuration source
  use_sizing = var.machine_type == "" ? true : false
  
  # Select configuration
  selected_config = local.use_sizing ? local.sizing_configs[var.sizing] : {
    machine_type   = var.machine_type
    disk_size_gb   = var.disk_size_gb
    disk_type      = var.disk_type
    cost_per_month = 0  # Unknown for custom
  }

  # Final values (allow overrides)
  final_machine_type = local.selected_config.machine_type
  final_disk_size    = var.disk_size_gb != 0 ? var.disk_size_gb : local.selected_config.disk_size_gb
  final_disk_type    = var.disk_type != "" ? var.disk_type : local.selected_config.disk_type

  # Cost calculation
  base_cost = local.selected_config.cost_per_month
  disk_cost = (local.final_disk_size - 20) * 0.04  # $0.04/GB over 20GB
  data_disk_cost = var.attach_data_disks ? (var.data_disk_count * var.data_disk_size_gb * 0.17) : 0
  total_monthly_cost = local.base_cost + local.disk_cost + local.data_disk_cost

  # Labels
  common_labels = merge(
    var.labels,
    {
      environment = var.environment
      managed_by  = "terraform"
      module      = "flexible-compute"
      sizing      = local.use_sizing ? var.sizing : "custom"
    }
  )
}

# Main compute instance
resource "google_compute_instance" "this" {
  name         = var.name
  machine_type = local.final_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.boot_disk_image
      size  = local.final_disk_size
      type  = local.final_disk_type
    }
  }

  # Dynamic data disk attachments
  dynamic "attached_disk" {
    for_each = var.attach_data_disks ? range(var.data_disk_count) : []
    content {
      source = google_compute_disk.data_disks[attached_disk.value].self_link
    }
  }

  network_interface {
    network = var.network

    dynamic "access_config" {
      for_each = var.enable_external_ip ? [1] : []
      content {
        network_tier = var.network_tier
      }
    }
  }

  metadata = merge(
    var.metadata,
    {
      environment = var.environment
      sizing      = local.use_sizing ? var.sizing : "custom"
    }
  )

  tags = concat(
    var.tags,
    [var.environment, "managed-by-terraform"]
  )

  labels = local.common_labels

  # Shielded VM settings
  shielded_instance_config {
    enable_secure_boot          = var.enable_secure_boot
    enable_vtpm                 = var.enable_vtpm
    enable_integrity_monitoring = var.enable_integrity_monitoring
  }

  # Monitoring
  metadata_startup_script = var.enable_monitoring ? file("${path.module}/scripts/install-monitoring.sh") : null

  allow_stopping_for_update = true

  lifecycle {
    # Prevent accidental deletion in production
    prevent_destroy = var.environment == "production" ? true : false
  }
}

# Data disks (if enabled)
resource "google_compute_disk" "data_disks" {
  count = var.attach_data_disks ? var.data_disk_count : 0

  name = "${var.name}-data-${count.index}"
  type = "pd-ssd"
  size = var.data_disk_size_gb
  zone = var.zone

  labels = merge(
    local.common_labels,
    {
      disk_index = tostring(count.index)
    }
  )
}

# Backup snapshot policy (if enabled)
resource "google_compute_resource_policy" "backup" {
  count = var.enable_backup ? 1 : 0

  name   = "${var.name}-backup-policy"
  region = replace(var.zone, "/-[a-z]$/", "")  # Extract region from zone

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = var.backup_schedule
      }
    }

    retention_policy {
      max_retention_days    = var.backup_retention_days
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
  }
}

# Attach backup policy to boot disk
resource "google_compute_disk_resource_policy_attachment" "backup" {
  count = var.enable_backup ? 1 : 0

  name = google_compute_resource_policy.backup[0].name
  disk = google_compute_instance.this.boot_disk[0].source
  zone = var.zone
}
