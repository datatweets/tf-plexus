# Lesson Five | Section 2: Managing Environments with Directory Structure

In this section, you'll learn how to manage multiple environments using a directory-based approach. This method provides maximum flexibility for environments that have different configurations, topologies, or resource counts.

## Learning Objectives

By the end of this section, you will:

- Understand when to use directory structure vs workspaces
- Organize Terraform code into environment-specific directories
- Use modules effectively with directory structure
- Share data between configurations using remote state
- Implement layered architecture patterns
- Manage complex multi-environment deployments

## Prerequisites

- Completed Section 1 (Workspaces)
- Understanding of Terraform modules
- Familiarity with Terraform state
- Two or more GCP projects

## The Directory Structure Approach

### When Workspaces Aren't Enough

Workspaces work well for nearly identical environments, but real-world scenarios often require:

- **Different resource counts** - 2 servers in dev, 5 in production
- **Different resource types** - CloudSQL only in production
- **Different topologies** - Simple network in dev, complex VPC in production
- **Different teams** - Separate ownership and approval workflows
- **Independent lifecycles** - Deploy dev frequently, production rarely

For these scenarios, **directory structure** is the better choice.

## Basic Directory Structure

The fundamental pattern separates each environment into its own directory:

```
terraform/
├── dev/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── backend.tf
│   └── terraform.tfvars
├── staging/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── backend.tf
│   └── terraform.tfvars
├── prod/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── backend.tf
│   └── terraform.tfvars
└── modules/
    ├── compute/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── networking/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── database/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

### Key Characteristics

1. **Independent Directories** - Each environment is self-contained
2. **Separate State Files** - Each directory has its own state
3. **Shared Modules** - DRY principle through module reuse
4. **Environment-Specific Configuration** - Different main.tf for each environment

## Simple Example: Different Server Counts

Let's create a basic example where dev has 2 servers and prod has 3.

### Step 1: Create Module

**modules/server/main.tf**
```hcl
resource "google_compute_instance" "server" {
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = var.disk_size_gb
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  labels = {
    environment = var.environment
    tier        = var.tier
  }
}
```

**modules/server/variables.tf**
```hcl
variable "name" {
  type        = string
  description = "Server name"
}

variable "machine_type" {
  type        = string
  description = "Machine type"
  default     = "e2-micro"
}

variable "disk_size_gb" {
  type        = number
  description = "Boot disk size in GB"
  default     = 20
}

variable "zone" {
  type        = string
  description = "GCP zone"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "tier" {
  type        = string
  description = "Application tier"
  default     = "general"
}
```

**modules/server/outputs.tf**
```hcl
output "id" {
  value       = google_compute_instance.server.id
  description = "Server instance ID"
}

output "name" {
  value       = google_compute_instance.server.name
  description = "Server instance name"
}

output "internal_ip" {
  value       = google_compute_instance.server.network_interface[0].network_ip
  description = "Internal IP address"
}

output "external_ip" {
  value       = google_compute_instance.server.network_interface[0].access_config[0].nat_ip
  description = "External IP address"
}
```

### Step 2: Create Dev Environment (2 servers)

**dev/main.tf**
```hcl
module "web_server" {
  source = "../modules/server"

  name         = "dev-web-server"
  machine_type = "e2-micro"
  disk_size_gb = 10
  zone         = var.zone
  environment  = "dev"
  tier         = "web"
}

module "app_server" {
  source = "../modules/server"

  name         = "dev-app-server"
  machine_type = "e2-small"
  disk_size_gb = 20
  zone         = var.zone
  environment  = "dev"
  tier         = "app"
}
```

**dev/variables.tf**
```hcl
variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
  default     = "us-west1"
}

variable "zone" {
  type        = string
  description = "GCP zone"
  default     = "us-west1-a"
}
```

**dev/outputs.tf**
```hcl
output "web_server" {
  value = {
    name        = module.web_server.name
    internal_ip = module.web_server.internal_ip
    external_ip = module.web_server.external_ip
  }
}

output "app_server" {
  value = {
    name        = module.app_server.name
    internal_ip = module.app_server.internal_ip
    external_ip = module.app_server.external_ip
  }
}
```

**dev/terraform.tfvars**
```hcl
project_id = "my-dev-project"
region     = "us-west1"
zone       = "us-west1-a"
```

### Step 3: Create Prod Environment (3 servers + database)

**prod/main.tf**
```hcl
module "web_server_1" {
  source = "../modules/server"

  name         = "prod-web-server-1"
  machine_type = "e2-medium"
  disk_size_gb = 50
  zone         = var.zone
  environment  = "production"
  tier         = "web"
}

module "web_server_2" {
  source = "../modules/server"

  name         = "prod-web-server-2"
  machine_type = "e2-medium"
  disk_size_gb = 50
  zone         = var.zone
  environment  = "production"
  tier         = "web"
}

module "app_server" {
  source = "../modules/server"

  name         = "prod-app-server"
  machine_type = "e2-standard-2"
  disk_size_gb = 100
  zone         = var.zone
  environment  = "production"
  tier         = "app"
}

# Database only in production
resource "google_sql_database_instance" "main" {
  name             = "prod-db-instance"
  database_version = "POSTGRES_14"
  region           = var.region

  settings {
    tier = "db-f1-micro"
    
    backup_configuration {
      enabled    = true
      start_time = "02:00"
    }
  }

  deletion_protection = true
}
```

**prod/terraform.tfvars**
```hcl
project_id = "my-prod-project"
region     = "us-west1"
zone       = "us-west1-a"
```

### Step 4: Deploy Environments Independently

```bash
# Deploy development
cd dev
terraform init
terraform apply

# Deploy production
cd ../prod
terraform init
terraform apply

# Each can be managed independently
```

## Advantages of Directory Structure

### 1. Complete Flexibility

Each environment can be completely different:

```hcl
# dev/main.tf - Simple setup
module "single_server" {
  source = "../modules/server"
  # ...
}

# prod/main.tf - Complex setup
module "web_tier" { }
module "app_tier" { }
module "db_tier" { }
module "cache_tier" { }
module "monitoring" { }
```

### 2. Independent State Files

```
terraform-state/
├── dev-state/
│   └── default.tfstate
├── staging-state/
│   └── default.tfstate
└── prod-state/
    └── default.tfstate
```

Each environment's backend configuration points to its own state location.

### 3. Separate Ownership

Different teams can own different environments:

```
dev/        # Owned by development team
staging/    # Owned by QA team
prod/       # Owned by operations team
```

### 4. Different Provider Versions

Each environment can use different provider versions:

```hcl
# dev/provider.tf - Using latest
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# prod/provider.tf - Pinned to stable version
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "= 4.84.0"  # Tested and stable
    }
  }
}
```

### 5. Independent Deployment Cadence

```bash
# Dev - Deploy multiple times per day
cd dev && terraform apply -auto-approve

# Staging - Deploy daily
cd staging && terraform apply

# Production - Deploy weekly with approval
cd prod && terraform plan -out=prod.tfplan
# Review plan, get approval
cd prod && terraform apply prod.tfplan
```

## Advanced Pattern: Layered Architecture

For complex environments, separate infrastructure into logical layers:

```
terraform/
├── layers/
│   ├── 01-networking/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   ├── 02-security/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   ├── 03-data/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   └── 04-compute/
│       ├── dev/
│       ├── staging/
│       └── prod/
└── modules/
    ├── vpc/
    ├── security/
    ├── database/
    └── compute/
```

### Layer Dependencies

```
01-networking (VPC, subnets)
    ↓
02-security (Firewall rules, IAM)
    ↓
03-data (CloudSQL, Storage)
    ↓
04-compute (VMs, GKE)
```

Each layer outputs data that the next layer consumes via remote state (covered in next section).

## Sharing Configuration Across Environments

### Pattern 1: Shared Variable Defaults

Create a shared variables file:

**shared/common-variables.tf**
```hcl
variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
  default     = "us-west1"
}

variable "zone" {
  type        = string
  description = "GCP zone"
  default     = "us-west1-a"
}

variable "common_labels" {
  type = map(string)
  default = {
    managed_by = "terraform"
    team       = "platform"
  }
}
```

Copy or symlink to each environment directory.

### Pattern 2: Shared Locals

**shared/common-locals.tf**
```hcl
locals {
  # Machine type mappings
  machine_types = {
    small  = "e2-micro"
    medium = "e2-small"
    large  = "e2-medium"
    xlarge = "e2-standard-2"
  }

  # Common tags
  tags = merge(
    var.common_labels,
    {
      environment = var.environment
    }
  )
}
```

### Pattern 3: Environment-Specific Overrides

Use locals to define environment-specific values:

```hcl
# dev/main.tf
locals {
  config = {
    instance_count     = 2
    machine_type       = "e2-micro"
    enable_backups     = false
    backup_retention   = 7
    enable_monitoring  = false
    enable_autoscaling = false
  }
}

# prod/main.tf
locals {
  config = {
    instance_count     = 5
    machine_type       = "e2-standard-2"
    enable_backups     = true
    backup_retention   = 30
    enable_monitoring  = true
    enable_autoscaling = true
  }
}
```

## Directory Structure Best Practices

### 1. Consistent Structure

Keep the same file organization in each environment:

```
dev/
├── main.tf          # Module calls
├── variables.tf     # Variable definitions
├── outputs.tf       # Output values
├── provider.tf      # Provider configuration
├── backend.tf       # State backend
├── terraform.tfvars # Variable values
└── README.md        # Environment documentation

# Same structure in staging/ and prod/
```

### 2. Use Relative Module Paths

```hcl
# Good - Relative path
module "server" {
  source = "../modules/server"
}

# Avoid - Absolute path
module "server" {
  source = "/Users/me/terraform/modules/server"
}
```

### 3. Environment-Specific Backend Configuration

```hcl
# dev/backend.tf
terraform {
  backend "gcs" {
    bucket = "my-terraform-state"
    prefix = "environments/dev"
  }
}

# prod/backend.tf
terraform {
  backend "gcs" {
    bucket = "my-terraform-state-prod"  # Separate bucket
    prefix = "environments/prod"
  }
}
```

### 4. Document Each Environment

```markdown
# dev/README.md

## Development Environment

**Purpose:** Development and testing

**GCP Project:** `my-dev-project`

**Deployment Frequency:** Multiple times daily

**Resources:**
- 2 compute instances (e2-micro)
- No CloudSQL
- No backups

## Deploying

```bash
cd dev
terraform init
terraform plan
terraform apply
```

## Destroying

```bash
terraform destroy
```
```

### 5. Use Makefiles for Consistency

**Makefile**
```makefile
.PHONY: init plan apply destroy

ENVIRONMENT ?= dev

init:
	cd $(ENVIRONMENT) && terraform init

plan:
	cd $(ENVIRONMENT) && terraform plan

apply:
	cd $(ENVIRONMENT) && terraform apply

destroy:
	cd $(ENVIRONMENT) && terraform destroy

# Usage:
# make init ENVIRONMENT=dev
# make plan ENVIRONMENT=prod
# make apply ENVIRONMENT=staging
```

## Migration from Workspaces to Directory Structure

If you're currently using workspaces:

### Step 1: Create Directory Structure

```bash
mkdir -p {dev,staging,prod}/
mkdir -p modules/
```

### Step 2: Copy Configuration

```bash
# Copy files to each environment
for env in dev staging prod; do
  cp main.tf variables.tf outputs.tf provider.tf $env/
done
```

### Step 3: Extract State

```bash
# For each workspace
terraform workspace select dev
terraform state pull > dev/terraform.tfstate

terraform workspace select prod
terraform state pull > prod/terraform.tfstate
```

### Step 4: Configure Backends

```bash
# Update backend configuration in each environment
# Then push state to new backend
cd dev
terraform init -migrate-state
```

## Comparison: Workspaces vs Directory Structure

| Aspect | Workspaces | Directory Structure |
|--------|-----------|---------------------|
| **Setup Complexity** | Simple | Moderate |
| **Flexibility** | Limited | High |
| **Code Duplication** | Minimal | Some (mitigated by modules) |
| **State Management** | Single location | Multiple locations |
| **Team Collaboration** | Harder | Easier |
| **Environment Differences** | Must be similar | Can be completely different |
| **Deployment Independence** | Limited | Full |
| **Best For** | Small projects | Production use |

## When to Use Each Approach

### Use Workspaces When:
- ✅ Environments are nearly identical
- ✅ Small team (1-3 people)
- ✅ Simple infrastructure
- ✅ Quick prototyping
- ✅ Learning Terraform

### Use Directory Structure When:
- ✅ Environments differ significantly
- ✅ Large teams
- ✅ Complex infrastructure
- ✅ Production deployments
- ✅ Need separate approval workflows
- ✅ Different deployment schedules
- ✅ Regulatory requirements (separate state files)

## Common Patterns

### Pattern 1: Environment Promotion

```bash
# Test in dev
cd dev && terraform apply

# Promote to staging
cd ../staging && terraform apply

# After approval, promote to prod
cd ../prod && terraform plan -out=prod.tfplan
# Review and approve
cd ../prod && terraform apply prod.tfplan
```

### Pattern 2: Gradual Rollout

```bash
# Deploy new feature to dev
cd dev && terraform apply

# Wait and monitor
sleep 86400  # 1 day

# If stable, deploy to staging
cd ../staging && terraform apply

# Wait and monitor
sleep 604800  # 1 week

# If stable, deploy to prod
cd ../prod && terraform apply
```

### Pattern 3: Hotfix

```bash
# Emergency fix in prod
cd prod && terraform apply

# Backport to other environments
cd ../staging && terraform apply
cd ../dev && terraform apply
```

## Testing Your Understanding

Try these exercises:

### Exercise 1: Create Multi-Environment Setup

Create dev, staging, and prod directories with:
- Dev: 1 small server
- Staging: 2 medium servers
- Prod: 3 large servers + CloudSQL

### Exercise 2: Environment-Specific Features

Implement features that only exist in certain environments:
- Monitoring: Only in staging and prod
- Backups: Only in prod
- Auto-scaling: Only in prod

### Exercise 3: Layered Architecture

Create a layered structure:
1. Networking layer (VPC, subnets)
2. Security layer (Firewall rules)
3. Application layer (Compute instances)

## Summary

**Directory structure is the recommended approach for:**
- ✅ Production deployments
- ✅ Complex infrastructure
- ✅ Large teams
- ✅ Environments with significant differences

**Key Takeaways:**
1. Each environment is a separate directory
2. Modules enable code reuse (DRY principle)
3. Independent state files provide isolation
4. Full flexibility in environment configuration
5. Better suited for team collaboration

## Next Steps

In the practical examples, you'll implement:
1. **workspaces/** - Hands-on with workspaces
2. **directory-structure/** - Building multi-environment setup
3. **remote-state/** - Sharing data between layers
4. **complete/** - Production multi-environment architecture
