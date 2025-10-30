# Outputs from flexible modules

output "web_small" {
  value = {
    name            = module.web_small.name
    sizing          = module.web_small.sizing_used
    machine_type    = module.web_small.machine_type
    internal_ip     = module.web_small.internal_ip
    external_ip     = module.web_small.external_ip
    monthly_cost_estimate = module.web_small.monthly_cost_estimate
  }
  description = "Small web server details"
}

output "app_medium" {
  value = {
    name            = module.app_medium.name
    sizing          = module.app_medium.sizing_used
    machine_type    = module.app_medium.machine_type
    internal_ip     = module.app_medium.internal_ip
    external_ip     = module.app_medium.external_ip
    monitoring      = module.app_medium.monitoring_enabled
    monthly_cost_estimate = module.app_medium.monthly_cost_estimate
  }
  description = "Medium app server details"
}

output "db_large" {
  value = {
    name               = module.db_large.name
    sizing             = module.db_large.sizing_used
    machine_type       = module.db_large.machine_type
    internal_ip        = module.db_large.internal_ip
    external_ip        = module.db_large.external_ip
    data_disks         = module.db_large.data_disk_names
    backup_enabled     = module.db_large.backup_enabled
    security_features  = module.db_large.security_features
    monthly_cost_estimate = module.db_large.monthly_cost_estimate
  }
  description = "Large database server details"
}

output "custom_server" {
  value = {
    name         = module.custom_server.name
    machine_type = module.custom_server.machine_type
    internal_ip  = module.custom_server.internal_ip
    external_ip  = module.custom_server.external_ip
    monthly_cost_estimate = module.custom_server.monthly_cost_estimate
  }
  description = "Custom server details"
}

output "cost_summary" {
  value = {
    web_small     = module.web_small.monthly_cost_estimate
    app_medium    = module.app_medium.monthly_cost_estimate
    db_large      = module.db_large.monthly_cost_estimate
    custom_server = module.custom_server.monthly_cost_estimate
    total_monthly = (
      module.web_small.monthly_cost_estimate +
      module.app_medium.monthly_cost_estimate +
      module.db_large.monthly_cost_estimate +
      module.custom_server.monthly_cost_estimate
    )
  }
  description = "Monthly cost estimates (USD)"
}

output "deployment_summary" {
  value = {
    total_servers = 4
    sizing_breakdown = {
      small  = 1
      medium = 1
      large  = 1
      custom = 1
    }
    features_enabled = {
      monitoring                 = 1
      backup                     = 1
      secure_boot               = 1
      data_disks                = 2
    }
    environments = ["dev", "staging", "production"]
  }
  description = "Deployment summary"
}
