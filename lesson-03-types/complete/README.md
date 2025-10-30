# Complete Production Infrastructure

**Production-ready multi-tier infrastructure combining ALL Lesson 3 concepts.**

This is the capstone example demonstrating enterprise-grade Terraform patterns.

## 🎯 What This Demonstrates

### All Lesson 3 Concepts Combined

✅ **Types** - String, number, bool, list, map, object  
✅ **Dynamic blocks** - Disk attachments, network interfaces, firewall rules  
✅ **Conditional expressions** - Environment-based configurations  
✅ **Data sources** - Zone discovery, image lookup, project metadata  
✅ **Functions** - element(), join(), format(), cidrsubnet(), merge()  
✅ **Outputs** - Splat, for_each, conditional, formatted  
✅ **Validation** - Input validation on all critical variables  
✅ **Count vs for_each** - Web servers use count, DBs use for_each  

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Load Balancer                           │
│                  (Conditional - Production)                   │
└────────────────────┬────────────────────────────────────────┘
                     │
    ┌────────────────┴────────────────┬────────────────────┐
    │                                 │                    │
┌───▼────┐                     ┌──────▼───┐         ┌─────▼────┐
│ Web-0  │                     │  Web-1   │         │  Web-2   │
│ (zone-a)│                     │ (zone-b) │         │ (zone-c) │
└───┬────┘                     └──────┬───┘         └─────┬────┘
    │                                 │                    │
    └─────────────────┬───────────────┴────────────────────┘
                      │
          ┌───────────┴──────────────┐
          │                          │
    ┌─────▼─────┐              ┌─────▼─────┐
    │ App API   │              │ App Worker │
    │ (zone-a)  │              │  (zone-b)  │
    └─────┬─────┘              └─────┬─────┘
          │                          │
          └──────────┬───────────────┘
                     │
         ┌───────────┴──────────────┐
         │                          │
    ┌────▼────┐                ┌────▼────┐
    │ DB Primary│               │ DB Replica│
    │ + 2 Disks │               │ + 2 Disks │
    │ (zone-a)  │               │ (zone-b)  │
    └───────────┘                └──────────┘

Subnets: frontend | application | database | management
```

## 📊 What Gets Created

### Development Environment
- 1 web server (e2-micro, 20GB standard disk)
- 2 app servers (API + Worker)
- 2 database servers (e2-micro, 20GB, no data disks)
- Load balancer (if enabled)
- Monitoring (if enabled)
- VPC + 4 subnets

### Production Environment  
- 3 web servers (e2-medium, 50GB SSD, 2 data disks each)
- 2 app servers (API + Worker, e2-medium)
- 2 database servers (e2-standard-4, 200GB SSD, 2x500GB data disks each)
- Load balancer with static IP
- Monitoring instance
- VPC + 4 subnets
- Static IPs for web servers

**Total Resources (Production):** ~25 resources

## 🚀 Quick Start

```bash
cd lesson-03/complete/

# Copy and configure
cp terraform.tfvars.example terraform.tfvars
# Edit: project_id, environment (dev or production)

# Initialize
terraform init

# See what will be created
terraform plan

# Deploy
terraform apply

# View outputs
terraform output deployment_summary
terraform output web_servers
terraform output db_servers
```

## 🔍 Key Implementation Patterns

### 1. Environment-Based Conditionals

**Production gets more resources:**
```hcl
count = var.environment == "production" ? var.web_server_count : 1
```

**Production gets better machines:**
```hcl
machine_type = var.environment == "production" ? 
  var.production_machine_type : 
  var.dev_machine_type
```

### 2. Dynamic Disk Attachments

**Web servers get data disks only if enabled:**
```hcl
dynamic "attached_disk" {
  for_each = var.attach_data_disks ? [1, 2] : []
  content {
    source = google_compute_disk.data_disks[...].self_link
  }
}
```

### 3. Data Source Discovery

**Automatically distribute across available zones:**
```hcl
data "google_compute_zones" "available" {
  region = var.region
  status = "UP"
}

zone = element(data.google_compute_zones.available.names, count.index)
```

### 4. For_each with Complex Objects

**Database configuration using maps:**
```hcl
variable "db_configs" {
  type = map(object({
    role                    = string
    production_machine_type = string
    num_data_disks         = number
    # ... more fields
  }))
}

resource "google_compute_instance" "db_servers" {
  for_each = var.db_configs
  # Access: each.key, each.value.role, etc.
}
```

### 5. Nested Dynamic Blocks

**Database servers with multiple data disks:**
```hcl
dynamic "attached_disk" {
  for_each = var.environment == "production" ? 
    range(each.value.num_data_disks) : []
  content {
    source = google_compute_disk.db_data_disks[...].self_link
  }
}
```

### 6. Complex Disk Creation Logic

**Create disks for web servers (flattened nested loop):**
```hcl
for_each = {
  for combo in flatten([
    for i in range(var.web_server_count) : [
      for disk_num in [1, 2] : {
        key  = format("%s-web-%d-disk-%d", var.project_name, i, disk_num)
        zone = element(data.google_compute_zones.available.names, i)
      }
    ]
  ]) : combo.key => combo
}
```

### 7. Template Functions

**Startup script with variables:**
```hcl
metadata = {
  startup-script = templatefile("${path.module}/scripts/web-startup.sh", {
    environment = var.environment
    server_name = "${var.project_name}-web-${count.index}"
    db_hosts    = join(",", values(google_compute_instance.db_servers)[*].network_interface[0].network_ip)
  })
}
```

### 8. Conditional Resources

**Load balancer only if enabled:**
```hcl
resource "google_compute_instance" "load_balancer" {
  count = var.create_load_balancer ? 1 : 0
  # ...
}
```

### 9. Merge Labels

**Combine common and specific labels:**
```hcl
labels = merge(
  var.common_labels,
  {
    environment = var.environment
    tier        = "web"
  }
)
```

### 10. Comprehensive Outputs

**Group servers by zone:**
```hcl
output "servers_by_zone" {
  value = {
    for zone in distinct(concat(
      google_compute_instance.web_servers[*].zone,
      values(google_compute_instance.db_servers)[*].zone
    )) : zone => {
      web_servers = [
        for instance in google_compute_instance.web_servers :
        instance.name if instance.zone == zone
      ]
      # ... more tiers
    }
  }
}
```

## 📈 Scaling Examples

### Development → Production

**Change one variable:**
```hcl
environment = "production"
```

**Result:**
- 1 → 3 web servers
- e2-micro → e2-medium/e2-standard-4
- Standard disks → SSD
- No data disks → 2 data disks per web, 4 per DB
- Ephemeral IPs → Static IPs

### Horizontal Scaling

**Add more web servers:**
```hcl
web_server_count = 5
```

**Automatically:**
- Distributed across zones
- Data disks created
- Load balancer updated

### Add Database Replica

```hcl
db_configs = {
  "db-primary" = { ... }
  "db-replica" = { ... }
  "db-replica-2" = {
    role = "replica"
    zone = "us-west1-c"
    # ... copy other configs
  }
}
```

## 🧪 Testing Scenarios

### Scenario 1: Minimal Dev Environment

```hcl
environment          = "dev"
web_server_count     = 1
attach_data_disks    = false
create_load_balancer = false
enable_monitoring    = false
```

**Cost:** ~$30/month

### Scenario 2: Full Production

```hcl
environment          = "production"
web_server_count     = 3
attach_data_disks    = true
create_load_balancer = true
enable_monitoring    = true
use_static_ips       = true
```

**Cost:** ~$500/month

## 📤 Output Examples

```bash
$ terraform output deployment_summary
{
  "db_servers" = 2
  "environment" = "production"
  "total_servers" = 8
  "web_servers" = 3
  "zones_used" = 3
  "data_disks" = 6
  "db_data_disks" = 4
  # ... more
}

$ terraform output web_servers
{
  "count" = 3
  "names" = ["prod-app-web-0", "prod-app-web-1", "prod-app-web-2"]
  "zones" = ["us-west1-a", "us-west1-b", "us-west1-c"]
  "external_ips" = ["34.83.1.10", "34.83.1.11", "34.83.1.12"]
}

$ terraform output servers_by_zone
{
  "us-west1-a" = {
    "app_servers" = ["app-api"]
    "db_servers" = ["prod-app-db-primary"]
    "total" = 3
    "web_servers" = ["prod-app-web-0"]
  }
  # ... more zones
}
```

## 🔧 Customization

### Change Regions

```hcl
region = "us-east1"
```

Data sources will discover zones automatically.

### Adjust Subnet CIDRs

```hcl
subnet_configs = {
  frontend = {
    cidr             = "10.1.1.0/24"
    enable_secondary = false
  }
  # ... more
}
```

### Custom Application Servers

```hcl
app_server_configs = {
  "app-cache" = {
    machine_type = "e2-highmem-2"
    zone         = "us-west1-a"
    disk_size    = 30
    os_family    = "ubuntu-2204-lts"
    app_type     = "redis"
  }
}
```

## 🧹 Cleanup

```bash
terraform destroy
```

**Warning:** This destroys ALL resources. Review carefully!

## 💡 Production Considerations

### Implemented
✅ Environment separation (dev/prod)  
✅ Input validation  
✅ Proper labeling  
✅ Zone distribution  
✅ Static IPs for production  
✅ Conditional resource creation  
✅ Comprehensive outputs  

### Not Implemented (Add for Real Production)
⚠️ Cloud SQL instead of VMs for databases  
⚠️ GCS backend for state  
⚠️ Workspaces for multi-env  
⚠️ Cloud NAT for private instances  
⚠️ Cloud Armor for DDoS protection  
⚠️ Identity-Aware Proxy  
⚠️ Cloud Monitoring integration  
⚠️ Backup policies  
⚠️ Disaster recovery  

## 📚 What You Learned

### Terraform Concepts
✅ Types: All primitive and complex types  
✅ Dynamic blocks: Multiple use cases  
✅ Conditionals: Environment-based logic  
✅ Data sources: Discovery and lookup  
✅ Functions: 10+ different functions  
✅ Outputs: All patterns (splat, for_each, conditional)  
✅ Count vs for_each: When to use each  
✅ Validation: Input constraints  

### GCP Resources
✅ Compute instances with advanced config  
✅ Persistent disks  
✅ VPC networks and subnets  
✅ Firewall rules  
✅ Static IP addresses  
✅ Startup scripts  

### Best Practices
✅ DRY principle (variables)  
✅ Reusability (for_each with maps)  
✅ Flexibility (conditionals)  
✅ Documentation (outputs)  
✅ Validation (error prevention)  

## 🎓 Next Steps

- ✅ **Completed**: Lesson 3 - Writing Efficient Code
- ⏭️ **Up next**: [Lesson 4](../../lesson-04/) - Modules and Reusable Code
- 📖 **Review**: [Lesson 3 Overview](../README.md)

---

**🎉 Congratulations!**

You've completed the most comprehensive Terraform example combining all advanced concepts. You're now ready to build production-grade infrastructure!
