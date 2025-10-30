output "bucket_names" {
  value       = { for k, v in google_storage_bucket.buckets : k => v.name }
  description = "Names of created buckets"
}

output "bucket_urls" {
  value       = { for k, v in google_storage_bucket.buckets : k => v.url }
  description = "URLs of created buckets"
}
