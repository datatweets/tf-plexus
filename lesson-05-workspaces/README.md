# Lesson 5: Managing Multiple Environments with Terraform

Learn how to manage multiple environments (dev, staging, production) using Terraform through workspaces, directory structures, remote state, and layered architectures.

## 🎯 Learning Objectives

By completing this lesson, you will master:

1. **Terraform Workspaces** - Multiple states for one configuration
2. **Directory Structure** - Separate directories per environment
3. **Remote State** - Sharing data between Terraform configurations
4. **Layered Architecture** - Multi-layer infrastructure deployment
5. **Environment Best Practices** - Production-grade patterns

## 📚 Course Structure

### Tutorials

| Tutorial | Topics | Duration |
|----------|--------|----------|
| [01: Workspaces](./section-01-workspaces.md) | Workspace commands, environment-aware config, interpolation | 45 min |
| [02: Directory Structure](./section-02-directory-structure.md) | When to use, advantages, layered architecture, migration | 60 min |

### Practical Examples

| Example | Complexity | Key Concepts | Duration |
|---------|------------|--------------|----------|
| [workspaces](./workspaces/) | ⭐ Simple | Single config, multiple states | 1-2 hours |
| [directory-structure](./directory-structure/) | ⭐⭐ Medium | Separate configs, module reuse | 1-2 hours |
| [remote-state](./remote-state/) | ⭐⭐⭐ Advanced | terraform_remote_state, layers | 2-3 hours |
| [complete](./complete/) | ⭐⭐⭐⭐ Expert | Multi-layer production architecture | 3-4 hours |

## 🚀 Quick Start

### Prerequisites

- Terraform >= 1.9 installed
- GCP account with billing enabled
- GCS bucket for state storage
- Completed Lessons 1-4

### Recommended Learning Path

```
1. Read Tutorial 01: Workspaces
2. Complete workspaces/ example
3. Read Tutorial 02: Directory Structure
4. Complete directory-structure/ example
5. Complete remote-state/ example
6. Complete complete/ example (capstone)
```

## 🏗️ Example Architectures

### Workspaces Example

**Pattern:** Single configuration, multiple state files

```
workspaces/
├── main.tf          # Workspace-aware configuration
├── variables.tf
├── outputs.tf
└── terraform.tfvars

Deployment:
terraform workspace select dev   → Uses dev.tfvars
terraform workspace select prod  → Uses prod.tfvars
```

**Best for:** Nearly identical environments with minor differences

### Directory Structure Example

**Pattern:** Separate directories with shared modules

```
directory-structure/
├── modules/server/  # Shared module
├── dev/             # Dev environment
│   └── main.tf
└── prod/            # Prod environment
    └── main.tf

Deployment:
cd dev  && terraform apply
cd prod && terraform apply
```

**Best for:** Environments with significant differences

### Remote State Example

**Pattern:** Layered architecture with terraform_remote_state

```
remote-state/
└── layers/
    ├── 01-networking/  # Deploy first
    │   ├── dev/
    │   └── prod/
    └── 02-compute/     # Reads networking outputs
        ├── dev/
        └── prod/

Deployment:
cd layers/01-networking/dev && terraform apply
cd layers/02-compute/dev    && terraform apply
```

**Best for:** Shared infrastructure, team independence

### Complete Example

**Pattern:** Production multi-layer architecture

```
complete/
└── layers/
    ├── 01-networking/  # VPC, subnets, firewall
    ├── 02-data/        # Cloud SQL database
    ├── 03-compute/     # Web + app servers
    └── 04-storage/     # GCS buckets

Deployment: Layer by layer, dev then prod
```

**Best for:** Production deployments, large teams

## 📊 Comparison Matrix

| Aspect | Workspaces | Directory | Remote State | Complete |
|--------|------------|-----------|--------------|----------|
| **Complexity** | Low | Medium | Medium-High | High |
| **State Files** | 1 backend, multiple states | Multiple backends | Multiple backends | Multiple backends |
| **Configuration** | Shared | Separate | Separate (layered) | Separate (layered) |
| **Team Size** | 1-2 | 2-5 | 5-10 | 10+ |
| **Flexibility** | Low | High | High | Very High |
| **Use Case** | Dev/staging/prod (similar) | Different environments | Shared infra | Production |
| **Files Created** | 9 | 15 | 20 | 30+ |
| **Cost (Dev)** | $52/mo | $26/mo | $26/mo | $36/mo |
| **Cost (Prod)** | $315/mo | $385/mo | $220/mo | $295/mo |

## 🎓 Key Concepts

### 1. Workspaces

**What:** Multiple named state instances for the same configuration

**When to use:**
- Environments are nearly identical
- Small team (1-3 people)
- Simple deployment needs

**Advantages:**
- Simple to use
- Single configuration
- Less code duplication

**Limitations:**
- All environments must be similar
- Risk of accidental changes
- Workspace conflicts in teams

### 2. Directory Structure

**What:** Separate directories per environment with shared modules

**When to use:**
- Environments differ significantly
- Medium team (2-5 people)
- Independent deployment schedules

**Advantages:**
- Complete flexibility
- Clear separation
- No workspace confusion

**Limitations:**
- More files to manage
- Requires discipline
- Module versioning needed

### 3. Remote State

**What:** terraform_remote_state to share data between configurations

**When to use:**
- Layered infrastructure
- Different teams manage different layers
- Shared foundational resources

**Advantages:**
- Team independence
- Reduced blast radius
- Clear interfaces

**Limitations:**
- Added complexity
- Deployment order matters
- State dependencies

### 4. Layered Architecture

**What:** Infrastructure organized into logical layers

**Common layers:**
1. **Networking** - VPCs, subnets, firewalls
2. **Data** - Databases, caches
3. **Compute** - VMs, containers
4. **Storage** - Buckets, disks
5. **Monitoring** - Logging, alerting

**Benefits:**
- Clear ownership
- Independent deployment
- Reduced blast radius
- Better testing

## 📖 Tutorial Highlights

### Workspace Commands

```bash
terraform workspace list              # List workspaces
terraform workspace new dev           # Create workspace
terraform workspace select dev        # Switch workspace
terraform workspace show              # Current workspace
terraform workspace delete staging    # Delete workspace
```

### Workspace Interpolation

```hcl
locals {
  env_configs = {
    dev     = { size = "small",  count = 1 }
    staging = { size = "medium", count = 2 }
    prod    = { size = "large",  count = 3 }
  }
  
  config = local.env_configs[terraform.workspace]
}

resource "google_compute_instance" "server" {
  count        = local.config.count
  machine_type = "e2-${local.config.size}"
  # ...
}
```

### Remote State Data Source

```hcl
data "terraform_remote_state" "networking" {
  backend = "gcs"
  
  config = {
    bucket = "my-state-bucket"
    prefix = "networking/dev"
  }
}

# Use outputs from networking layer
module "server" {
  subnetwork = data.terraform_remote_state.networking.outputs.subnet_self_link
}
```

## 🧪 Hands-On Exercises

### Exercise 1: Workspace Practice

1. Create dev, staging, prod workspaces
2. Deploy different configurations per workspace
3. Compare state files
4. Switch between workspaces
5. Observe cost differences

### Exercise 2: Module Reuse

1. Extract common resources into a module
2. Use module in dev and prod
3. Pass different variables per environment
4. Update module, see propagation
5. Implement T-shirt sizing

### Exercise 3: Layer Dependencies

1. Deploy networking layer
2. Try deploying compute before networking (should fail)
3. Deploy compute layer
4. Modify networking, observe compute impact
5. Destroy in reverse order

### Exercise 4: Complete Deployment

1. Deploy all 4 layers in dev
2. Verify connections between layers
3. Test database connectivity
4. Upload files to storage bucket
5. Deploy to prod with different sizing

## 🎯 Best Practices

### Workspace Best Practices

- ✅ Use for simple environments
- ✅ Document workspace purposes
- ✅ Use workspace-specific tfvars
- ❌ Avoid for significantly different environments
- ❌ Don't mix workspace types

### Directory Best Practices

- ✅ Keep consistent structure across environments
- ✅ Use relative module paths
- ✅ Version control everything
- ✅ Use separate backends
- ✅ Tag resources with environment

### Remote State Best Practices

- ✅ Document layer dependencies
- ✅ Version output contracts
- ✅ Deploy in correct order
- ✅ Test each layer independently
- ❌ Don't remove outputs others depend on
- ❌ Avoid circular dependencies

### General Best Practices

- ✅ Start simple (workspaces), grow complexity as needed
- ✅ Use modules for code reuse
- ✅ Separate state files per environment
- ✅ Automate deployments
- ✅ Test in dev first
- ✅ Use consistent naming conventions
- ✅ Document everything
- ❌ Don't share tfvars files
- ❌ Don't store secrets in code
- ❌ Don't manually edit state files

## 🧹 Cleanup

Each example includes cleanup instructions. General pattern:

```bash
# Workspaces
terraform workspace select prod && terraform destroy
terraform workspace select dev && terraform destroy

# Directories
cd prod && terraform destroy
cd dev && terraform destroy

# Layered (reverse order!)
cd layers/04-storage/dev && terraform destroy
cd layers/03-compute/dev && terraform destroy
cd layers/02-data/dev && terraform destroy
cd layers/01-networking/dev && terraform destroy
```

## 📚 Learning Checklist

- [ ] Understand when to use workspaces vs directories
- [ ] Can create and switch between workspaces
- [ ] Can use terraform.workspace interpolation
- [ ] Understand module reuse patterns
- [ ] Can implement T-shirt sizing
- [ ] Understand terraform_remote_state
- [ ] Can design layered architecture
- [ ] Know deployment order for layers
- [ ] Can implement environment-specific configurations
- [ ] Understand state file organization
- [ ] Can estimate costs per environment
- [ ] Can migrate from workspaces to directories
- [ ] Understand production patterns

## 🚀 Next Steps

1. **Apply to your projects** - Choose the right pattern for your use case
2. **Implement CI/CD** - Automate environment deployments
3. **Add monitoring** - Create monitoring layer (layer 05)
4. **Security hardening** - Implement least privilege, secrets management
5. **Cost optimization** - Right-size resources, use spot instances
6. **Multi-region** - Extend to multiple regions
7. **Disaster recovery** - Implement backup and recovery procedures

## 📖 Additional Resources

- [Terraform Workspaces Documentation](https://www.terraform.io/docs/language/state/workspaces.html)
- [Remote State Data Source](https://www.terraform.io/docs/language/state/remote-state-data.html)
- [GCP Best Practices](https://cloud.google.com/docs/terraform/best-practices-for-terraform)
- [Infrastructure as Code Patterns](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

---

**Total Time:** 8-12 hours

**Difficulty:** Intermediate to Advanced

**Prerequisites:** Lessons 1-4 completed

**Best For:** Anyone deploying to multiple environments (dev, staging, production)
