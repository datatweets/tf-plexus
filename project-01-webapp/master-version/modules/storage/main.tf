# Storage Module - Main Configuration
# Purpose: Create GCS buckets for Plexus application storage

# Generate unique bucket names (GCS requires globally unique names)
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

locals {
  bucket_prefix = "plexus-${var.environment}"
}

# GCS Buckets
# Using for_each (Lesson 2) to create multiple buckets from a map
resource "google_storage_bucket" "buckets" {
  for_each = var.buckets
  
  name          = "${local.bucket_prefix}-${each.key}-${random_id.bucket_suffix.hex}"
  location      = each.value.location
  project       = var.project_id
  storage_class = each.value.storage_class
  force_destroy = var.force_destroy
  
  # Uniform bucket-level access (recommended security practice)
  uniform_bucket_level_access = var.uniform_bucket_level_access
  
  # Public access prevention
  public_access_prevention = var.public_access_prevention
  
  # Versioning configuration
  versioning {
    enabled = each.value.versioning
  }
  
  # Lifecycle rules using dynamic blocks (Lesson 3)
  # This allows flexible lifecycle management from variables
  dynamic "lifecycle_rule" {
    for_each = each.value.lifecycle_rules
    content {
      action {
        type = lifecycle_rule.value.action_type
      }
      
      condition {
        age                        = lifecycle_rule.value.age_days
        num_newer_versions         = lifecycle_rule.value.num_newer_versions
        with_state                 = lifecycle_rule.value.action_type == "Delete" ? "ANY" : null
      }
    }
  }
  
  # Labels for organization
  labels = {
    environment = var.environment
    managed_by  = "terraform"
    application = "plexus"
    bucket_type = each.key
  }
  
  # Soft delete policy (retain deleted objects for recovery)
  soft_delete_policy {
    retention_duration_seconds = var.environment == "prod" ? 604800 : 86400 # 7 days prod, 1 day dev
  }
  
  # Lifecycle to prevent accidental deletion
  lifecycle {
    prevent_destroy = false # Set to true in production for critical buckets
  }
}

# Example: IAM binding for service account access
# Uncomment and modify as needed
# resource "google_storage_bucket_iam_member" "bucket_access" {
#   for_each = var.buckets
#   
#   bucket = google_storage_bucket.buckets[each.key].name
#   role   = "roles/storage.objectAdmin"
#   member = "serviceAccount:${var.service_account_email}"
# }

# Example: Create a sample file in assets bucket
# resource "google_storage_bucket_object" "readme" {
#   name   = "README.txt"
#   bucket = google_storage_bucket.buckets["assets"].name
#   content = <<-EOT
#     Plexus Assets Bucket
#     Environment: ${var.environment}
#     Created: ${timestamp()}
#   EOT
# }
