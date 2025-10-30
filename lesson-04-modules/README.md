# Lesson 4: Terraform Modules - Reusable Infrastructure Components

Welcome to Lesson 4! In this lesson, you'll master Terraform modules - the key to writing reusable, maintainable, and scalable infrastructure code.

## 🎯 Learning Objectives

By the end of this lesson, you will be able to:

1. **Understand Module Fundamentals** - Root vs child modules, module structure, and organization
2. **Create Local Modules** - Build reusable custom modules for your infrastructure
3. **Use Registry Modules** - Leverage community-maintained modules from Terraform Registry
4. **Implement Advanced Patterns** - T-shirt sizing, validation, flexible configurations
5. **Design Multi-Module Architecture** - Compose multiple modules into complete systems
6. **Apply DRY Principles** - Eliminate code duplication and improve maintainability

## 📚 Course Structure

This lesson contains **2 tutorials** and **4 practical examples**:

### Tutorials (Read First)

| Tutorial | Time | Description |
|----------|------|-------------|
| [Module Basics](./section-01-module-basics.md) | 30 min | Introduction to modules, structure, and creating your first module |
| [Advanced Modules](./section-02-advanced-modules.md) | 30 min | T-shirt sizing, validation, locals, and registry usage |

### Practical Examples (Hands-On)

| Example | Difficulty | Time | Key Concepts |
|---------|-----------|------|--------------|
| [local-module](./local-module/) | Beginner | 1-2 hours | Basic local modules, module inputs/outputs, DRY principle |
| [flexible-module](./flexible-module/) | Intermediate | 2-3 hours | T-shirt sizing, validation, optional features, cost estimation |
| [registry-module](./registry-module/) | Intermediate | 1-2 hours | Using public registry modules, versioning, composition |
| [complete](./complete/) | Advanced | 2-3 hours | Multi-tier architecture, module dependencies, production patterns |

**Total Time:** 8-12 hours

## 🚀 Quick Start

### Prerequisites

Before starting this lesson, you should have:

- ✅ Completed [Lesson 1](../lesson-01/) - GCP Authentication
- ✅ Completed [Lesson 2](../lesson-02/) - Terraform Fundamentals
- ✅ Completed [Lesson 3](../lesson-03/) - Advanced Features
- ✅ Terraform >= 1.9 installed
- ✅ GCP account with billing enabled
- ✅ `gcloud` CLI authenticated

### Recommended Learning Path

```
1. Read: section-01-module-basics.md (30 min)
   ↓
2. Practice: local-module/ (1-2 hours)
   ↓
3. Read: section-02-advanced-modules.md (30 min)
   ↓
4. Practice: flexible-module/ (2-3 hours)
   ↓
5. Practice: registry-module/ (1-2 hours)
   ↓
6. Practice: complete/ (2-3 hours)
```

## 📦 What Are Modules?

**Modules are containers for multiple resources that are used together.** They're the primary way to organize, reuse, and share Terraform configuration.

### Without Modules (Problem)

```hcl
# main.tf - 500 lines of repetitive code

resource "google_compute_instance" "web1" {
  name         = "web-server-1"
  machine_type = "e2-medium"
  # ... 20 more lines
}

resource "google_compute_instance" "web2" {
  name         = "web-server-2"
  machine_type = "e2-medium"
  # ... same 20 lines copied
}

resource "google_compute_instance" "app1" {
  name         = "app-server-1"
  machine_type = "e2-medium"
  # ... same 20 lines copied again
}

# ... repeated 10+ times
```

❌ **Problems:**
- 80% code duplication
- Hard to maintain (change in 10 places)
- Error-prone (typos in copies)
- Not scalable

### With Modules (Solution)

```hcl
# main.tf - 30 lines, clean and maintainable

module "web_servers" {
  source = "./modules/compute-instance"
  
  count        = 2
  name_prefix  = "web"
  machine_type = "e2-medium"
}

module "app_servers" {
  source = "./modules/compute-instance"
  
  count        = 3
  name_prefix  = "app"
  machine_type = "e2-standard-2"
}
```

✅ **Benefits:**
- 80% less code
- Single source of truth
- Easy to maintain
- Highly scalable

## 🎓 Key Concepts

### 1. Root Module vs Child Module

**Root Module:**
- The main Terraform configuration
- Where you run `terraform apply`
- Calls child modules

**Child Module:**
- Reusable component
- Called by root module
- Lives in `./modules/` directory

```
project/
├── main.tf          # Root module
├── modules/
│   └── web-server/  # Child module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
```

### 2. Module Structure

Every module should have:

```
module-name/
├── main.tf         # Resource definitions
├── variables.tf    # Input variables
├── outputs.tf      # Output values
└── README.md       # Documentation
```

### 3. Module Sources

Modules can come from different sources:

**Local Path:**
```hcl
module "example" {
  source = "./modules/example"
}
```

**Terraform Registry:**
```hcl
module "network" {
  source  = "terraform-google-modules/network/google"
  version = "~> 9.0"
}
```

**Git Repository:**
```hcl
module "example" {
  source = "git::https://github.com/org/repo.git//modules/example"
}
```

### 4. Module Inputs and Outputs

**Inputs** (variables.tf):
```hcl
variable "instance_name" {
  type        = string
  description = "Name of the instance"
}
```

**Using inputs** (main.tf):
```hcl
resource "google_compute_instance" "vm" {
  name = var.instance_name
}
```

**Outputs** (outputs.tf):
```hcl
output "instance_ip" {
  value = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}
```

**Using outputs** (calling module):
```hcl
module "web" {
  source = "./modules/compute"
}

output "web_ip" {
  value = module.web.instance_ip
}
```

## 📋 Example Descriptions

### [local-module/](./local-module/) - Basic Module Usage

**What you'll build:**
- A reusable compute instance module
- Root module that uses the module 4 times
- Different configurations (web, app, workers)

**Key learnings:**
- Module structure (main.tf, variables.tf, outputs.tf)
- Passing variables to modules
- Using module outputs
- DRY principle in action

**Before/After:**
- Before: ~200 lines of repetitive code
- After: ~40 lines + reusable module
- **Code reduction: 80%**

### [flexible-module/](./flexible-module/) - Advanced Patterns

**What you'll build:**
- Module with T-shirt sizing (small/medium/large/xlarge)
- Extensive validation rules
- Optional features (backups, monitoring, data disks)
- Cost estimation

**Key learnings:**
- T-shirt sizing pattern
- Input validation
- Local values for complex logic
- Optional features with conditionals
- Cost calculations

**Configurations:**
- Small: $8/month
- Medium: $35/month
- Large: $150/month
- XLarge: $300/month

### [registry-module/](./registry-module/) - Public Modules

**What you'll build:**
- Infrastructure using 5 public registry modules
- VPC, compute, database, storage, load balancer
- Production-ready with minimal code

**Key learnings:**
- Finding modules in Terraform Registry
- Version constraints
- Module composition
- Submodules
- Registry module patterns

**Code reduction: 70%** vs writing raw resources

### [complete/](./complete/) - Production Architecture

**What you'll build:**
- Complete 3-tier web application
- 7 custom modules working together
- Network, web, app, database, load balancer, monitoring, storage
- Dev and production configurations

**Key learnings:**
- Multi-module architecture
- Module dependencies
- Inter-module communication
- Production patterns
- Environment-aware configuration
- Infrastructure composition

**Resources created:**
- 1 VPC with 4 subnets
- 2+ web servers
- 2+ app servers
- 1 database with backups
- 1 load balancer
- 3 storage buckets
- 1 monitoring server

## 🔑 Module Best Practices

### 1. Module Organization

```
✅ Good:
modules/
├── compute/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── networking/
└── storage/

❌ Bad:
modules/
├── module1.tf
├── module2.tf
└── all-in-one.tf
```

### 2. Variable Naming

```hcl
✅ Good:
variable "instance_count" { }
variable "machine_type" { }
variable "enable_backups" { }

❌ Bad:
variable "count" { }  # Too generic
variable "type" { }   # Unclear
variable "flag" { }   # Not descriptive
```

### 3. Documentation

```hcl
✅ Good:
variable "machine_type" {
  type        = string
  description = "GCE machine type (e.g., e2-medium, e2-standard-2)"
  default     = "e2-medium"
}

❌ Bad:
variable "machine_type" {
  # No description, no type
  default = "e2-medium"
}
```

### 4. Outputs

```hcl
✅ Good:
output "instance_ip" {
  value       = google_compute_instance.vm.network_interface[0].network_ip
  description = "Private IP address of the instance"
}

❌ Bad:
output "ip" {
  # No description, unclear which IP
  value = google_compute_instance.vm.network_interface[0].network_ip
}
```

### 5. Module Versioning

```hcl
✅ Good:
module "network" {
  source  = "terraform-google-modules/network/google"
  version = "~> 9.0"  # Pin to major version
}

❌ Bad:
module "network" {
  source = "terraform-google-modules/network/google"
  # No version - uses latest (risky)
}
```

## 🎯 Module Patterns

### Pattern 1: T-Shirt Sizing

Predefined configurations for common use cases:

```hcl
module "app" {
  source = "./modules/compute"
  
  size = "medium"  # Automatically sets machine_type, disk, etc.
}
```

**Use when:** Users want simplicity with the option to customize

### Pattern 2: Flexible Configuration

Allow presets OR custom configuration:

```hcl
module "app" {
  source = "./modules/compute"
  
  # Use preset
  size = "large"
  
  # OR override specific values
  machine_type = "e2-standard-4"
  disk_size_gb = 200
}
```

**Use when:** Need both simplicity and flexibility

### Pattern 3: Feature Flags

Optional features controlled by boolean flags:

```hcl
module "app" {
  source = "./modules/compute"
  
  enable_backups    = true
  enable_monitoring = true
  enable_data_disk  = false
}
```

**Use when:** Features are optional and independent

### Pattern 4: Module Composition

Combine multiple modules:

```hcl
module "networking" { }

module "compute" {
  network_id = module.networking.network_id
}

module "database" {
  network_id = module.networking.network_id
}
```

**Use when:** Building complex systems from smaller pieces

## 📊 Module Comparison

| Aspect | No Modules | Local Modules | Registry Modules |
|--------|-----------|---------------|------------------|
| **Code Reuse** | 0% | High | Very High |
| **Maintenance** | Hard | Moderate | Easy |
| **Learning Curve** | Low | Moderate | Low |
| **Customization** | Full | Full | Limited |
| **Community Support** | None | Team | Large |
| **Version Control** | Manual | Git | Registry |
| **Documentation** | Minimal | Team Docs | Extensive |
| **Best For** | Learning | Custom Infra | Standard Infra |

## 🛠️ Troubleshooting

### Issue: Module not found

```
Error: Module not found: ./modules/compute
```

**Solution:**
- Verify the path is correct
- Ensure the directory exists
- Check module files are present

### Issue: Variable not defined

```
Error: Variable not declared in module
```

**Solution:**
- Check `variables.tf` in the module
- Ensure variable is declared
- Match variable names exactly

### Issue: Cannot access module output

```
Error: Unsupported attribute
```

**Solution:**
- Check `outputs.tf` in the module
- Ensure output is declared
- Use `module.name.output_name` syntax

### Issue: Module version conflict

```
Error: Module version constraints
```

**Solution:**
- Check version constraints
- Run `terraform init -upgrade`
- Verify version compatibility

## 💰 Cost Considerations

### Local Module Example
- Dev: ~$10-20/month
- Production: ~$50-100/month

### Flexible Module Example
- Small: ~$8/month
- Medium: ~$35/month
- Large: ~$150/month
- XLarge: ~$300/month

### Registry Module Example
- ~$100-200/month (varies by configuration)

### Complete Example
- Dev: ~$100-150/month
- Production: ~$400-500/month

**Tip:** Always start with dev environment and smaller instance sizes!

## 📚 Additional Resources

### Official Documentation
- [Terraform Modules Overview](https://developer.hashicorp.com/terraform/language/modules)
- [Module Development](https://developer.hashicorp.com/terraform/language/modules/develop)
- [Terraform Registry](https://registry.terraform.io/)

### Google Cloud Modules
- [terraform-google-modules](https://github.com/terraform-google-modules)
- [Google Cloud Foundation Toolkit](https://cloud.google.com/foundation-toolkit)

### Community Resources
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Gruntwork Terraform Library](https://gruntwork.io/infrastructure-as-code-library/)

## ✅ Learning Checklist

Track your progress through this lesson:

### Tutorials
- [ ] Read section-01-module-basics.md
- [ ] Read section-02-advanced-modules.md

### Practical Examples
- [ ] Complete local-module example
- [ ] Complete flexible-module example
- [ ] Complete registry-module example
- [ ] Complete complete example

### Concepts Mastered
- [ ] Understand root vs child modules
- [ ] Can create custom local modules
- [ ] Can use Terraform Registry modules
- [ ] Know how to pass data between modules
- [ ] Understand module versioning
- [ ] Can implement T-shirt sizing
- [ ] Can add validation rules
- [ ] Can compose multiple modules
- [ ] Can design multi-tier architecture

## 🎓 What You'll Learn

After completing this lesson:

1. **Module Fundamentals**
   - Root vs child modules
   - Module structure
   - Module sources

2. **Local Modules**
   - Creating custom modules
   - Variables and outputs
   - Code reuse patterns

3. **Registry Modules**
   - Finding public modules
   - Version constraints
   - Module composition

4. **Advanced Patterns**
   - T-shirt sizing
   - Validation rules
   - Optional features
   - Cost estimation

5. **Production Architecture**
   - Multi-module systems
   - Module dependencies
   - Environment management
   - Security patterns

## 🎯 Next Steps

After completing this lesson:

1. **Practice** - Build your own modules for common patterns
2. **Share** - Publish modules to your team or community
3. **Explore** - Try other registry modules
4. **Advance** - Move to Lesson 5 (coming soon)
5. **Build** - Create a real project using modules

## 📝 Quick Reference

### Creating a Module

```bash
# Create module structure
mkdir -p modules/my-module
cd modules/my-module

# Create required files
touch main.tf variables.tf outputs.tf README.md
```

### Using a Local Module

```hcl
module "example" {
  source = "./modules/my-module"
  
  # Input variables
  name  = "my-instance"
  size  = "medium"
}

# Access outputs
output "example_ip" {
  value = module.example.ip_address
}
```

### Using a Registry Module

```hcl
module "network" {
  source  = "terraform-google-modules/network/google"
  version = "~> 9.0"
  
  project_id   = var.project_id
  network_name = "my-vpc"
}
```

### Module Commands

```bash
# Initialize modules
terraform init

# Update modules
terraform init -upgrade

# List modules
terraform providers

# Format module code
terraform fmt -recursive
```

## 🎉 Summary

Modules are the foundation of scalable, maintainable Terraform code. By mastering modules, you'll be able to:

- ✅ Write less code (80% reduction)
- ✅ Maintain infrastructure easily
- ✅ Share code across teams
- ✅ Use battle-tested community modules
- ✅ Build complex systems from simple pieces
- ✅ Scale infrastructure effortlessly

Take your time with each example, experiment with the code, and don't hesitate to customize the modules to fit your needs.

**Happy Learning! 🚀**

---

**Estimated Time:** 8-12 hours total

**Difficulty Progression:** Beginner → Intermediate → Advanced

**Prerequisites:** Lessons 1-3 completed
