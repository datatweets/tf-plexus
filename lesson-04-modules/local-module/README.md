# Local Module Example

Learn how to create and use **local Terraform modules** to eliminate code duplication.

## 🎯 What You'll Learn

- ✅ **Module structure** - Root vs child modules
- ✅ **Local modules** - Using `./modules/` directory
- ✅ **Module inputs** - Passing variables to modules
- ✅ **Module outputs** - Accessing module results
- ✅ **Module reuse** - Create 4 instances with 1 module
- ✅ **DRY principle** - Don't Repeat Yourself

## 🏗️ Project Structure

```
local-module/
├── main.tf                    ← Root module (uses child module)
├── variables.tf
├── outputs.tf
├── provider.tf
└── modules/
    └── compute-instance/      ← Child module (reusable)
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## 📦 What Gets Created

Using **1 reusable module** to create:

- **1 web server** (e2-micro)
- **1 app server** (e2-small)
- **2 worker servers** (e2-micro)

**Total:** 4 instances with ~60 lines of code (vs 300+ without modules)

## 🚀 Quick Start

```bash
cd lesson-04/local-module/

# Copy and configure
cp terraform.tfvars.example terraform.tfvars
# Edit project_id

# Initialize (downloads providers AND initializes modules)
terraform init

# See what will be created
terraform plan

# Deploy
terraform apply

# View outputs
terraform output
terraform output web_server
```

## 🔍 Understanding Modules

### Root Module (main.tf)

The **root module** is your main configuration that **calls** child modules:

```hcl
module "web_server" {
  source = "./modules/compute-instance"  # Local path
  
  # Pass inputs to module
  project_id   = var.project_id
  name         = "web-server-1"
  machine_type = "e2-micro"
}
```

### Child Module (modules/compute-instance/main.tf)

The **child module** is reusable code that creates resources:

```hcl
resource "google_compute_instance" "this" {
  name         = var.name          # From module input
  machine_type = var.machine_type  # From module input
  # ...
}
```

### Module Workflow

```
Root Module (main.tf)
    ↓ calls module 3 times
    ↓ passes different inputs
    ↓
Child Module (modules/compute-instance/)
    ↓ creates 3 instances
    ↓ returns outputs
    ↓
Root Module receives outputs
```

## 📊 Module Benefits

### Without Modules (Repetitive)

```hcl
# ~100 lines for web server
resource "google_compute_instance" "web" {
  name = "web-server"
  machine_type = "e2-micro"
  boot_disk { ... }
  network_interface { ... }
  # ... 20 more lines
}

# ~100 lines for app server (copy-paste with changes)
resource "google_compute_instance" "app" {
  name = "app-server"
  machine_type = "e2-small"
  boot_disk { ... }
  network_interface { ... }
  # ... 20 more lines
}

# ~100 lines for workers (more copy-paste)
resource "google_compute_instance" "worker_0" { ... }
resource "google_compute_instance" "worker_1" { ... }

# Total: 400+ lines of repetitive code
```

### With Modules (DRY)

```hcl
# 1 module definition (~40 lines)
# modules/compute-instance/main.tf

# 3 module calls (~45 lines total)
module "web_server" { source = "./modules/compute-instance"; name = "web" }
module "app_server" { source = "./modules/compute-instance"; name = "app" }
module "worker_servers" { count = 2; source = "./modules/compute-instance" }

# Total: ~85 lines (80% reduction!)
```

## 🔑 Key Concepts

### 1. Module Source

```hcl
module "example" {
  source = "./modules/compute-instance"  # Relative path
  # source = "../shared/compute"        # Parent directory
  # source = "/absolute/path/module"    # Absolute path
}
```

### 2. Passing Variables

**Root module passes data:**
```hcl
module "server" {
  source = "./modules/compute-instance"
  
  name         = "my-server"      # Required
  machine_type = "e2-micro"       # Optional (has default)
}
```

**Child module receives:**
```hcl
variable "name" {
  type = string
  # No default = required
}

variable "machine_type" {
  type    = string
  default = "e2-micro"  # Optional
}
```

### 3. Module Outputs

**Child module exposes data:**
```hcl
output "external_ip" {
  value = google_compute_instance.this.network_interface[0].access_config[0].nat_ip
}
```

**Root module accesses it:**
```hcl
module.server.external_ip
```

### 4. Multiple Module Instances

**Using count:**
```hcl
module "workers" {
  count  = 3
  source = "./modules/compute-instance"
  
  name = "worker-${count.index}"
}

# Access: module.workers[0].external_ip
```

**Using for_each:**
```hcl
module "servers" {
  for_each = toset(["web", "app", "db"])
  source   = "./modules/compute-instance"
  
  name = "${each.key}-server"
}

# Access: module.servers["web"].external_ip
```

## 🧪 Experiments

### Experiment 1: Add More Workers

```hcl
worker_count = 5
```

**Result:** Creates 5 worker instances

### Experiment 2: Different Machine Types

```hcl
module "large_server" {
  source       = "./modules/compute-instance"
  machine_type = "e2-medium"  # Override default
  # ...
}
```

### Experiment 3: Custom Disk Size

```hcl
module "big_disk_server" {
  source         = "./modules/compute-instance"
  boot_disk_size = 100  # 100GB instead of 20GB
  # ...
}
```

### Experiment 4: Add Metadata

```hcl
module "server_with_metadata" {
  source = "./modules/compute-instance"
  
  metadata = {
    startup-script = "apt-get update && apt-get install -y nginx"
    app-version    = "1.0.0"
  }
}
```

## 📤 Viewing Outputs

```bash
$ terraform output web_server
{
  "external_ip" = "34.83.10.20"
  "internal_ip" = "10.138.0.2"
  "name" = "web-server-1"
  "self_link" = "https://www.googleapis.com/compute/v1/..."
}

$ terraform output module_demonstration
{
  "modules_used" = 4
  "reusability_benefit" = "Created 4 instances with ~60 lines (vs ~300+ without modules)"
  "total_servers" = 4
}
```

## 🔄 Module Lifecycle

### 1. Initial Setup

```bash
terraform init
# Output:
# Initializing modules...
# - web_server in modules/compute-instance
# - app_server in modules/compute-instance
# - worker_servers in modules/compute-instance
```

### 2. After Module Changes

If you modify the **child module**, no need to re-init (unless you change source):

```bash
terraform plan  # Automatically uses updated module code
```

### 3. Targeting Specific Module

```bash
terraform apply -target=module.web_server
terraform destroy -target=module.worker_servers[0]
```

## 💡 Best Practices

### ✅ Do

- Keep modules **focused** (one purpose)
- Use **descriptive** variable names
- Provide **sensible defaults**
- Document with **descriptions**
- Use `this` for single resource in module
- Expose outputs for important attributes

### ❌ Don't

- Hardcode project IDs in modules
- Mix provider configs in child modules
- Create overly complex modules
- Use modules for single-use resources

## 🧹 Cleanup

```bash
terraform destroy
```

## 📚 Module File Structure

### Child Module (modules/compute-instance/)

```hcl
# main.tf - Resource definitions
resource "google_compute_instance" "this" { ... }

# variables.tf - Module inputs
variable "name" { ... }
variable "machine_type" { ... }

# outputs.tf - Module outputs
output "external_ip" { ... }
output "internal_ip" { ... }
```

### Root Module

```hcl
# main.tf - Call modules
module "server" { source = "./modules/compute-instance" }

# variables.tf - Root-level variables
variable "project_id" { ... }

# outputs.tf - Aggregate module outputs
output "all_ips" { value = [module.server.external_ip] }

# provider.tf - Provider configuration
provider "google" { ... }
```

## 🎓 What You Learned

✅ **Module structure** - Root and child modules  
✅ **Local paths** - Using `./modules/` directory  
✅ **Variable passing** - Root → Child  
✅ **Output access** - Child → Root  
✅ **Code reuse** - DRY principle  
✅ **Multiple instances** - count with modules  

## ⏭️ Next Steps

- ✅ **Completed**: Basic local modules
- ⏭️ **Up next**: [flexible-module/](../flexible-module/) - Advanced patterns
- ⏭️ **Then**: [registry-module/](../registry-module/) - Public modules

---

**Local Modules Mastered!** 🎉

You've reduced code by 80% and improved maintainability!
