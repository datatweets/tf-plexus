# Production Multi-Tier Architecture with Modules

A comprehensive example demonstrating production-ready infrastructure using multiple custom Terraform modules. This example shows how to build a complete 3-tier web application architecture with networking, load balancing, monitoring, and storage.

## 🎯 Learning Objectives

By completing this example, you will understand how to:

1. **Design Multi-Module Architecture** - Structure complex infrastructure using multiple custom modules
2. **Module Dependencies** - Handle inter-module relationships and data passing
3. **Environment-Aware Configuration** - Different settings for dev vs production
4. **Production Patterns** - Implement high availability, monitoring, and backups
5. **Module Composition** - Combine modules to create cohesive systems
6. **Infrastructure Organization** - Separate concerns across logical tiers

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        Internet                              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
                 ┌──────────────┐
                 │ Load Balancer│ (Public)
                 └───────┬──────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  Web Server  │ │  Web Server  │ │  Web Server  │
│   (nginx)    │ │   (nginx)    │ │   (nginx)    │
└──────┬───────┘ └──────┬───────┘ └──────┬───────┘
       │                │                │
       └────────────────┼────────────────┘
                        │
                        ▼
               ┌────────────────┐
               │ App Tier       │
               │ (2x instances) │
               └────────┬───────┘
                        │
                        ▼
               ┌────────────────┐
               │  Database      │
               │  (PostgreSQL)  │
               └────────────────┘

┌──────────────────────────────────────────┐
│  Management Network                      │
│  ┌──────────────┐  ┌─────────────────┐ │
│  │  Monitoring  │  │  Cloud Storage  │ │
│  │  (Bastion)   │  │  (3 buckets)    │ │
│  └──────────────┘  └─────────────────┘ │
└──────────────────────────────────────────┘
```

### Network Topology

- **Frontend Subnet (10.0.1.0/24)** - Web tier with public access
- **Application Subnet (10.0.2.0/24)** - App tier (private)
- **Database Subnet (10.0.3.0/24)** - Data tier (private)
- **Management Subnet (10.0.4.0/24)** - Monitoring and bastion

## 📦 Modules Used

This example uses **7 custom modules** to build the complete infrastructure:

| Module | Purpose | Resources Created |
|--------|---------|-------------------|
| `networking` | VPC, subnets, firewall rules | 1 VPC, 4 subnets, 6 firewall rules |
| `web-tier` | Web servers (nginx) | 2+ compute instances |
| `app-tier` | Application servers | 2+ compute instances |
| `data-tier` | Database server | 1 instance, 1 data disk, backup policy |
| `load-balancer` | HTTP load balancer | LB, health check, backend service |
| `monitoring` | Monitoring/bastion server | 1 instance with Prometheus/Grafana |
| `storage` | Cloud Storage buckets | 3 buckets (assets, backups, logs) |

## 🚀 Quick Start

### Prerequisites

- Terraform >= 1.9
- GCP account with billing enabled
- `gcloud` CLI authenticated

### Setup

1. **Clone and navigate to this directory:**

```bash
cd lesson-04/complete
```

2. **Configure your project:**

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
project_id = "your-gcp-project-id"
project_name = "multi-tier-app"
region = "us-west1"
environment = "dev"  # Start with dev

# Instance counts
web_instance_count = 2
app_instance_count = 2

# Optional features
enable_monitoring = true
```

3. **Deploy the infrastructure:**

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy
terraform apply
```

4. **Access your application:**

```bash
# Get the load balancer IP
terraform output -json access_info | jq -r '.application_url'

# Test the application
curl http://<LOAD_BALANCER_IP>
```

## 📊 What Gets Created

### Development Environment

```bash
terraform apply -var="environment=dev"
```

Creates:
- 1 VPC with 4 subnets
- 2 web servers (e2-micro)
- 2 app servers (e2-small)
- 1 database server (e2-medium)
- 1 load balancer
- 3 storage buckets
- 1 monitoring server (e2-micro)

**Estimated Monthly Cost:** ~$100-150

### Production Environment

```bash
terraform apply -var="environment=production"
```

Creates:
- Same architecture with larger instances
- Web servers: e2-medium
- App servers: e2-standard-2
- Database: e2-standard-4 with 200GB disk
- Automated backups enabled
- Monitoring: e2-medium

**Estimated Monthly Cost:** ~$400-500

## 🧩 Module Architecture

### Module Dependencies

```
networking (no dependencies)
    ├── web-tier (depends on networking)
    ├── app-tier (depends on networking, data-tier)
    ├── data-tier (depends on networking)
    ├── load-balancer (depends on networking, web-tier)
    ├── monitoring (depends on networking, all tiers)
    └── storage (no dependencies)
```

### Data Flow Between Modules

1. **Networking** provides:
   - Network ID
   - Subnet IDs
   
2. **Web-tier** provides:
   - Instance self-links (for load balancer)
   - Instance names (for monitoring)
   
3. **App-tier** receives:
   - Database IP from data-tier
   
4. **Load-balancer** receives:
   - Backend instances from web-tier
   
5. **Monitoring** receives:
   - List of all instance names

## 💡 Key Concepts Demonstrated

### 1. Module Composition

Combining multiple modules to create a cohesive system:

```hcl
module "networking" {
  source = "./modules/networking"
  # ...
}

module "web_tier" {
  source = "./modules/web-tier"
  
  # Uses output from networking module
  network_id = module.networking.network_id
  subnet_id  = module.networking.frontend_subnet_id
}
```

### 2. Module Dependencies

Modules can depend on outputs from other modules:

```hcl
module "app_tier" {
  # ...
  
  # Depends on data-tier output
  db_host = module.data_tier.db_private_ip
}
```

### 3. Conditional Modules

Modules can be conditionally created:

```hcl
module "monitoring" {
  count = var.enable_monitoring ? 1 : 0
  
  # ...
}
```

### 4. Environment-Aware Configuration

Different settings based on environment:

```hcl
machine_type = var.environment == "production" ? "e2-standard-2" : "e2-small"
enable_backup = var.environment == "production"
```

### 5. Common Labels

Shared labels across all resources:

```hcl
locals {
  common_labels = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Pass to all modules
labels = local.common_labels
```

### 6. Dynamic Backend Configuration

Using splat expressions for dynamic lists:

```hcl
backend_instances = module.web_tier.instance_self_links

monitored_instances = concat(
  module.web_tier.instance_names,
  module.app_tier.instance_names,
  [module.data_tier.db_instance_name]
)
```

## 🔍 Exploring the Code

### Root Module (`main.tf`)

The root module orchestrates all child modules:

```bash
# View module calls
grep -A 10 "^module" main.tf

# See how modules connect
grep "module\." main.tf | grep "="
```

### Networking Module

Creates the VPC foundation:

```bash
cat modules/networking/main.tf | grep "^resource"
```

Provides:
- 1 VPC network
- 4 subnets (frontend, application, database, management)
- 6 firewall rules

### Compute Modules

Three tiers of compute:

```bash
# Web tier
ls -la modules/web-tier/

# App tier
ls -la modules/app-tier/

# Data tier
ls -la modules/data-tier/
```

Each has:
- `main.tf` - Resource definitions
- `variables.tf` - Input variables
- `outputs.tf` - Output values

## 🧪 Experiments

### Experiment 1: Scale Web Tier

Try changing the number of web servers:

```bash
# Edit terraform.tfvars
web_instance_count = 4

# Apply the change
terraform apply

# Verify
terraform output web_tier
```

**What to observe:**
- New instances created
- Load balancer automatically updated
- Instance groups reconfigured

### Experiment 2: Add/Remove Monitoring

Toggle the monitoring module:

```bash
# Disable monitoring
terraform apply -var="enable_monitoring=false"

# Re-enable monitoring
terraform apply -var="enable_monitoring=true"
```

**What to observe:**
- Conditional module creation
- Outputs change accordingly
- Access info updates

### Experiment 3: Environment Promotion

Promote from dev to production:

```bash
# Start with dev
terraform apply -var="environment=dev"

# Check costs
terraform output estimated_monthly_cost

# Promote to production
terraform apply -var="environment=production"

# Compare costs
terraform output estimated_monthly_cost
```

**What to observe:**
- Instance sizes change
- Disk sizes increase
- Backups enabled
- Costs increase significantly

### Experiment 4: Module Isolation

Make changes to a single module:

```bash
# Edit web-tier module
vim modules/web-tier/main.tf

# Plan shows only web-tier changes
terraform plan | grep "module.web_tier"
```

**What to observe:**
- Changes isolated to one module
- Other modules unaffected
- Clean separation of concerns

### Experiment 5: Add Custom Module

Create a new module for caching:

```bash
# Create module directory
mkdir -p modules/cache-tier

# Create module files
cat > modules/cache-tier/main.tf <<'EOF'
resource "google_compute_instance" "redis" {
  name         = "${var.project_id}-redis"
  machine_type = "e2-small"
  zone         = var.zone
  # ...
}
EOF

# Add to main.tf
module "cache_tier" {
  source = "./modules/cache-tier"
  # ...
}
```

**What to observe:**
- Extending architecture easily
- Module pattern reuse
- Clean addition without modifying existing code

## 📈 Scaling Considerations

### Horizontal Scaling

Increase instance counts:

```hcl
web_instance_count = 5  # Scale from 2 to 5
app_instance_count = 3  # Scale from 2 to 3
```

### Vertical Scaling

Increase instance sizes:

```hcl
# Override default sizing
terraform apply \
  -var="environment=production" \
  -var="web_instance_count=2"
```

### Multi-Region Deployment

To deploy across multiple regions, create a wrapper:

```hcl
# multi-region/main.tf
module "us_west" {
  source = "../complete"
  region = "us-west1"
  # ...
}

module "us_east" {
  source = "../complete"
  region = "us-east1"
  # ...
}
```

## 🔒 Security Considerations

### Network Segmentation

```
✓ Web tier: Public subnet with external IPs
✓ App tier: Private subnet (no external IPs)
✓ Data tier: Private subnet (no external IPs)
✓ Management: Separate subnet for operations
```

### Firewall Rules

```
✓ Web tier: Only ports 80/443 from internet
✓ App tier: Only accessible from web tier
✓ Database: Only accessible from app tier
✓ SSH: Only from management subnet
```

### Production Hardening

For production deployment:

1. **Enable prevent_destroy:**
```hcl
# In data-tier module
lifecycle {
  prevent_destroy = true
}
```

2. **Use static IPs for load balancer:**
```hcl
use_static_ip = true
```

3. **Enable backups:**
```hcl
enable_backup = true
```

4. **Use secrets management:**
```hcl
# Don't hardcode passwords
# Use Secret Manager or similar
```

## 📊 Outputs

The example provides comprehensive outputs:

```bash
# Network information
terraform output network

# Tier information
terraform output web_tier
terraform output app_tier
terraform output data_tier

# Access endpoints
terraform output access_info

# Deployment summary
terraform output deployment_summary

# Cost estimates
terraform output estimated_monthly_cost

# Module architecture
terraform output module_architecture
```

## 🎓 What You've Learned

After completing this example, you now understand:

1. ✅ **Multi-Module Architecture** - How to structure complex infrastructure with multiple modules
2. ✅ **Module Dependencies** - Passing data between modules and handling dependencies
3. ✅ **Production Patterns** - High availability, backups, monitoring, security
4. ✅ **Environment Management** - Different configurations for dev and production
5. ✅ **Module Composition** - Combining modules to create complete systems
6. ✅ **Scalability** - Horizontal and vertical scaling patterns
7. ✅ **Infrastructure Organization** - Logical separation of concerns
8. ✅ **Cost Management** - Understanding cost implications of different configurations

## 🧹 Cleanup

**Important:** This example creates many resources. Clean up to avoid charges:

```bash
# Destroy all resources
terraform destroy

# Verify everything is deleted
gcloud compute instances list
gcloud compute networks list
gcloud storage buckets list
```

## 🔄 Real-World Usage

This architecture pattern is suitable for:

- **Multi-tier web applications**
- **Microservices architecture**
- **SaaS platforms**
- **E-commerce applications**
- **Content management systems**
- **API backends with databases**

## 📚 Module Benefits Summary

| Benefit | Traditional Approach | Multi-Module Approach |
|---------|---------------------|----------------------|
| **Code Reuse** | Copy/paste code | Import modules |
| **Maintenance** | Update multiple places | Update one module |
| **Testing** | Test entire stack | Test modules independently |
| **Scaling** | Duplicate code | Adjust counts/sizes |
| **Organization** | One large file | Logical separation |
| **Team Collaboration** | Merge conflicts | Work on separate modules |
| **Environment Promotion** | Duplicate configs | Same modules, different vars |

## 🎯 Next Steps

1. **Experiment** with different configurations
2. **Add modules** for caching, messaging, etc.
3. **Implement CI/CD** for automated deployments
4. **Add testing** with Terratest or similar
5. **Create module registry** for your organization
6. **Document modules** for team usage
7. **Build module library** of common patterns

## 📖 Related Examples

- [local-module/](../local-module/) - Basic module usage
- [flexible-module/](../flexible-module/) - Advanced module patterns
- [registry-module/](../registry-module/) - Using public modules

## 💡 Tips and Tricks

### Tip 1: Module Versioning

When sharing modules, use version constraints:

```hcl
module "networking" {
  source  = "git::https://github.com/your-org/tf-modules.git//networking?ref=v1.0.0"
  version = "~> 1.0"
}
```

### Tip 2: Module Testing

Test modules independently:

```bash
cd modules/web-tier
terraform init
terraform plan -var="project_id=test" -var="zone=us-west1-a"
```

### Tip 3: Cost Optimization

Start with dev, promote to production:

```bash
# Develop with minimal resources
terraform workspace new dev
terraform apply -var="environment=dev"

# Promote to production
terraform workspace new production
terraform apply -var="environment=production"
```

### Tip 4: Module Documentation

Document each module's README.md:

```bash
# Generate module documentation
terraform-docs markdown modules/web-tier/ > modules/web-tier/README.md
```

## 🐛 Troubleshooting

### Issue: Module not found

```
Error: Module not found: ./modules/web-tier
```

**Solution:** Ensure module directories exist and contain required files.

### Issue: Circular dependency

```
Error: Cycle: module.a -> module.b -> module.a
```

**Solution:** Refactor to break the circular dependency. Use data sources or restructure modules.

### Issue: Different resources but same name

```
Error: Resource already exists
```

**Solution:** Use unique naming with `project_id` or `environment` prefix.

---

**Time to Complete:** 2-3 hours

**Difficulty:** Advanced

**Prerequisites:** Complete local-module, flexible-module, and registry-module examples

