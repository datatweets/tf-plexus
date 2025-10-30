output "environment" {
  value       = "dev"
  description = "Environment name"
}

output "web_server" {
  value = {
    name        = module.web_server.name
    internal_ip = module.web_server.internal_ip
    external_ip = module.web_server.external_ip
    machine_type = module.web_server.machine_type
  }
  description = "Web server details"
}

output "app_server" {
  value = {
    name        = module.app_server.name
    internal_ip = module.app_server.internal_ip
    external_ip = module.app_server.external_ip
    machine_type = module.app_server.machine_type
  }
  description = "App server details"
}

output "access_url" {
  value       = "http://${module.web_server.external_ip}"
  description = "Web server access URL"
}

output "cost_estimate" {
  value = {
    web_server  = "~$8/month"
    app_server  = "~$18/month"
    total       = "~$26/month"
  }
  description = "Estimated monthly cost"
}
