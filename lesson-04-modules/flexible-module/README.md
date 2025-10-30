# Flexible Module - Advanced Patterns

Master advanced module patterns with **T-shirt sizing**, **validation**, and **optional features**.

## 🎯 What You'll Learn

- ✅ **T-shirt sizing** - small/medium/large/xlarge presets
- ✅ **Local values** - Complex logic within modules
- ✅ **Validation rules** - Input constraints
- ✅ **Optional features** - Conditional resources
- ✅ **Cost estimation** - Calculate monthly costs
- ✅ **Security features** - Shielded VMs, backups
- ✅ **Flexible configuration** - Presets OR custom

## 🏗️ Module Features

### T-Shirt Sizing

| Size | Machine Type | Disk | Type | Monthly Cost |
|------|-------------|------|------|--------------|
| **small** | e2-micro | 20GB | standard | ~$8 |
| **medium** | e2-medium | 50GB | balanced | ~$35 |
| **large** | e2-standard-4 | 100GB | SSD | ~$150 |
| **xlarge** | e2-standard-8 | 200GB | SSD | ~$300 |

### Optional Features

- ✅ Data disks (configurable count and size)
- ✅ Automated backups with retention
- ✅ Monitoring agent installation
- ✅ Shielded VM (secure boot, vTPM, integrity)
- ✅ External IP (optional)
- ✅ Network tier selection

## 📦 What Gets Created

- **1 small web server** (dev) - $8/month
- **1 medium app server** (staging) + monitoring - $35/month
- **1 large database server** (production) + 2 data disks + backup + security - $500/month
- **1 custom server** - Custom configuration

## 🚀 Quick Start

```bash
cd lesson-04/flexible-module/

cp terraform.tfvars.example terraform.tfvars
# Edit project_id

terraform init
terraform plan
terraform apply

# View cost summary
terraform output cost_summary
```

## 🔍 Module Usage Patterns

### Pattern 1: Simple Sizing

```hcl
module "web_server" {
  source = "./modules/flexible-compute"
  
  name        = "web-server"
  sizing      = "small"    # That's it!
  environment = "dev"
}

# Gets: e2-micro, 20GB standard disk, ~$8/month
```

### Pattern 2: Sizing with Overrides

```hcl
module "app_server" {
  source = "./modules/flexible-compute"
  
  sizing       = "medium"
  disk_size_gb = 100     # Override default 50GB
  
  # Everything else from "medium" preset
}
```

### Pattern 3: Custom Configuration

```hcl
module "custom_server" {
  source = "./modules/flexible-compute"
  
  machine_type = "e2-standard-8"  # Explicit machine type
  disk_size_gb = 200
  disk_type    = "pd-ssd"
  
  # No sizing preset used
}
```

### Pattern 4: Production with Everything

```hcl
module "db_server" {
  source = "./modules/flexible-compute"
  
  sizing      = "large"
  environment = "production"
  
  # Data disks
  attach_data_disks = true
  data_disk_count   = 2
  data_disk_size_gb = 1000
  
  # Backup
  enable_backup           = true
  backup_retention_days   = 30
  
  # Security
  enable_secure_boot             = true
  enable_vtpm                    = true
  enable_integrity_monitoring    = true
  
  # Monitoring
  enable_monitoring = true
}
```

## 💡 Key Implementation Details

### Local Values for Logic

**The module uses locals to handle complex logic:**

```hcl
locals {
  # Determine if using sizing or custom
  use_sizing = var.machine_type == "" ? true : false
  
  # Select configuration
  selected_config = local.use_sizing ? 
    local.sizing_configs[var.sizing] : 
    {
      machine_type = var.machine_type
      disk_size_gb = var.disk_size_gb
      # ...
    }
  
  # Allow overrides
  final_disk_size = var.disk_size_gb != 0 ? 
    var.disk_size_gb : 
    local.selected_config.disk_size_gb
}
```

### Validation Rules

**Prevent invalid inputs:**

```hcl
variable "environment" {
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "sizing" {
  validation {
    condition     = contains(["small", "medium", "large", "xlarge"], var.sizing)
    error_message = "Sizing must be small, medium, large, or xlarge."
  }
}
```

### Dynamic Blocks for Optional Features

```hcl
# Only attach data disks if enabled
dynamic "attached_disk" {
  for_each = var.attach_data_disks ? range(var.data_disk_count) : []
  content {
    source = google_compute_disk.data_disks[attached_disk.value].self_link
  }
}

# Only add external IP if enabled
dynamic "access_config" {
  for_each = var.enable_external_ip ? [1] : []
  content {
    network_tier = var.network_tier
  }
}
```

### Lifecycle Rules

```hcl
lifecycle {
  # Prevent accidental deletion in production
  prevent_destroy = var.environment == "production" ? true : false
}
```

### Cost Calculation

```hcl
locals {
  base_cost      = local.selected_config.cost_per_month
  disk_cost      = (local.final_disk_size - 20) * 0.04
  data_disk_cost = var.attach_data_disks ? (var.data_disk_count * var.data_disk_size_gb * 0.17) : 0
  total_monthly_cost = local.base_cost + local.disk_cost + local.data_disk_cost
}

output "monthly_cost_estimate" {
  value = local.total_monthly_cost
}
```

## 📤 Example Outputs

```bash
$ terraform output cost_summary
{
  "custom_server" = 0
  "db_large" = 490
  "app_medium" = 36.2
  "total_monthly" = 534.2
  "web_small" = 8
}

$ terraform output db_large
{
  "backup_enabled" = true
  "data_disks" = [
    "db-large-data-0",
    "db-large-data-1",
  ]
  "machine_type" = "e2-standard-4"
  "monthly_cost_estimate" = 490
  "security_features" = {
    "secure_boot" = true
    "vtpm" = true
    "integrity_monitoring" = true
  }
  "sizing" = "large"
}
```

## 🧪 Experiments

### Experiment 1: Try Different Sizes

```hcl
sizing = "xlarge"  # Upgrade to xlarge
```

### Experiment 2: Add Data Disks

```hcl
attach_data_disks = true
data_disk_count   = 3
data_disk_size_gb = 500
```

### Experiment 3: Enable All Security

```hcl
enable_secure_boot          = true
enable_vtpm                 = true
enable_integrity_monitoring = true
```

### Experiment 4: Custom Machine Type

```hcl
machine_type = "e2-highmem-4"  # High memory variant
disk_size_gb = 150
```

## ✅ Validation Examples

**These will fail validation:**

```hcl
environment = "test"           # Error: Must be dev/staging/production
sizing = "tiny"                # Error: Must be small/medium/large/xlarge
disk_size_gb = 5               # Error: Min 10GB
backup_retention_days = 400    # Error: Max 365 days
data_disk_count = 15           # Error: Max 10 disks
```

## 🧹 Cleanup

```bash
terraform destroy
```

**Note:** Production instances with `prevent_destroy = true` cannot be destroyed without removing that lifecycle rule first.

## 📊 Module Comparison

### Basic Module (local-module)

```hcl
module "server" {
  source = "./modules/compute-instance"
  name   = "server"
  # Fixed configuration
}
```

**Pros:** Simple, straightforward  
**Cons:** Need to specify everything

### Flexible Module (this example)

```hcl
module "server" {
  source = "./modules/flexible-compute"
  name   = "server"
  sizing = "medium"  # Preset!
}
```

**Pros:** T-shirt sizing, validation, optional features  
**Cons:** More complex internally

## 🎓 What You Learned

✅ **T-shirt sizing** - Predefined configurations  
✅ **Local values** - Complex calculations in modules  
✅ **Validation** - Input constraints and error messages  
✅ **Dynamic blocks** - Conditional nested resources  
✅ **Lifecycle rules** - Protect production resources  
✅ **Cost estimation** - Calculate monthly costs  
✅ **Optional features** - Enable/disable capabilities  
✅ **Flexibility** - Presets OR custom configuration  

## 🏆 Advanced Patterns

This module demonstrates **production-grade** module design:

1. **Defaults with flexibility** - Sensible defaults, allow overrides
2. **Input validation** - Catch errors early
3. **Cost transparency** - Show estimated costs
4. **Environment awareness** - Different rules per environment
5. **Security by default** - Optional hardening features
6. **Comprehensive outputs** - Return everything useful

## ⏭️ Next Steps

- ✅ **Completed**: Flexible module patterns
- ⏭️ **Up next**: [registry-module/](../registry-module/) - Using public modules
- ⏭️ **Then**: [complete/](../complete/) - Multi-module architecture

---

**Flexible Modules Mastered!** 🎉

You now know how to build enterprise-grade reusable modules!
