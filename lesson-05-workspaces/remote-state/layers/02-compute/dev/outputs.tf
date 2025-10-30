# Networking Layer Information (from remote state)
output "network_name" {
  description = "VPC network name (from networking layer)"
  value       = data.terraform_remote_state.networking.outputs.network_name
}

output "public_subnet" {
  description = "Public subnet CIDR (from networking layer)"
  value       = data.terraform_remote_state.networking.outputs.public_subnet_cidr
}

output "private_subnet" {
  description = "Private subnet CIDR (from networking layer)"
  value       = data.terraform_remote_state.networking.outputs.private_subnet_cidr
}

# Web Server Outputs
output "web_server_name" {
  description = "Web server name"
  value       = module.web_server.name
}

output "web_server_external_ip" {
  description = "Web server external IP"
  value       = module.web_server.external_ip
}

output "web_server_internal_ip" {
  description = "Web server internal IP"
  value       = module.web_server.internal_ip
}

# App Server Outputs
output "app_server_name" {
  description = "App server name"
  value       = module.app_server.name
}

output "app_server_internal_ip" {
  description = "App server internal IP"
  value       = module.app_server.internal_ip
}

# Deployment Summary
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    environment     = "dev"
    network         = data.terraform_remote_state.networking.outputs.network_name
    web_servers     = 1
    app_servers     = 1
    web_server_url  = "http://${module.web_server.external_ip}"
    cost_estimate   = "$26/month (2 servers: micro + small)"
  }
}
