# Managing Environments with Directory Structure

A practical example demonstrating how to manage multiple environments (dev, production) using separate directories with shared modules. This approach provides maximum flexibility for environments that differ significantly.

## 🎯 Learning Objectives

By completing this example, you will understand how to:

1. **Organize environments** with directory-based structure
2. **Share code via modules** - DRY principle with module reuse
3. **Configure environments independently** - Different resources per environment
4. **Manage separate state files** - Isolation and safety
5. **Scale environments differently** - Different topologies and sizes

## 🏗️ Architecture

### Directory Structure

```
directory-structure/
├── modules/
│   └── server/              # Reusable server module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── startup.sh.tftpl
├── dev/                     # Development environment
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── backend.tf
│   └── terraform.tfvars.example
└── prod/                    # Production environment
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── backend.tf
    └── terraform.tfvars.example
```

### Environment Comparison

| Resource | Dev | Production |
|----------|-----|------------|
| **Web Servers** | 1 (e2-micro) | 2 (e2-medium) with static IPs |
| **App Servers** | 1 (e2-small) | 2 (e2-standard-2) |
| **Database** | None | 1 (e2-standard-4) |
| **Monitoring** | None | 1 (e2-medium) |
| **Total Cost** | ~$26/month | ~$385/month |

## 🚀 Quick Start

### Deploy Development Environment

```bash
# Navigate to dev directory
cd dev

# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project ID

# Initialize and deploy
terraform init
terraform plan
terraform apply

# View outputs
terraform output
```

### Deploy Production Environment

```bash
# Navigate to prod directory
cd ../prod

# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project ID

# Initialize and deploy
terraform init
terraform plan
terraform apply

# View outputs
terraform output
```

## 🔑 Key Features

### 1. Shared Module

The `modules/server` module provides reusable compute instance configuration:

**T-shirt Sizing:**
- micro: e2-micro, 10GB disk
- small: e2-small, 20GB disk
- medium: e2-medium, 50GB disk
- large: e2-standard-2, 100GB disk
- xlarge: e2-standard-4, 200GB disk

### 2. Environment-Specific Configuration

**Dev** (dev/main.tf):
```hcl
module "web_server" {
  source = "../modules/server"
  
  name        = "dev-web"
  size        = "micro"
  environment = "dev"
  # ...
}

module "app_server" {
  source = "../modules/server"
  
  name        = "dev-app"
  size        = "small"
  environment = "dev"
  # ...
}
```

**Prod** (prod/main.tf):
```hcl
module "web_server_1" { size = "medium" }
module "web_server_2" { size = "medium" }
module "app_server_1" { size = "large" }
module "app_server_2" { size = "large" }
module "db_server" { size = "xlarge" }
# Plus monitoring server
```

### 3. Independent State Files

Each environment has its own backend configuration:

```hcl
# dev/backend.tf
backend "gcs" {
  bucket = "my-terraform-state"
  prefix = "lesson-05/directory-structure/dev"
}

# prod/backend.tf
backend "gcs" {
  bucket = "my-terraform-state"
  prefix = "lesson-05/directory-structure/prod"
}
```

## 🧪 Experiments

### Experiment 1: Compare Environments

Deploy both environments and compare:

```bash
# Deploy dev
cd dev && terraform apply
terraform output deployment_summary

# Deploy prod
cd ../prod && terraform apply
terraform output deployment_summary
```

**Observations:**
- Dev: 2 servers, ~$26/month
- Prod: 6 servers, ~$385/month
- Different configurations for same module
- Prod has monitoring + database

### Experiment 2: Add Staging Environment

Create a third environment:

```bash
# Create staging directory
mkdir -p staging
cp dev/*.tf staging/
cd staging

# Edit main.tf to use medium instances
# Edit backend.tf to use staging prefix
terraform init
terraform apply
```

### Experiment 3: Modify Prod Without Affecting Dev

```bash
# Add third web server to prod
cd prod
# Edit main.tf to add module "web_server_3"
terraform apply

# Verify dev is unchanged
cd ../dev
terraform state list  # Shows only 2 servers
```

### Experiment 4: Test Module Changes

Modify the shared module:

```bash
# Edit modules/server/main.tf
# Add new label or configuration

# Test in dev first
cd dev && terraform plan

# If good, apply to prod
cd ../prod && terraform plan
```

## 💡 Advantages Over Workspaces

1. **Complete Flexibility** - Environments can be completely different
2. **Clear Separation** - Each environment is self-contained
3. **Team Ownership** - Different teams can own different directories
4. **Independent Lifecycles** - Deploy/destroy independently
5. **Different Provider Versions** - Each can use different versions
6. **Better for Large Teams** - No workspace conflicts

## 📊 Module Benefits

### Code Reuse

**Without modules:**
```
dev/main.tf: 150 lines
prod/main.tf: 300 lines
Total: 450 lines (lots of duplication)
```

**With modules:**
```
modules/server/: 100 lines
dev/main.tf: 40 lines
prod/main.tf: 140 lines
Total: 280 lines (38% reduction)
```

### Maintenance

**Change machine type:**
- Without modules: Edit 6+ files
- With modules: Edit 1 file (module) or variable values

## 🎓 What You've Learned

1. ✅ **Directory organization** - Separate directories per environment
2. ✅ **Module reuse** - Shared code via modules
3. ✅ **Independent configuration** - Different resources per environment
4. ✅ **State isolation** - Separate state files
5. ✅ **Flexible deployment** - Deploy environments independently

## 🧹 Cleanup

```bash
# Destroy prod
cd prod
terraform destroy

# Destroy dev
cd ../dev
terraform destroy
```

## 📚 Best Practices

1. **Keep same file structure** across environments
2. **Use relative module paths**
3. **Document each environment's purpose**
4. **Use consistent naming conventions**
5. **Tag resources with environment labels**

## 🔄 Workflow

### Daily Development
```bash
# Work in dev
cd dev
terraform apply

# Test changes
# ...

# Promote to prod when ready
cd ../prod
terraform apply
```

### Environment Promotion
```bash
# 1. Test in dev
cd dev && terraform apply

# 2. After validation, replicate changes in prod
cd ../prod
# Update main.tf with same changes
terraform apply
```

## 🎯 Next Steps

- Explore [remote-state](../remote-state/) for sharing data between layers
- See [complete](../complete/) for production multi-layer architecture
- Compare with [workspaces](../workspaces/) approach

---

**Time to Complete:** 1-2 hours

**Difficulty:** Intermediate

**Best For:** Production deployments with different environment configurations
