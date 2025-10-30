# Registry Module Example

Learn to use **public modules** from Terraform Registry - leverage battle-tested, community-maintained code.

## 🎯 What You'll Learn

- ✅ **Terraform Registry** - Finding and using public modules
- ✅ **Module versioning** - Pinning module versions
- ✅ **Google modules** - Official Google Cloud modules
- ✅ **Module composition** - Combining multiple modules
- ✅ **Best practices** - When to use registry vs custom modules
- ✅ **Code reduction** - 70% less code than resources

## 📦 What Gets Created

Using **5 public registry modules**:

- **VPC Network** - Using `terraform-google-modules/network/google`
- **Managed Instance Group (2 VMs)** - Using `terraform-google-modules/vm/google//modules/mig`
- **PostgreSQL Database** - Using `GoogleCloudPlatform/sql-db/google`
- **2 Cloud Storage Buckets** - Using `terraform-google-modules/cloud-storage/google`
- **HTTP Load Balancer** - Using `GoogleCloudPlatform/lb-http/google`

## 🚀 Quick Start

```bash
cd lesson-04/registry-module/

cp terraform.tfvars.example terraform.tfvars
# Edit project_id

# Initialize (downloads registry modules!)
terraform init

terraform plan
terraform apply

# View what modules created
terraform output deployment_summary

# Connect to PostgreSQL database
gcloud beta sql connect registry-demo-db \
  --user=postgres \
  --database=default \
  --project=your-project-id
# Password: Postgres123!
```

## 🔍 Understanding Registry Modules

### Module Source Format

```hcl
module "example" {
  source  = "namespace/name/provider"
  version = "~> 1.0"
  
  # Module inputs
}
```

**Parts:**
- `namespace` - Publisher (e.g., `terraform-google-modules`)
- `name` - Module name (e.g., `network`)
- `provider` - Cloud provider (e.g., `google`)
- `version` - Semantic version constraint

### Version Constraints

```hcl
version = "1.0.0"      # Exact version
version = "~> 1.0"     # >= 1.0.0, < 2.0.0
version = ">= 1.0"     # Any version >= 1.0.0
version = "~> 1.0.5"   # >= 1.0.5, < 1.1.0
```

**Best practice:** Use `~>` for minor version updates

### Submodules

Some modules have submodules for specific use cases:

```hcl
# Root module
source = "terraform-google-modules/vm/google"

# Submodule (note the //)
source = "terraform-google-modules/vm/google//modules/compute_instance"
```

## 📚 Modules Used in This Example

### 1. Network Module

```hcl
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 9.0"
  
  network_name = "my-vpc"
  subnets = [...]
  firewall_rules = [...]
}
```

**What it does:**
- Creates VPC network
- Creates subnets
- Creates firewall rules
- Handles routing

**vs doing it manually:** ~200 lines → 30 lines

### 2. Managed Instance Group Module

```hcl
module "web_servers" {
  source  = "terraform-google-modules/vm/google//modules/mig"
  version = "~> 11.0"
  
  region            = var.region
  hostname          = "web"
  instance_template = module.web_instance_template.self_link
  target_size       = 2
}
```

**What it does:**
- Creates managed instance group (MIG)
- Manages instance lifecycle
- Provides auto-scaling and auto-healing
- Integrates with load balancers
- Sets up health checks

**Why MIG instead of compute_instance?**
- Load balancers require instance groups (not individual instances)
- Auto-scaling support
- High availability across zones
- Automatic health monitoring

**vs doing it manually:** ~150 lines → 20 lines

### 3. Cloud SQL Module

```hcl
module "postgresql" {
  source  = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version = "~> 20.0"
  
  database_version = "POSTGRES_15"
  tier             = "db-f1-micro"
  
  # Creates postgres user with password
  user_name     = "postgres"
  user_password = "Postgres123!"
}
```

**What it does:**
- Creates Cloud SQL instance
- Configures high availability
- Sets up backups
- Manages users and databases
- Creates postgres superuser with password

**Connection:**
```bash
gcloud beta sql connect registry-demo-db \
  --user=postgres \
  --database=default \
  --project=your-project-id
```
Password: `Postgres123!`

**vs doing it manually:** ~100 lines → 15 lines

### 4. Cloud Storage Module

```hcl
module "gcs_buckets" {
  source  = "terraform-google-modules/cloud-storage/google"
  version = "~> 6.0"
  
  names = ["assets", "backups"]
  lifecycle_rules = [...]
}
```

**What it does:**
- Creates multiple buckets
- Sets up lifecycle rules
- Configures IAM bindings
- Handles versioning

### 5. Load Balancer Module

```hcl
module "load_balancer" {
  source  = "GoogleCloudPlatform/lb-http/google"
  version = "~> 11.0"
  
  backends = {...}
}
```

**What it does:**
- Creates HTTP(S) load balancer
- Configures backend services
- Sets up health checks
- Manages SSL certificates (optional)

## 🔎 Finding Registry Modules

### Terraform Registry Website

Visit: https://registry.terraform.io/

**Search for:**
- "google network" → Network module
- "google vm" → VM modules
- "google sql" → Database modules
- "google gcs" → Storage modules

### Module Quality Indicators

✅ **Official** - Published by HashiCorp or provider  
✅ **Verified** - Reviewed by HashiCorp  
⭐ **Stars** - Community endorsement  
📥 **Downloads** - Usage statistics  
📝 **Documentation** - Complete examples  
🧪 **Tests** - Automated testing  

### Recommended Google Modules

| Module | Publisher | Use Case |
|--------|-----------|----------|
| `network/google` | terraform-google-modules | VPC, subnets, firewall |
| `vm/google//modules/mig` | terraform-google-modules | Managed instance groups |
| `vm/google//modules/compute_instance` | terraform-google-modules | Individual compute instances |
| `sql-db/google` | GoogleCloudPlatform | Cloud SQL databases |
| `cloud-storage/google` | terraform-google-modules | GCS buckets |
| `lb-http/google` | GoogleCloudPlatform | Load balancers |
| `kubernetes-engine/google` | terraform-google-modules | GKE clusters |

## 💡 Registry vs Custom Modules

### Use Registry Modules When:

✅ Common infrastructure patterns (VPC, VMs, databases)  
✅ Complex resources (load balancers, GKE)  
✅ Best practices needed (security, HA)  
✅ Want community support  
✅ Don't want to maintain code  

### Use Custom Modules When:

✅ Specific business logic  
✅ Non-standard configurations  
✅ Internal company standards  
✅ Simple wrappers  
✅ Learning/education  

### Combine Both:

```hcl
# Registry module for VPC
module "vpc" {
  source = "terraform-google-modules/network/google"
  # ...
}

# Custom module for company-specific VMs
module "app_servers" {
  source = "./modules/company-app-server"
  # ...
}
```

## 🧪 Experiments

### Experiment 1: Add More Web Servers

```hcl
module "web_servers" {
  target_size = 5  # Change from 2 to 5
}
```

### Experiment 2: Upgrade Database

```hcl
module "postgresql" {
  tier = "db-n1-standard-1"  # Bigger instance
  
  # Change password (optional)
  user_password = "YourNewSecurePassword123!"
}
```

### Experiment 3: Add More Subnets

```hcl
module "vpc" {
  subnets = [
    {
      subnet_name   = "subnet-1"
      subnet_ip     = "10.0.0.0/24"
      subnet_region = "us-west1"
    },
    {
      subnet_name   = "subnet-2"
      subnet_ip     = "10.1.0.0/24"
      subnet_region = "us-west1"
    }
  ]
}
```

## 📤 Example Outputs

```bash
$ terraform output deployment_summary
{
  "modules_used" = {
    "GoogleCloudPlatform/lb-http/google" = "HTTP Load Balancer"
    "GoogleCloudPlatform/sql-db/google" = "PostgreSQL database"
    "terraform-google-modules/cloud-storage/google" = "Cloud Storage buckets"
    "terraform-google-modules/network/google" = "VPC and firewall rules"
    "terraform-google-modules/vm/google" = "Web servers with instance template"
  }
  "resources_created" = {
    "databases" = 1
    "firewall_rules" = 2
    "load_balancers" = 1
    "storage_buckets" = 2
    "subnets" = 2
    "vpc_networks" = 1
    "web_servers" = 2
  }
  "benefits" = [
    "No need to write VPC/subnet/firewall code",
    "Managed database with best practices",
    "Production-ready load balancer",
    "Maintained and tested by Google/community",
    "Reduced code by ~70%"
  ]
}
```

## 🔌 Connecting to PostgreSQL Database

After deployment, connect to your PostgreSQL database:

```bash
# Connect using gcloud (easiest method)
gcloud beta sql connect registry-demo-db \
  --user=postgres \
  --database=default \
  --project=your-project-id
```

**Credentials:**
- **Username:** `postgres`
- **Password:** `Postgres123!`
- **Database:** `default`

**Alternative: Using psql directly**
```bash
# Get database IP
terraform output database

# Connect with psql
psql "host=<DB_PUBLIC_IP> dbname=default user=postgres sslmode=require"
```

**⚠️ Security Note:** In production, use Secret Manager for passwords and consider private IP connections.

### Prerequisites for Database Connection

If you don't have the gcloud beta SQL components installed, install them first:

```bash
# Install gcloud beta components (includes Cloud SQL Proxy v1)
gcloud components install beta

# Verify installation
gcloud components list | grep beta
```

After installation, you can use the `gcloud beta sql connect` command to connect to your database.

## 🔄 Module Updates

### Check for Updates

```bash
# See current versions
terraform version
terraform providers

# Check registry for new versions
# Visit: https://registry.terraform.io/modules/...
```

### Update Module Version

```hcl
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 10.0"  # Updated from 9.0
}
```

```bash
terraform init -upgrade
terraform plan  # Review changes
terraform apply
```

## ⚠️ Important Considerations

### Version Pinning

**❌ Don't:**
```hcl
version = ">= 1.0"  # Too loose, can break
```

**✅ Do:**
```hcl
version = "~> 9.0"  # Safe minor updates
```

### Security Best Practices

**Database Passwords:**
- The example uses a hardcoded password for simplicity
- **In production:** Store passwords in Secret Manager or use IAM authentication
- **Never commit** passwords to version control

**Example with Secret Manager:**
```hcl
data "google_secret_manager_secret_version" "db_password" {
  secret = "postgres-password"
}

module "postgresql" {
  user_password = data.google_secret_manager_secret_version.db_password.secret_data
}
```

### Module Documentation

Always read the module's documentation:
- Required inputs
- Optional inputs
- Outputs available
- Examples
- Changelog

### State Management

Registry modules create **many** resources. Be careful with:
- `terraform destroy` - Reviews all resources
- Module version changes - May require recreation
- Moving resources - Use `terraform state mv`

## 🧹 Cleanup

```bash
terraform destroy
```

**Warning:** This destroys all resources from all modules (VPC, VMs, database, storage, load balancer).

## 🎓 What You Learned

✅ **Finding modules** - Terraform Registry search  
✅ **Module syntax** - `namespace/name/provider`  
✅ **Versioning** - Semantic version constraints  
✅ **Submodules** - Using `//modules/...`  
✅ **Combining modules** - Multi-module architecture  
✅ **Code reduction** - 70% less code  
✅ **Best practices** - When to use registry modules  

## 📊 Code Comparison

### Without Modules (~600 lines)

```hcl
resource "google_compute_network" "vpc" { ... }        # 20 lines
resource "google_compute_subnetwork" "subnet" { ... }  # 15 lines
resource "google_compute_firewall" "ssh" { ... }       # 15 lines
resource "google_compute_firewall" "http" { ... }      # 15 lines
resource "google_compute_instance_template" { ... }    # 40 lines
resource "google_compute_instance_group_manager" { ... } # 30 lines
resource "google_sql_database_instance" { ... }        # 50 lines
resource "google_storage_bucket" "assets" { ... }      # 25 lines
resource "google_storage_bucket" "backups" { ... }     # 25 lines
resource "google_compute_global_forwarding_rule" { ... } # 20 lines
resource "google_compute_backend_service" { ... }      # 40 lines
# ... many more resources
```

### With Registry Modules (~180 lines)

```hcl
module "vpc" { source = "..."; subnets = [...]; firewall_rules = [...] }
module "web_servers" { source = ".../mig"; target_size = 2; ... }
module "postgresql" { source = "..."; tier = "..."; ... }
module "gcs_buckets" { source = "..."; names = [...]; ... }
module "load_balancer" { source = "..."; backends = {...}; ... }
```

**Result:** 70% code reduction + best practices included!

## ⏭️ Next Steps

- ✅ **Completed**: Using registry modules
- ⏭️ **Up next**: [complete/](../complete/) - Production multi-module architecture
- 📖 **Review**: [Section 2 Tutorial](../section-02-advanced-modules.md)

---

**Registry Modules Mastered!** 🎉

You now know how to leverage the power of community modules!
