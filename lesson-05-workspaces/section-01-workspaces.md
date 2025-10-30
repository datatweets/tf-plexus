# Lesson Five | Section 1: Managing Environments with Workspaces

In this section, you'll learn how to manage multiple environments (dev, staging, production) using Terraform workspaces. Workspaces let you maintain separate state files for the same configuration, enabling you to deploy identical infrastructure across different environments.

## Learning Objectives

By the end of this section, you will:

- Understand what Terraform workspaces are and how they work
- Know when to use workspaces vs other approaches
- Create and switch between workspaces
- Use workspace-specific variable files
- Implement environment-aware configurations
- Understand workspace limitations and best practices

## Prerequisites

- Completed Lessons 1-4
- Understanding of Terraform state
- Familiarity with modules and variables
- Two GCP projects (dev and prod)

## What Are Workspaces?

**Workspaces** are a Terraform feature that allows you to maintain multiple independent state files for a single configuration. Each workspace has its own state file, enabling you to deploy the same infrastructure configuration to different environments.

### The Problem: Managing Multiple Environments

Without workspaces, managing multiple environments requires either:

1. **Duplicating code** - Copy the entire configuration for each environment
2. **Complex conditionals** - Use variables to change behavior everywhere
3. **Manual state management** - Switch backend configurations manually

All of these approaches are error-prone and hard to maintain.

### The Solution: Workspaces

Workspaces provide a cleaner approach:

```bash
# One configuration, multiple state files
terraform/
├── main.tf          # Single configuration
├── variables.tf
├── terraform.tfvars # Default values
├── dev.tfvars       # Dev overrides
└── prod.tfvars      # Prod overrides

# Separate state files managed automatically
terraform.tfstate.d/
├── default/       # Default workspace
├── dev/           # Dev workspace
└── prod/          # Prod workspace
```

## How Workspaces Work

### Workspace Commands

```bash
# List all workspaces (* indicates current)
terraform workspace list

# Create and switch to new workspace
terraform workspace new dev

# Switch to existing workspace
terraform workspace select dev

# Show current workspace
terraform workspace show

# Delete a workspace (must not be current)
terraform workspace delete staging
```

### Workspace Interpolation

Access the current workspace name in your configuration:

```hcl
# Reference current workspace
resource "google_compute_instance" "vm" {
  name = "${terraform.workspace}-server"
  
  labels = {
    environment = terraform.workspace
  }
}
```

### State File Organization

When using remote backends (like GCS), Terraform automatically organizes state files:

```
bucket/
└── terraform/state/
    ├── default.tfstate        # Default workspace
    ├── env:/dev/default.tfstate   # Dev workspace
    └── env:/prod/default.tfstate  # Prod workspace
```

## Basic Workspace Example

Let's build a simple example that deploys servers to different environments:

### Step 1: Create Configuration

**main.tf**

```hcl
resource "google_compute_instance" "server" {
  count = var.instance_count

  name         = "${var.environment}-server-${count.index + 1}"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  labels = {
    environment = var.environment
    workspace   = terraform.workspace
  }
}
```

**variables.tf**

```hcl
variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

variable "instance_count" {
  type        = number
  description = "Number of instances"
  default     = 1
}

variable "machine_type" {
  type        = string
  description = "Machine type"
  default     = "e2-micro"
}

variable "zone" {
  type        = string
  default     = "us-west1-a"
}
```

### Step 2: Create Environment-Specific Variable Files

**terraform.tfvars** (default - dev)

```hcl
project_id     = "my-dev-project"
environment    = "dev"
instance_count = 2
machine_type   = "e2-micro"
```

**prod.tfvars**

```hcl
project_id     = "my-prod-project"
environment    = "production"
instance_count = 3
machine_type   = "e2-medium"
```

### Step 3: Deploy to Multiple Environments

```bash
# Initialize
terraform init

# Deploy to dev (default workspace)
terraform apply

# Create production workspace
terraform workspace new prod

# Deploy to production
terraform apply -var-file="prod.tfvars"

# Verify both deployments
terraform workspace select default
terraform state list

terraform workspace select prod
terraform state list
```

## Environment-Aware Configuration

You can make your configuration adapt based on the workspace:

```hcl
locals {
  # Workspace-specific configurations
  workspace_config = {
    default = {
      instance_count = 1
      machine_type   = "e2-micro"
      disk_size      = 10
    }
    dev = {
      instance_count = 2
      machine_type   = "e2-small"
      disk_size      = 20
    }
    staging = {
      instance_count = 2
      machine_type   = "e2-medium"
      disk_size      = 50
    }
    prod = {
      instance_count = 3
      machine_type   = "e2-standard-2"
      disk_size      = 100
    }
  }
  
  # Select configuration for current workspace
  config = local.workspace_config[terraform.workspace]
}

resource "google_compute_instance" "server" {
  count = local.config.instance_count
  
  name         = "${terraform.workspace}-server-${count.index + 1}"
  machine_type = local.config.machine_type
  zone         = var.zone
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = local.config.disk_size
    }
  }
  
  # ... rest of configuration
}
```

## Workspaces with Remote Backend

Configure backend to use workspaces with GCS:

**backend.tf**

```hcl
terraform {
  backend "gcs" {
    bucket = "my-terraform-state"
    prefix = "environments"
    
    # Terraform automatically adds workspace name to path
    # Results in: environments/env:/dev/default.tfstate
  }
}
```

When you create workspaces, Terraform manages the state file paths automatically:

```bash
# Creates: bucket/environments/default.tfstate
terraform workspace select default

# Creates: bucket/environments/env:/dev/default.tfstate
terraform workspace select dev

# Creates: bucket/environments/env:/prod/default.tfstate
terraform workspace select prod
```

## Conditional Resource Creation

Create resources only in specific workspaces:

```hcl
# Only create monitoring in production
resource "google_compute_instance" "monitoring" {
  count = terraform.workspace == "prod" ? 1 : 0
  
  name         = "monitoring-server"
  machine_type = "e2-medium"
  zone         = var.zone
  # ...
}

# Different backup schedules per environment
resource "google_compute_resource_policy" "backup" {
  name   = "${terraform.workspace}-backup-policy"
  region = var.region
  
  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = terraform.workspace == "prod" ? "02:00" : "04:00"
      }
    }
    
    retention_policy {
      max_retention_days = terraform.workspace == "prod" ? 30 : 7
    }
  }
}
```

## Workspace Best Practices

### ✅ DO: Use Workspaces When

1. **Environments are nearly identical** - Same resources, different values
2. **Quick testing** - Need temporary environments
3. **Small teams** - Few people managing infrastructure
4. **Simple architectures** - Limited number of resources

### ❌ DON'T: Use Workspaces When

1. **Environments differ significantly** - Different resources or topology
2. **Large teams** - Multiple people working simultaneously
3. **Complex architectures** - Many interconnected resources
4. **Need separate approval workflows** - Different review processes per environment

### Best Practices

1. **Always use variable files per workspace**

```bash
# Good
terraform apply -var-file="${terraform.workspace}.tfvars"

# Bad
terraform apply -var="project_id=..."
```

2. **Validate workspace before applying**

```hcl
# Add to variables.tf
variable "allowed_workspaces" {
  type    = list(string)
  default = ["default", "dev", "staging", "prod"]
}

# Add to main.tf
locals {
  # Validate workspace
  validate_workspace = contains(var.allowed_workspaces, terraform.workspace)
}

# This will fail if workspace is not in allowed list
resource "null_resource" "workspace_validation" {
  count = local.validate_workspace ? 0 : 1
  
  provisioner "local-exec" {
    command = "echo 'ERROR: Invalid workspace ${terraform.workspace}' && exit 1"
  }
}
```

3. **Use consistent naming conventions**

```hcl
# Good - workspace in names
name = "${terraform.workspace}-${var.name}"

# Better - clear environment labels
labels = {
  environment = terraform.workspace
  managed_by  = "terraform"
}
```

4. **Document workspace usage**

```bash
# Create README.md with instructions
cat > README.md <<'EOF'
# Workspace Usage

## Available Workspaces
- default: Development environment
- dev: Dedicated dev environment
- staging: Pre-production testing
- prod: Production environment

## Deploying to Environment
```bash
terraform workspace select <workspace>
terraform apply -var-file="<workspace>.tfvars"
```

EOF

```
## Workspace Limitations

### Limitation 1: Cannot Have Different Resource Counts

**Problem:**
```hcl
# Can't easily have 2 servers in dev, 3 in prod
resource "google_compute_instance" "server" {
  count = 2  # This is the same for all workspaces
  # ...
}
```

**Solution:**

```hcl
# Use locals and workspace detection
locals {
  instance_counts = {
    default = 1
    dev     = 2
    staging = 2
    prod    = 3
  }
}

resource "google_compute_instance" "server" {
  count = local.instance_counts[terraform.workspace]
  # ...
}
```

### Limitation 2: Cannot Have Different Resource Types

**Problem:**

```hcl
# Can't have CloudSQL in prod but not in dev
# Would need complex conditionals
resource "google_sql_database_instance" "db" {
  count = terraform.workspace == "prod" ? 1 : 0
  # Gets messy with many resources
}
```

**Solution:** Use directory structure (covered in Section 2)

### Limitation 3: Workspace Names Not Visible in Console

When viewing resources in GCP console, workspace names aren't obvious unless you use labels:

```hcl
# Always add workspace label
labels = {
  environment = terraform.workspace
  managed_by  = "terraform"
}

# Include workspace in names
name = "${terraform.workspace}-${var.resource_name}"
```

## Migration from Non-Workspace Setup

If you have existing infrastructure without workspaces:

### Step 1: Create Workspace for Existing State

```bash
# Your current state is in "default" workspace
terraform workspace show  # Shows "default"

# Create dev workspace for existing dev environment
terraform workspace new dev

# Import existing state or rename default
mv terraform.tfstate terraform.tfstate.d/dev/terraform.tfstate
```

### Step 2: Create New Workspaces for Other Environments

```bash
# Create production workspace
terraform workspace new prod

# Deploy to production
terraform apply -var-file="prod.tfvars"
```

## Workspace Workflows

### Daily Development Workflow

```bash
# Start of day - verify workspace
terraform workspace show

# Make changes to code
# ...

# Test in dev
terraform workspace select dev
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"

# Once tested, promote to staging
terraform workspace select staging
terraform apply -var-file="staging.tfvars"

# After approval, deploy to production
terraform workspace select prod
terraform plan -var-file="prod.tfvars"
# Review plan carefully!
terraform apply -var-file="prod.tfvars"
```

### Emergency Hotfix Workflow

```bash
# Quick fix needed in production
terraform workspace select prod

# Make emergency change
terraform apply -var-file="prod.tfvars"

# Backport to other environments
terraform workspace select staging
terraform apply -var-file="staging.tfvars"

terraform workspace select dev
terraform apply -var-file="dev.tfvars"
```

## Testing Your Understanding

Try these exercises:

### Exercise 1: Create Three Workspaces

Create dev, staging, and prod workspaces with different configurations:

- Dev: 1 e2-micro instance
- Staging: 2 e2-small instances
- Prod: 3 e2-medium instances

### Exercise 2: Conditional Resources

Create a monitoring instance that only exists in production.

### Exercise 3: Environment-Aware Configuration

Implement different backup retention policies:

- Dev: 7 days
- Staging: 14 days
- Prod: 30 days

## Summary

**Workspaces are ideal for:**

- ✅ Nearly identical environments
- ✅ Small teams
- ✅ Simple architectures
- ✅ Quick environment provisioning

**Key Takeaways:**

1. Each workspace has independent state
2. Use `terraform.workspace` to reference current workspace
3. Combine workspaces with `.tfvars` files for configuration
4. Works well with GCP projects for environment separation
5. Has limitations for complex, divergent environments

## Next Steps

In Section 2, you'll learn about using directory structure for environment management, which provides more flexibility for complex scenarios where environments differ significantly.