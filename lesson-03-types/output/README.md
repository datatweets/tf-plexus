# Outputs - Master Output Expressions

Master every output pattern: splat expressions, for_each, conditionals, sensitive values, and complex transformations.

## What You'll Learn

- ✅ **Splat expressions** - Extract attributes with `[*]`
- ✅ **For_each outputs** - Handle map-based resources
- ✅ **Conditional outputs** - Handle optional resources
- ✅ **Complex for expressions** - Advanced transformations
- ✅ **Sensitive outputs** - Hide secrets from logs
- ✅ **Formatted outputs** - JSON, templates, automation-ready

## What Gets Created

- **3 web servers** distributed across zones
- **2 database servers** (primary + replica) using for_each
- **1 load balancer** (optional)
- **3 data disks** for persistent storage
- **1 VPC + 2 subnets** for networking

## Quick Start

```bash
cd lesson-03/output/
cp terraform.tfvars.example terraform.tfvars
# Edit project_id in terraform.tfvars
terraform init
terraform apply
terraform output  # See all outputs!
```

## Output Pattern Reference

### 1. Splat Expressions `[*]`

Extract same attribute from all resources created with `count`:

```hcl
# Get all server names
output "server_names" {
  value = google_compute_instance.web_servers[*].name
}

# Result: ["output-demo-0", "output-demo-1", "output-demo-2"]
```

**Nested attributes:**
```hcl
output "external_ips" {
  value = google_compute_instance.web_servers[*].network_interface[0].access_config[0].nat_ip
}
```

### 2. For_each Outputs

Resources created with `for_each` are maps:

```hcl
output "db_server_ips" {
  value = {
    for key, instance in google_compute_instance.db_servers :
    key => instance.network_interface[0].network_ip
  }
}

# Result:
# {
#   "db-primary" = "10.0.0.2"
#   "db-replica" = "10.0.0.3"
# }
```

**Convert map to list using values():**
```hcl
output "db_names_list" {
  value = values(google_compute_instance.db_servers)[*].name
}
```

### 3. Conditional Outputs

Handle resources created conditionally:

```hcl
output "load_balancer_ip" {
  value = var.create_lb ? google_compute_instance.load_balancer[0].network_interface[0].access_config[0].nat_ip : "not created"
}

# Or return null:
output "lb_info" {
  value = var.create_lb ? {
    name = google_compute_instance.load_balancer[0].name
    ip   = google_compute_instance.load_balancer[0].network_interface[0].access_config[0].nat_ip
  } : null
}
```

### 4. Complex For Expressions

Merge multiple resource types:

```hcl
output "server_inventory" {
  value = merge(
    {
      for idx, instance in google_compute_instance.web_servers : 
      instance.name => {
        type = "web"
        zone = instance.zone
      }
    },
    {
      for key, instance in google_compute_instance.db_servers : 
      instance.name => {
        type = "database"
        zone = instance.zone
      }
    }
  )
}
```

**Group by attribute:**
```hcl
output "servers_by_zone" {
  value = {
    for zone in distinct(google_compute_instance.web_servers[*].zone) : 
    zone => [
      for instance in google_compute_instance.web_servers :
      instance.name if instance.zone == zone
    ]
  }
}
```

### 5. Sensitive Outputs

Mark outputs as sensitive to hide from logs:

```hcl
output "api_key" {
  value     = var.sensitive_api_key
  sensitive = true
}

# Won't display in 'terraform output' or logs
# Use: terraform output -json | jq -r '.api_key.value'
```

### 6. Formatted Outputs

**JSON format:**
```hcl
output "servers_json" {
  value = jsonencode([
    for instance in google_compute_instance.web_servers : {
      name = instance.name
      ip   = instance.network_interface[0].access_config[0].nat_ip
    }
  ])
}
```

**Template format (Ansible inventory):**
```hcl
output "ansible_inventory" {
  value = templatefile("${path.module}/templates/inventory.tpl", {
    web_servers = google_compute_instance.web_servers
    db_servers  = values(google_compute_instance.db_servers)
  })
}
```

## Viewing Outputs

**All outputs:**
```bash
terraform output
```

**Specific output:**
```bash
terraform output web_server_names
terraform output db_server_details
```

**JSON format (for scripts):**
```bash
terraform output -json > outputs.json
terraform output -json web_server_names | jq -r '.[]'
```

**Sensitive output (requires explicit flag):**
```bash
terraform output -json api_key | jq -r '.value'
```

## Example Output Results

```bash
$ terraform output web_server_names
[
  "output-demo-0",
  "output-demo-1",
  "output-demo-2",
]

$ terraform output db_server_ips
{
  "db-primary" = "10.128.0.2"
  "db-replica" = "10.128.0.3"
}

$ terraform output deployment_summary
{
  "db_servers" = 2
  "environment" = "demo"
  "load_balancer" = true
  "project" = "my-gcp-project"
  "region" = "us-west1"
  "total_servers" = 5
  "web_servers" = 3
  "zones_used" = [
    "us-west1-a",
    "us-west1-b",
    "us-west1-c",
  ]
}
```

## Output Patterns by Use Case

### Infrastructure Inventory
```hcl
output "server_inventory" {
  value = merge(...)  # All servers with details
}
```

### Load Balancer Configuration
```hcl
output "backend_ips" {
  value = google_compute_instance.web_servers[*].network_interface[0].network_ip
}
```

### Monitoring/Alerting
```hcl
output "ssh_commands" {
  value = [for instance in google_compute_instance.web_servers : 
    "ssh user@${instance.network_interface[0].access_config[0].nat_ip}"
  ]
}
```

### CI/CD Integration
```hcl
output "deployment_complete" {
  value = "Success at ${timestamp()}"
  depends_on = [google_compute_instance.web_servers]
}
```

## Cleanup

```bash
terraform destroy
```

## Key Takeaways

✅ **Splat `[*]`** - For count-based resources  
✅ **For expressions** - For for_each resources  
✅ **values()** - Convert for_each map to list  
✅ **Conditional** - Handle optional resources  
✅ **Sensitive** - Hide secrets from logs  
✅ **Templates** - Generate config files  
✅ **depends_on** - Wait for all resources

## Next Steps

- ✅ **Completed**: Mastering output expressions
- ⏭️ **Up next**: [complete/](../complete/) - Production infrastructure combining everything

---

**Output Mastery Complete!** 🎉
