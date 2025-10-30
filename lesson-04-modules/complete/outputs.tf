# Comprehensive outputs from all modules

# Networking outputs
output "network" {
  value = {
    network_id   = module.networking.network_id
    network_name = module.networking.network_name
    subnets = {
      frontend    = module.networking.frontend_subnet_id
      application = module.networking.application_subnet_id
      database    = module.networking.database_subnet_id
      management  = module.networking.management_subnet_id
    }
  }
  description = "Network infrastructure details"
}

# Web tier outputs
output "web_tier" {
  value = {
    instance_count = module.web_tier.instance_count
    instance_names = module.web_tier.instance_names
    internal_ips   = module.web_tier.internal_ips
    external_ips   = module.web_tier.external_ips
  }
  description = "Web tier details"
}

# Application tier outputs
output "app_tier" {
  value = {
    instance_count = module.app_tier.instance_count
    instance_names = module.app_tier.instance_names
    internal_ips   = module.app_tier.internal_ips
  }
  description = "Application tier details"
}

# Data tier outputs
output "data_tier" {
  value = {
    instance_name = module.data_tier.db_instance_name
    internal_ip   = module.data_tier.db_private_ip
    backup_enabled = module.data_tier.backup_enabled
  }
  description = "Database tier details"
}

# Load balancer outputs
output "load_balancer" {
  value = {
    name        = module.load_balancer.name
    external_ip = module.load_balancer.external_ip
    backend_count = module.load_balancer.backend_count
  }
  description = "Load balancer details"
}

# Storage outputs
output "storage" {
  value = {
    bucket_names = module.storage.bucket_names
    bucket_urls  = module.storage.bucket_urls
  }
  description = "Cloud storage details"
}

# Monitoring outputs
output "monitoring" {
  value = var.enable_monitoring ? {
    instance_name = module.monitoring[0].instance_name
    internal_ip   = module.monitoring[0].internal_ip
    external_ip   = module.monitoring[0].external_ip
    monitored_instances = module.monitoring[0].monitored_instances
  } : null
  description = "Monitoring details (null if disabled)"
}

# Deployment summary
output "deployment_summary" {
  value = {
    project      = var.project_name
    environment  = var.environment
    region       = var.region
    
    modules_used = [
      "networking",
      "web-tier",
      "app-tier",
      "data-tier",
      "load-balancer",
      "storage",
      var.enable_monitoring ? "monitoring" : null
    ]
    
    resources = {
      networks            = 1
      subnets             = 4
      web_servers         = var.web_instance_count
      app_servers         = var.app_instance_count
      database_servers    = 1
      load_balancers      = 1
      storage_buckets     = 3
      monitoring_servers  = var.enable_monitoring ? 1 : 0
      total_vms          = var.web_instance_count + var.app_instance_count + 1 + (var.enable_monitoring ? 1 : 0)
    }
    
    architecture = {
      tiers = ["web", "application", "database"]
      high_availability = var.web_instance_count > 1 && var.app_instance_count > 1
      load_balanced     = true
      monitored         = var.enable_monitoring
    }
  }
  description = "Complete deployment summary"
}

# Module structure output
output "module_architecture" {
  value = {
    modules_count = 6 + (var.enable_monitoring ? 1 : 0)
    module_dependencies = {
      "web-tier"      = ["networking"]
      "app-tier"      = ["networking", "data-tier"]
      "data-tier"     = ["networking"]
      "load-balancer" = ["networking", "web-tier"]
      "monitoring"    = ["networking", "web-tier", "app-tier", "data-tier"]
      "storage"       = []
    }
    benefits = [
      "Modular architecture - each tier is independent",
      "Reusable modules - can be used in other projects",
      "Easy to scale - adjust instance counts",
      "Environment-aware - different config for dev/prod",
      "Maintainable - changes isolated to modules",
      "Testable - modules can be tested independently"
    ]
  }
  description = "Module architecture and benefits"
}

# Access information
output "access_info" {
  value = {
    application_url = "http://${module.load_balancer.external_ip}"
    monitoring_url  = var.enable_monitoring ? "http://${module.monitoring[0].external_ip}" : "not deployed"
    ssh_bastion     = var.enable_monitoring ? "ssh user@${module.monitoring[0].external_ip}" : "use IAP or Cloud Shell"
  }
  description = "Access endpoints"
}

# Cost estimate
output "estimated_monthly_cost" {
  value = {
    web_tier       = var.web_instance_count * (var.environment == "production" ? 35 : 8)
    app_tier       = var.app_instance_count * (var.environment == "production" ? 70 : 20)
    data_tier      = var.environment == "production" ? 150 : 35
    load_balancer  = 18
    storage        = 10
    monitoring     = var.enable_monitoring ? (var.environment == "production" ? 20 : 8) : 0
    total_usd      = (
      var.web_instance_count * (var.environment == "production" ? 35 : 8) +
      var.app_instance_count * (var.environment == "production" ? 70 : 20) +
      (var.environment == "production" ? 150 : 35) +
      18 + 10 +
      (var.enable_monitoring ? (var.environment == "production" ? 20 : 8) : 0)
    )
  }
  description = "Estimated monthly cost in USD"
}
