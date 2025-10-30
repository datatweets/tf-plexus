# Database Module - Outputs

output "instance_name" {
  value = # YOUR CODE
}

output "instance_connection_name" {
  value     = # YOUR CODE
  sensitive = true
}

output "public_ip_address" {
  value     = # YOUR CODE
  sensitive = true
}

output "database_version" {
  value = # YOUR CODE
}

output "connection_command" {
  description = "gcloud command to connect to the database"
  value       = # YOUR CODE: Build gcloud sql connect command
  sensitive   = true
}

output "database_info" {
  description = "Formatted database information"
  value       = <<-EOT
    # YOUR CODE: Create formatted output with connection details
  EOT
  sensitive = true
}
