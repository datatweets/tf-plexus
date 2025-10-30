# Outputs from registry modules

# VPC outputs
output "vpc_network" {
  value = {
    name      = module.vpc.network_name
    id        = module.vpc.network_id
    self_link = module.vpc.network_self_link
  }
  description = "VPC network details from registry module"
}

output "subnets" {
  value       = module.vpc.subnets
  description = "Subnets created by registry module"
}

# Web server outputs
output "web_servers" {
  value = {
    self_link              = module.web_servers.self_link
    instance_group         = module.web_servers.instance_group
    instance_group_manager = module.web_servers.instance_group_manager
    health_checks          = module.web_servers.health_check_self_links
  }
  description = "Web server MIG details from managed instance group module"
}

# Database outputs
output "database" {
  value = {
    instance_name        = module.postgresql.instance_name
    instance_connection  = module.postgresql.instance_connection_name
    public_ip           = module.postgresql.public_ip_address
    private_ip          = module.postgresql.private_ip_address
  }
  description = "PostgreSQL database details from Cloud SQL module"
  sensitive   = true
}

# Storage outputs
output "storage_buckets" {
  value = {
    names = module.gcs_buckets.names
    urls  = module.gcs_buckets.urls
  }
  description = "Cloud Storage bucket details"
}

# Load balancer outputs
output "load_balancer" {
  value = {
    external_ip = module.load_balancer.external_ip
    backend_services = module.load_balancer.backend_services
  }
  description = "Load balancer details"
  sensitive   = true
}

# Summary output
output "deployment_summary" {
  value = {
    modules_used = {
      "terraform-google-modules/network/google"           = "VPC and firewall rules"
      "terraform-google-modules/vm/google"                = "Web servers with instance template"
      "GoogleCloudPlatform/sql-db/google"                 = "PostgreSQL database"
      "terraform-google-modules/cloud-storage/google"     = "Cloud Storage buckets"
      "GoogleCloudPlatform/lb-http/google"                = "HTTP Load Balancer"
    }
    resources_created = {
      vpc_networks       = 1
      subnets            = 2
      web_servers        = 2
      databases          = 1
      storage_buckets    = 2
      load_balancers     = 1
      firewall_rules     = 2
    }
    benefits = [
      "No need to write VPC/subnet/firewall code",
      "Managed database with best practices",
      "Production-ready load balancer",
      "Maintained and tested by Google/community",
      "Reduced code by ~70%"
    ]
  }
  description = "Summary of registry modules used"
}

# Registry module sources
output "module_sources" {
  value = {
    vpc          = "terraform-google-modules/network/google"
    compute      = "terraform-google-modules/vm/google//modules/compute_instance"
    template     = "terraform-google-modules/vm/google//modules/instance_template"
    database     = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
    storage      = "terraform-google-modules/cloud-storage/google"
    load_balancer = "GoogleCloudPlatform/lb-http/google"
  }
  description = "Registry module sources for reference"
}
