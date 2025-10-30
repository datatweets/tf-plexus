/**
 * Storage Module
 * 
 * Creates GCS (Google Cloud Storage) buckets.
 */

# Storage Bucket
resource "google_storage_bucket" "bucket" {
  name          = "${var.project_id}-${var.environment}-${var.bucket_name}"
  location      = var.location
  project       = var.project_id
  storage_class = var.storage_class
  force_destroy = var.force_destroy

  uniform_bucket_level_access = true

  versioning {
    enabled = var.versioning_enabled
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lookup(lifecycle_rule.value.action, "storage_class", null)
      }
      condition {
        age                   = lookup(lifecycle_rule.value.condition, "age", null)
        num_newer_versions    = lookup(lifecycle_rule.value.condition, "num_newer_versions", null)
        with_state            = lookup(lifecycle_rule.value.condition, "with_state", null)
      }
    }
  }

  labels = merge(
    {
      environment = var.environment
      managed_by  = "terraform"
      purpose     = var.purpose
    },
    var.custom_labels
  )
}
