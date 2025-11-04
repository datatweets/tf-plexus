# Database Module - Outputs
# Purpose: Expose database connection information

output "instance_name" {
  description = "Name of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.name
}

output "instance_connection_name" {
  description = "Connection name for Cloud SQL Proxy"
  value       = google_sql_database_instance.postgres.connection_name
}

output "public_ip_address" {
  description = "Public IP address of the database (if enabled)"
  value       = length(google_sql_database_instance.postgres.ip_address) > 0 ? google_sql_database_instance.postgres.ip_address[0].ip_address : "No public IP"
}

output "private_ip_address" {
  description = "Private IP address of the database"
  value       = length(google_sql_database_instance.postgres.ip_address) > 1 ? google_sql_database_instance.postgres.ip_address[1].ip_address : "No private IP"
}

output "database_name" {
  description = "Name of the default database"
  value       = var.create_database ? google_sql_database.database[0].name : "No database created"
}

output "database_user" {
  description = "Database username"
  value       = google_sql_user.app_user.name
}

output "database_version" {
  description = "PostgreSQL version"
  value       = google_sql_database_instance.postgres.database_version
}

output "connection_command" {
  description = "Command to connect to the database using gcloud"
  value       = "gcloud beta sql connect ${google_sql_database_instance.postgres.name} --user=${var.database_user} --database=${var.create_database ? google_sql_database.database[0].name : "postgres"} --project=${var.project_id}"
}

output "connection_info" {
  description = "Complete database connection information"
  value = {
    instance_name      = google_sql_database_instance.postgres.name
    connection_name    = google_sql_database_instance.postgres.connection_name
    public_ip          = length(google_sql_database_instance.postgres.ip_address) > 0 ? google_sql_database_instance.postgres.ip_address[0].ip_address : null
    database_name      = var.create_database ? google_sql_database.database[0].name : "postgres"
    user               = google_sql_user.app_user.name
    region             = var.region
    version            = google_sql_database_instance.postgres.database_version
    tier               = var.tier
    environment        = var.environment
  }
  sensitive = false # Set to true if including passwords
}

output "database_info_message" {
  description = "Information message about connecting to the database"
  value = <<-EOT
    Database created successfully!
    
    Connection Details:
    - Instance: ${google_sql_database_instance.postgres.name}
    - Public IP: ${length(google_sql_database_instance.postgres.ip_address) > 0 ? google_sql_database_instance.postgres.ip_address[0].ip_address : "No public IP"}
    - Database: ${var.create_database ? google_sql_database.database[0].name : "postgres"}
    - User: ${var.database_user}
    - Password: (see terraform output for sensitive values)
    
    Connect using:
    ${format("gcloud beta sql connect %s --user=%s --database=%s --project=%s", 
      google_sql_database_instance.postgres.name,
      var.database_user,
      var.create_database ? google_sql_database.database[0].name : "postgres",
      var.project_id
    )}
    
    Note: Database creation can take 10-15 minutes.
  EOT
}
