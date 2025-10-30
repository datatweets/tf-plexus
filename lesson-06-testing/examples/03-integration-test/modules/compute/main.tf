terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

resource "google_compute_instance" "instances" {
  for_each = var.instances
  
  name         = each.key
  machine_type = each.value.machine_type
  zone         = each.value.zone
  
  tags = concat(
    ["managed-by-terraform"],
    lookup(each.value, "tags", [])
  )
  
  boot_disk {
    initialize_params {
      image = lookup(each.value, "boot_image", "debian-cloud/debian-11")
      size  = lookup(each.value, "disk_size_gb", 10)
      type  = lookup(each.value, "disk_type", "pd-standard")
    }
  }
  
  network_interface {
    network    = var.network_id
    subnetwork = var.subnetwork_id
    
    dynamic "access_config" {
      for_each = lookup(each.value, "assign_external_ip", false) ? [1] : []
      content {
        # Ephemeral IP
      }
    }
  }
  
  metadata = lookup(each.value, "metadata", {})
  
  labels = merge(
    {
      managed_by = "terraform"
      module     = "compute"
    },
    lookup(each.value, "labels", {})
  )
  
  allow_stopping_for_update = true
}
