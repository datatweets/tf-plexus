output "environment" {
  value       = "prod"
  description = "Environment name"
}

output "web_servers" {
  value = {
    web_1 = {
      name        = module.web_server_1.name
      internal_ip = module.web_server_1.internal_ip
      external_ip = module.web_server_1.external_ip
      machine_type = module.web_server_1.machine_type
    }
    web_2 = {
      name        = module.web_server_2.name
      internal_ip = module.web_server_2.internal_ip
      external_ip = module.web_server_2.external_ip
      machine_type = module.web_server_2.machine_type
    }
  }
  description = "Web server details"
}

output "app_servers" {
  value = {
    app_1 = {
      name        = module.app_server_1.name
      internal_ip = module.app_server_1.internal_ip
      machine_type = module.app_server_1.machine_type
    }
    app_2 = {
      name        = module.app_server_2.name
      internal_ip = module.app_server_2.internal_ip
      machine_type = module.app_server_2.machine_type
    }
  }
  description = "App server details"
}

output "db_server" {
  value = {
    name        = module.db_server.name
    internal_ip = module.db_server.internal_ip
    machine_type = module.db_server.machine_type
  }
  description = "Database server details"
}

output "monitoring_server" {
  value = {
    name        = google_compute_instance.monitoring.name
    internal_ip = google_compute_instance.monitoring.network_interface[0].network_ip
    external_ip = google_compute_instance.monitoring.network_interface[0].access_config[0].nat_ip
  }
  description = "Monitoring server details"
}

output "access_urls" {
  value = [
    "http://${module.web_server_1.external_ip}",
    "http://${module.web_server_2.external_ip}"
  ]
  description = "Web server URLs"
}

output "deployment_summary" {
  value = {
    environment      = "prod"
    web_servers      = 2
    app_servers      = 2
    database_servers = 1
    monitoring       = 1
    total_servers    = 6
  }
  description = "Production deployment summary"
}

output "cost_estimate" {
  value = {
    web_servers     = "2 x $35 = $70/month"
    app_servers     = "2 x $70 = $140/month"
    database_server = "1 x $140 = $140/month"
    monitoring      = "1 x $35 = $35/month"
    total           = "~$385/month"
  }
  description = "Estimated monthly cost"
}
