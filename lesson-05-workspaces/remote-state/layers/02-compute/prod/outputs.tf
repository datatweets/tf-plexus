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
output "web_servers" {
  description = "Web server details"
  value = {
    server_1 = {
      name        = module.web_server_1.name
      external_ip = module.web_server_1.external_ip
      internal_ip = module.web_server_1.internal_ip
    }
    server_2 = {
      name        = module.web_server_2.name
      external_ip = module.web_server_2.external_ip
      internal_ip = module.web_server_2.internal_ip
    }
  }
}

# App Server Outputs
output "app_servers" {
  description = "App server details"
  value = {
    server_1 = {
      name        = module.app_server_1.name
      internal_ip = module.app_server_1.internal_ip
    }
    server_2 = {
      name        = module.app_server_2.name
      internal_ip = module.app_server_2.internal_ip
    }
  }
}

# Deployment Summary
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    environment      = "prod"
    network          = data.terraform_remote_state.networking.outputs.network_name
    web_servers      = 2
    app_servers      = 2
    web_server_urls  = [
      "http://${module.web_server_1.external_ip}",
      "http://${module.web_server_2.external_ip}"
    ]
    cost_estimate    = "$220/month (2 medium + 2 large)"
  }
}
