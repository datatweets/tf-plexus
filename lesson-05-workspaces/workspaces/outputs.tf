output "workspace" {
  value       = terraform.workspace
  description = "Current workspace name"
}

output "web_servers" {
  value = {
    count        = length(google_compute_instance.web)
    names        = google_compute_instance.web[*].name
    internal_ips = google_compute_instance.web[*].network_interface[0].network_ip
    external_ips = google_compute_instance.web[*].network_interface[0].access_config[0].nat_ip
  }
  description = "Web server details"
}

output "app_servers" {
  value = {
    count        = length(google_compute_instance.app)
    names        = google_compute_instance.app[*].name
    internal_ips = google_compute_instance.app[*].network_interface[0].network_ip
  }
  description = "App server details"
}

output "monitoring_server" {
  value = length(google_compute_instance.monitoring) > 0 ? {
    name        = google_compute_instance.monitoring[0].name
    internal_ip = google_compute_instance.monitoring[0].network_interface[0].network_ip
    external_ip = google_compute_instance.monitoring[0].network_interface[0].access_config[0].nat_ip
  } : null
  description = "Monitoring server details (null if not deployed)"
}

output "deployment_summary" {
  value = {
    workspace    = terraform.workspace
    project_id   = var.project_id
    region       = var.region
    zone         = var.zone
    
    resources = {
      web_servers        = length(google_compute_instance.web)
      app_servers        = length(google_compute_instance.app)
      monitoring_servers = length(google_compute_instance.monitoring)
      total_servers      = length(google_compute_instance.web) + length(google_compute_instance.app) + length(google_compute_instance.monitoring)
    }
    
    configuration = local.config
  }
  description = "Complete deployment summary"
}

output "estimated_monthly_cost" {
  value = {
    web_tier  = length(google_compute_instance.web) * (local.config.web_machine_type == "e2-micro" ? 8 : local.config.web_machine_type == "e2-small" ? 18 : local.config.web_machine_type == "e2-medium" ? 35 : 70)
    app_tier  = length(google_compute_instance.app) * (local.config.app_machine_type == "e2-micro" ? 8 : local.config.app_machine_type == "e2-small" ? 18 : local.config.app_machine_type == "e2-medium" ? 35 : 70)
    monitoring = length(google_compute_instance.monitoring) * 35
    total_usd  = (
      length(google_compute_instance.web) * (local.config.web_machine_type == "e2-micro" ? 8 : local.config.web_machine_type == "e2-small" ? 18 : local.config.web_machine_type == "e2-medium" ? 35 : 70) +
      length(google_compute_instance.app) * (local.config.app_machine_type == "e2-micro" ? 8 : local.config.app_machine_type == "e2-small" ? 18 : local.config.app_machine_type == "e2-medium" ? 35 : 70) +
      length(google_compute_instance.monitoring) * 35
    )
  }
  description = "Estimated monthly cost in USD"
}

output "access_urls" {
  value = [
    for ip in google_compute_instance.web[*].network_interface[0].access_config[0].nat_ip :
    "http://${ip}"
  ]
  description = "Web server URLs"
}
