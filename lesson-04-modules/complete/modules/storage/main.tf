# Storage Module
# Creates Cloud Storage buckets

resource "google_storage_bucket" "buckets" {
  for_each = var.buckets

  name          = "${var.project_name}-${var.environment}-${each.key}"
  location      = var.region
  storage_class = each.value.storage_class
  force_destroy = var.environment != "production"

  uniform_bucket_level_access = true

  versioning {
    enabled = each.value.versioning
  }

  lifecycle_rule {
    condition {
      age = each.value.lifecycle_age_days
    }
    action {
      type = "Delete"
    }
  }

  labels = var.labels
}
