# Managing Environments with Terraform Workspaces

A practical example demonstrating how to use Terraform workspaces to manage multiple environments (dev, staging, production) with a single configuration.

## 🎯 Learning Objectives

By completing this example, you will understand how to:

1. **Create and manage workspaces** - Use workspace commands effectively
2. **Implement workspace-aware configuration** - Adapt resources based on workspace
3. **Use workspace-specific variables** - Different values per environment
4. **Deploy to multiple environments** - Independent deployments with shared code
5. **Handle conditional resources** - Resources that only exist in certain workspaces

## 🏗️ What This Example Creates

This example deploys a multi-tier web application with environment-specific sizing:

### Default/Dev Workspace
- 2 web servers (e2-micro)
- 2 app servers (e2-small)
- **No monitoring server**
- ~$52/month

### Staging Workspace
- 2 web servers (e2-small)
- 2 app servers (e2-medium)
- **No monitoring server**
- ~$106/month

### Production Workspace
- 3 web servers (e2-medium)
- 3 app servers (e2-standard-2)
- **1 monitoring server** (e2-medium)
- ~$315/month

## 📦 Files in This Example

```
workspaces/
├── main.tf                      # Main configuration with workspace logic
├── variables.tf                 # Variable definitions
├── outputs.tf                   # Comprehensive outputs
├── provider.tf                  # Provider configuration
├── terraform.tfvars.example     # Dev environment variables
├── staging.tfvars.example       # Staging environment variables
├── prod.tfvars.example          # Production environment variables
├── .gitignore                   # Git ignore rules
└── README.md                    # This file
```

## 🚀 Quick Start

### Prerequisites

- Terraform >= 1.9
- GCP account with billing enabled
- `gcloud` CLI authenticated
- Two or more GCP projects (recommended)

### Setup

1. **Copy example variable files:**

```bash
cp terraform.tfvars.example terraform.tfvars
cp prod.tfvars.example prod.tfvars
cp staging.tfvars.example staging.tfvars
```

2. **Edit variable files with your project IDs:**

```bash
# terraform.tfvars (for default/dev workspace)
project_id = "my-dev-project-id"

# staging.tfvars
project_id = "my-staging-project-id"

# prod.tfvars
project_id = "my-prod-project-id"
```

### Deploy to Development

```bash
# Initialize Terraform
terraform init

# View available workspaces (should show * default)
terraform workspace list

# Plan and apply (uses terraform.tfvars by default)
terraform plan
terraform apply

# View outputs
terraform output
```

### Deploy to Staging

```bash
# Create and switch to staging workspace
terraform workspace new staging

# Verify current workspace
terraform workspace show

# Deploy with staging variables
terraform plan -var-file="staging.tfvars"
terraform apply -var-file="staging.tfvars"

# View outputs
terraform output
```

### Deploy to Production

```bash
# Create and switch to production workspace
terraform workspace new prod

# Verify current workspace
terraform workspace show

# Deploy with production variables
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"

# View outputs
terraform output
```

## 🔍 How It Works

### Workspace-Aware Configuration

The `main.tf` file uses locals to define different configurations per workspace:

```hcl
locals {
  workspace_config = {
    default = {
      web_count        = 1
      web_machine_type = "e2-micro"
      # ...
    }
    dev = {
      web_count        = 2
      web_machine_type = "e2-micro"
      # ...
    }
    prod = {
      web_count        = 3
      web_machine_type = "e2-medium"
      # ...
    }
  }
  
  # Automatically selects config for current workspace
  config = local.workspace_config[terraform.workspace]
}
```

### Conditional Resources

The monitoring server only exists in production:

```hcl
resource "google_compute_instance" "monitoring" {
  count = terraform.workspace == "prod" ? 1 : 0
  # ...
}
```

### Workspace in Resource Names

Resources are named with the workspace prefix:

```hcl
resource "google_compute_instance" "web" {
  name = "${terraform.workspace}-web-${count.index + 1}"
  # Creates: dev-web-1, staging-web-1, prod-web-1, etc.
}
```

## 📊 Workspace Management

### Listing Workspaces

```bash
$ terraform workspace list
  default
  dev
  staging
* prod  # * indicates current workspace
```

### Switching Workspaces

```bash
# Switch to existing workspace
terraform workspace select dev

# Create and switch to new workspace
terraform workspace new qa
```

### Showing Current Workspace

```bash
$ terraform workspace show
prod
```

### Deleting Workspaces

```bash
# Switch away from the workspace first
terraform workspace select default

# Delete the workspace
terraform workspace delete qa
```

## 🧪 Experiments

### Experiment 1: Compare Environments

Deploy all three environments and compare their configurations:

```bash
# Deploy to dev
terraform workspace select default
terraform apply
terraform output deployment_summary

# Deploy to staging
terraform workspace select staging
terraform apply -var-file="staging.tfvars"
terraform output deployment_summary

# Deploy to prod
terraform workspace select prod
terraform apply -var-file="prod.tfvars"
terraform output deployment_summary

# Compare the outputs
```

**What to observe:**
- Different instance counts
- Different machine types
- Monitoring only in production
- Cost differences

### Experiment 2: Add a New Workspace

Create a QA workspace with custom configuration:

1. **Add QA config to locals:**

```hcl
# In main.tf locals block
qa = {
  web_count        = 2
  web_machine_type = "e2-small"
  web_disk_size    = 20
  app_count        = 2
  app_machine_type = "e2-medium"
  app_disk_size    = 30
}
```

2. **Create QA workspace:**

```bash
terraform workspace new qa
echo 'project_id = "my-qa-project-id"' > qa.tfvars
terraform apply -var-file="qa.tfvars"
```

**What to observe:**
- New workspace created seamlessly
- Separate state file
- Independent deployment

### Experiment 3: Modify Production Without Affecting Dev

Make changes only to production:

```bash
# Edit locals in main.tf to change prod config
# For example, increase web_count from 3 to 4

# Switch to prod
terraform workspace select prod

# Apply changes
terraform apply -var-file="prod.tfvars"

# Verify dev is unaffected
terraform workspace select default
terraform state list  # Shows dev resources unchanged
```

**What to observe:**
- Changes isolated to production
- Dev environment unaffected
- Separate state files provide isolation

### Experiment 4: Workspace Interpolation

See how workspace name is used:

```bash
# In each workspace, check the outputs
terraform workspace select default
terraform output workspace

terraform workspace select staging
terraform output workspace

terraform workspace select prod
terraform output workspace
```

**What to observe:**
- `terraform.workspace` reflects current workspace
- Used in resource names, labels, conditionals

### Experiment 5: Cost Comparison

Compare costs across environments:

```bash
# Check cost for each workspace
for ws in default staging prod; do
  echo "=== $ws workspace ==="
  terraform workspace select $ws
  terraform output estimated_monthly_cost
done
```

**What to observe:**
- Dev: ~$52/month (small instances)
- Staging: ~$106/month (medium instances)
- Prod: ~$315/month (larger instances + monitoring)

## 💡 Key Concepts Demonstrated

### 1. State File Isolation

Each workspace has its own state file:

```bash
# View state files in GCS backend (if configured)
gsutil ls gs://my-terraform-state/

# Shows:
# default.tfstate
# env:/dev/default.tfstate
# env:/staging/default.tfstate
# env:/prod/default.tfstate
```

### 2. Environment-Specific Variables

Use different `.tfvars` files per workspace:

```bash
# Dev (default workspace)
terraform apply -var-file="terraform.tfvars"

# Staging
terraform apply -var-file="staging.tfvars"

# Production
terraform apply -var-file="prod.tfvars"
```

### 3. Conditional Resource Creation

Resources can be conditionally created:

```hcl
# Only in production
count = terraform.workspace == "prod" ? 1 : 0

# Not in default/dev
count = terraform.workspace != "default" ? 1 : 0

# Only in specific workspaces
count = contains(["staging", "prod"], terraform.workspace) ? 1 : 0
```

### 4. Dynamic Configuration

Configuration adapts to workspace:

```hcl
locals {
  config = local.workspace_config[terraform.workspace]
}

resource "google_compute_instance" "web" {
  count        = local.config.web_count
  machine_type = local.config.web_machine_type
  # ...
}
```

### 5. Workspace in Labels and Tags

Track which workspace created resources:

```hcl
labels = {
  environment = terraform.workspace
  managed_by  = "terraform"
}
```

## 🎓 What You've Learned

After completing this example, you now understand:

1. ✅ **Workspace fundamentals** - Create, switch, and manage workspaces
2. ✅ **Workspace-aware configuration** - Adapt resources based on workspace
3. ✅ **Variable files per workspace** - Environment-specific values
4. ✅ **Conditional resources** - Resources in specific workspaces only
5. ✅ **State isolation** - Independent state files per workspace
6. ✅ **Workspace interpolation** - Use `terraform.workspace` in configuration

## ⚠️ Workspace Limitations

While this example works well, be aware of workspace limitations:

### Limitation 1: Configuration Coupling

All environments share the same configuration code. If environments diverge significantly, workspaces become unwieldy.

**Solution:** Use directory structure (next example).

### Limitation 2: Workspace Visibility

Workspace names aren't visible in GCP console unless you use labels/naming conventions.

**Solution:** Always include workspace in resource names and labels.

### Limitation 3: Team Collaboration

Multiple people can't easily work on different workspaces simultaneously with the same backend.

**Solution:** Use separate directories with separate backends.

## 🧹 Cleanup

Clean up resources in each workspace:

```bash
# Destroy production
terraform workspace select prod
terraform destroy -var-file="prod.tfvars"

# Destroy staging  
terraform workspace select staging
terraform destroy -var-file="staging.tfvars"

# Destroy dev
terraform workspace select default
terraform destroy

# Delete workspaces (optional)
terraform workspace select default
terraform workspace delete staging
terraform workspace delete prod
```

## 📚 Best Practices from This Example

1. **Use consistent variable files** - Create `.tfvars` for each workspace
2. **Include workspace in names** - Makes resources identifiable
3. **Add workspace labels** - Track which workspace created resources
4. **Define configurations in locals** - Centralized environment settings
5. **Document workspace usage** - Clear instructions for team members

## 🔄 Real-World Usage

This pattern works well for:

- **Small to medium projects** - Manageable number of resources
- **Similar environments** - Dev, staging, and prod are mostly identical
- **Quick provisioning** - Need to spin up/down environments frequently
- **Learning and experimentation** - Easy to test different configurations

## 🎯 Next Steps

1. **Try all experiments** to understand workspace behavior
2. **Add a new workspace** for testing or QA
3. **Modify configurations** to see how changes propagate
4. **Compare with directory structure** approach (next example)
5. **Decide which approach fits your needs** better

## 📖 Related Examples

- [directory-structure/](../directory-structure/) - Alternative approach for complex environments
- [remote-state/](../remote-state/) - Sharing data between configurations
- [complete/](../complete/) - Production multi-environment architecture

## 💡 Tips and Tricks

### Tip 1: Alias for Common Commands

```bash
# Add to ~/.bashrc or ~/.zshrc
alias tfws='terraform workspace show'
alias tfwl='terraform workspace list'
alias tfws-dev='terraform workspace select default && terraform apply'
alias tfws-prod='terraform workspace select prod && terraform apply -var-file="prod.tfvars"'
```

### Tip 2: Validate Workspace

Add validation to prevent mistakes:

```hcl
locals {
  allowed_workspaces = ["default", "dev", "staging", "prod"]
  is_valid_workspace = contains(local.allowed_workspaces, terraform.workspace)
}

# This will fail if workspace is invalid
check "valid_workspace" {
  assert {
    condition     = local.is_valid_workspace
    error_message = "Workspace '${terraform.workspace}' is not allowed. Use: ${join(", ", local.allowed_workspaces)}"
  }
}
```

### Tip 3: Environment Promotion Script

```bash
#!/bin/bash
# promote.sh - Promote changes through environments

set -e

echo "Deploying to dev..."
terraform workspace select default
terraform apply -auto-approve

echo "Waiting 1 hour for testing..."
sleep 3600

echo "Deploying to staging..."
terraform workspace select staging
terraform apply -var-file="staging.tfvars" -auto-approve

echo "Waiting 24 hours for validation..."
sleep 86400

echo "Ready to deploy to production!"
echo "Run: terraform workspace select prod && terraform apply -var-file='prod.tfvars'"
```

---

**Time to Complete:** 1-2 hours

**Difficulty:** Beginner to Intermediate

**Prerequisites:** Understanding of Terraform basics and modules

