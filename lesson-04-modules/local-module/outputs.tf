# Outputs from root module

output "web_server" {
  value = {
    name        = module.web_server.name
    internal_ip = module.web_server.internal_ip
    external_ip = module.web_server.external_ip
    self_link   = module.web_server.self_link
  }
  description = "Web server details"
}

output "app_server" {
  value = {
    name        = module.app_server.name
    internal_ip = module.app_server.internal_ip
    external_ip = module.app_server.external_ip
    self_link   = module.app_server.self_link
  }
  description = "App server details"
}

output "worker_servers" {
  value = [
    for idx in range(var.worker_count) : {
      name        = module.worker_servers[idx].name
      internal_ip = module.worker_servers[idx].internal_ip
      external_ip = module.worker_servers[idx].external_ip
    }
  ]
  description = "Worker server details"
}

output "all_server_ips" {
  value = concat(
    [module.web_server.external_ip],
    [module.app_server.external_ip],
    [for idx in range(var.worker_count) : module.worker_servers[idx].external_ip]
  )
  description = "All external IPs"
}

output "module_demonstration" {
  value = {
    modules_used       = 4
    web_servers        = 1
    app_servers        = 1
    worker_servers     = var.worker_count
    total_servers      = 2 + var.worker_count
    module_source      = "./modules/compute-instance"
    reusability_benefit = "Created ${2 + var.worker_count} instances with ~60 lines (vs ~300+ without modules)"
  }
  description = "Module usage summary"
}
