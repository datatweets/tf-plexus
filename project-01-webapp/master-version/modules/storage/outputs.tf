# Storage Module - Outputs
# Purpose: Expose bucket information

output "bucket_names" {
  description = "Map of bucket types to their names"
  value = {
    for key, bucket in google_storage_bucket.buckets :
    key => bucket.name
  }
}

output "bucket_urls" {
  description = "Map of bucket types to their URLs"
  value = {
    for key, bucket in google_storage_bucket.buckets :
    key => bucket.url
  }
}

output "bucket_self_links" {
  description = "Map of bucket types to their self_links"
  value = {
    for key, bucket in google_storage_bucket.buckets :
    key => bucket.self_link
  }
}

output "buckets_info" {
  description = "Detailed information about all buckets"
  value = {
    for key, bucket in google_storage_bucket.buckets :
    key => {
      name          = bucket.name
      url           = bucket.url
      location      = bucket.location
      storage_class = bucket.storage_class
      versioning    = bucket.versioning[0].enabled
    }
  }
}

output "assets_bucket_name" {
  description = "Name of the assets bucket (if created)"
  value       = contains(keys(google_storage_bucket.buckets), "assets") ? google_storage_bucket.buckets["assets"].name : null
}

output "backups_bucket_name" {
  description = "Name of the backups bucket (if created)"
  value       = contains(keys(google_storage_bucket.buckets), "backups") ? google_storage_bucket.buckets["backups"].name : null
}

output "storage_summary" {
  description = "Summary of created storage resources"
  value = {
    bucket_count = length(google_storage_bucket.buckets)
    bucket_names = [for bucket in google_storage_bucket.buckets : bucket.name]
    environment  = var.environment
    project_id   = var.project_id
  }
}
