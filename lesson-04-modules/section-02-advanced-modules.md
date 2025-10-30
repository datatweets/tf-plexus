# Lesson 4: Writing Reusable Code Using Modules

## Section 2: Advanced Module Techniques

**Prerequisites:** Section 1 completed  
**What You'll Master:** Flexible modules, validation, local values, module sharing, and public registries

---

## Overview

In Section 1, we built basic modules. Now we'll make them production-ready by adding flexibility, validation, and learning how to share them. You'll learn:

- How to write flexible modules with abstraction layers
- Custom validation rules for input variables
- Using local values for internal calculations
- Sharing modules via Google Cloud Storage and Git
- Using public module registries effectively

By the end of this section, you'll write modules that are easy to use, hard to misuse, and ready to share.

---

## Part 1: Writing Flexible Modules

### The Problem: Modules as Thin Wrappers

**Bad module design - Just a wrapper:**

```hcl
# modules/server/variables.tf
variable "name" {
  type = string
}

variable "machine_type" {
  type = string
}

# modules/server/main.tf
resource "google_compute_instance" "this" {
  name         = var.machine_type
  machine_type = var.machine_type
  # ...
}
```

**Why is this bad?**

- ❌ No abstraction - just passes values through
- ❌ User needs to know GCP machine types ("e2-micro", "n2-standard-4")
- ❌ No added value over using resources directly
- ❌ Not user-friendly for non-experts

### Good Module Design: Abstraction Layer

**Better approach - T-shirt sizing:**

Instead of requiring users to know GCP machine types, provide simple sizes:

```
small  → e2-micro
medium → e2-medium
large  → n2-standard-2
```

**Benefits:**

- ✅ **User-friendly:** "small", "medium", "large" are intuitive
- ✅ **Abstraction:** Hides GCP-specific details
- ✅ **Centralized decisions:** Change mappings in one place
- ✅ **Added value:** Module is easier to use than raw resources

### Implementing Flexible Modules

Let's enhance our server module with T-shirt sizing and smart defaults.

### Step 1: Updated Variables with Defaults

```hcl
# modules/server/variables.tf

variable "name" {
  type        = string
  description = "Server name (required)"
  # No default = required variable
}

variable "zone" {
  type        = string
  description = "GCP zone"
  default     = "us-central1-b"
  # Has default = optional variable
}

variable "static_ip" {
  type        = string
  description = "Whether to assign static IP"
  default     = true
  # Has default = optional variable
}

variable "machine_size" {
  type        = string
  description = "Server size: small, medium, or large"
  default     = "small"
  
  # Custom validation rule!
  validation {
    condition     = contains(["small", "medium", "large"], var.machine_size)
    error_message = "The machine size must be one of: small, medium, large."
  }
}
```

**Key concept: Optional vs Required Variables**

```hcl
# Required (no default)
variable "name" {
  type = string
}

# Optional (has default)
variable "zone" {
  type    = string
  default = "us-central1-b"
}
```

**Rule:** Variables with defaults are optional; without defaults are required.

### Step 2: Custom Validation Rules

**Syntax:**

```hcl
variable "machine_size" {
  type = string
  
  validation {
    condition     = contains(["small", "medium", "large"], var.machine_size)
    error_message = "The machine size must be one of: small, medium, large."
  }
}
```

**How it works:**

1. **condition:** Boolean expression that must evaluate to `true`
2. **error_message:** Shown to user if condition is `false`
3. **Terraform checks:** Validation happens during `terraform plan`

**Common validation patterns:**

```hcl
# Check if value is in a list
validation {
  condition     = contains(["dev", "staging", "prod"], var.environment)
  error_message = "Environment must be dev, staging, or prod."
}

# Check numeric range
validation {
  condition     = var.port >= 1 && var.port <= 65535
  error_message = "Port must be between 1 and 65535."
}

# Check string pattern
validation {
  condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.name))
  error_message = "Name must start with letter, contain only lowercase letters, numbers, and hyphens."
}

# Check minimum length
validation {
  condition     = length(var.password) >= 8
  error_message = "Password must be at least 8 characters."
}

# Check CIDR block
validation {
  condition     = can(cidrhost(var.vpc_cidr, 0))
  error_message = "Must be a valid CIDR block."
}
```

**Benefits:**

- ✅ **Fail fast:** Errors caught during plan, not apply
- ✅ **Clear messages:** Users know exactly what's wrong
- ✅ **Enforce policies:** Organizational standards in code
- ✅ **Better UX:** Helpful instead of cryptic cloud provider errors

### Step 3: Local Values for Internal Logic

**Local values** are like private variables - used within a module but not exposed outside.

**Syntax:**

```hcl
locals {
  local_name = expression
}

# Access with local.local_name
```

**Our flexible module with locals:**

```hcl
# modules/server/main.tf

locals {
  # Define the mapping
  machine_type_mapping = {
    small  = "e2-micro"
    medium = "e2-medium"
    large  = "n2-standard-2"
  }
  
  # Evaluate the actual machine type
  machine_type = local.machine_type_mapping[var.machine_size]
}

resource "google_compute_address" "static" {
  count = var.static_ip ? 1 : 0
  name  = "${var.name}-ipv4-address"
}

resource "google_compute_instance" "this" {
  name         = var.name
  zone         = var.zone
  machine_type = local.machine_type  # ← Using local value!
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  
  network_interface {
    network = "default"
    
    dynamic "access_config" {
      for_each = google_compute_address.static
      content {
        nat_ip = access_config.value["address"]
      }
    }
  }
  
  metadata_startup_script = file("${path.module}/startup.sh")
  tags                    = ["http-server"]
}
```

**What happens:**

1. User provides: `machine_size = "medium"`
2. Locals block evaluates: `local.machine_type = "e2-medium"`
3. Resource uses: `machine_type = local.machine_type`
4. GCP receives: `machine_type = "e2-medium"`

**More local value examples:**

```hcl
locals {
  # Computed values
  full_name = "${var.environment}-${var.application}-server"
  
  # Conditional logic
  disk_type = var.environment == "prod" ? "pd-ssd" : "pd-standard"
  
  # Complex transformations
  uppercase_tags = [for tag in var.tags : upper(tag)]
  
  # Common labels
  common_labels = {
    managed_by  = "terraform"
    team        = "platform"
    environment = var.environment
    created_on  = formatdate("YYYY-MM-DD", timestamp())
  }
  
  # Multiple resources from data
  zone_count = length(data.google_compute_zones.available.names)
  first_zone = data.google_compute_zones.available.names[0]
}
```

**Local values vs Variables:**

| Feature        | Variables                   | Local Values              |
| -------------- | --------------------------- | ------------------------- |
| **Source**     | Provided by caller          | Calculated internally     |
| **Scope**      | Can be used anywhere        | Module-only               |
| **Purpose**    | Configuration inputs        | Intermediate calculations |
| **Validation** | Yes, with validation block  | No (computed values)      |
| **Override**   | Can be overridden by caller | Cannot be overridden      |

### Step 4: Calling the Flexible Module

Now using the module is much simpler:

```hcl
# main.tf (root module)

module "server1" {
  source = "./modules/server"
  name   = "${var.server_name}-1"
  # That's it! Uses all defaults:
  # - zone: us-central1-b
  # - machine_size: small
  # - static_ip: true
}

module "server2" {
  source       = "./modules/server"
  name         = "${var.server_name}-2"
  zone         = var.zone
  machine_size = "medium"
  # Uses:
  # - zone: from root module variable
  # - machine_size: medium (→ e2-medium)
  # - static_ip: true (default)
}

module "server3" {
  source       = "./modules/server"
  name         = "${var.server_name}-3"
  zone         = "us-central1-f"
  machine_size = "large"
  static_ip    = false
  # Uses:
  # - zone: us-central1-f (explicit)
  # - machine_size: large (→ n2-standard-2)
  # - static_ip: false (no IP at all)
}
```

**Notice the improvement:**

**Before (not flexible):**

```hcl
module "server1" {
  source       = "./modules/server"
  name         = "server-1"
  zone         = "us-central1-b"
  machine_type = "e2-micro"
  static_ip    = true
}
```

**After (flexible):**

```hcl
module "server1" {
  source = "./modules/server"
  name   = "server-1"
}
```

**From 5 lines to 3 lines!** And much more user-friendly.

### Understanding Zone Placement

Let's trace where each server gets deployed:

**server1:**

- No zone specified → Uses default from module: `us-central1-b`

**server2:**

- zone = var.zone → Uses root module variable
- If terraform.tfvars has `zone = "us-central1-c"` → Deployed to `us-central1-c`

**server3:**

- zone = "us-central1-f" → Explicitly set → Deployed to `us-central1-f`

**Order of precedence:**

```
Explicit value → Variable value → Module default
  (highest)         (middle)        (lowest)
```

---



## Part 2: Sharing Modules

### Why Share Modules?

**Scenarios:**

1. **Within organization:** Share across teams and projects
2. **Across projects:** Reuse in multiple Terraform configurations
3. **With community:** Contribute to open source

### Module Source Types

Modules stored in the same repository are **local modules**. To share modules, store them externally.

**Terraform supports:**

- ✅ Google Cloud Storage (GCS)
- ✅ Git repositories (GitHub, GitLab, Bitbucket)
- ✅ Terraform Registry (public)
- ✅ HTTP URLs
- ✅ S3 buckets (AWS)

### Option 1: Google Cloud Storage

**Use case:** Private organizational modules

**Step 1: Upload module to GCS**

```bash
# Package the module
cd modules/server
tar -czf server-module.tar.gz .

# Upload to bucket
gsutil cp server-module.tar.gz gs://my-terraform-modules/modules/
```

**Step 2: Use from GCS**

```hcl
module "server" {
  source = "gcs::https://www.googleapis.com/storage/v1/my-terraform-modules/modules/server-module.tar.gz"
  name   = "web-server"
}
```

**Alternative: Individual files (no compression)**

```hcl
module "server" {
  source = "gcs::https://www.googleapis.com/storage/v1/my-terraform-modules/modules/server"
  name   = "web-server"
}
```

**IAM Requirements:**

You need Storage Object Viewer permission on the bucket:

```bash
# Grant permission
gcloud storage buckets add-iam-policy-binding gs://my-terraform-modules \
  --member="user:your-email@example.com" \
  --role="roles/storage.objectViewer"
```

**Supported compression formats:**

- ✅ `.tar.gz`
- ✅ `.tgz`
- ✅ `.zip`
- ✅ `.tar.bz2`

### Option 2: Git Repositories

**Use case:** Version-controlled modules with collaboration

**Generic Git repository:**

```hcl
module "server" {
  source = "git::https://github.com/myorg/terraform-modules.git//modules/server"
  name   = "web-server"
}
```

**Syntax breakdown:**

```
git::https://github.com/myorg/terraform-modules.git//modules/server
  ↑              ↑                                  ↑         ↑
  |              |                                  |         └─ Module subdirectory
  |              |                                  └─ Double slash separator
  |              └─ Repository URL
  └─ Source type prefix
```

**With versioning (Git tags):**

```hcl
module "server" {
  source = "git::https://github.com/myorg/terraform-modules.git//modules/server?ref=v2.0.0"
  name   = "web-server"
}
```

**Versioning options:**

```hcl
# Specific tag
source = "git::https://...?ref=v2.0.0"

# Specific branch
source = "git::https://...?ref=main"

# Specific commit
source = "git::https://...?ref=abc123def456"
```

**GitHub shorthand:**

```hcl
module "server" {
  source = "github.com/myorg/terraform-modules//modules/server?ref=v2.0.0"
  name   = "web-server"
}
```

**Benefits of Git-based modules:**

- ✅ **Version control:** Track changes over time
- ✅ **Versioning:** Pin to specific versions
- ✅ **Collaboration:** Pull requests for changes
- ✅ **CI/CD integration:** Test modules before release
- ✅ **Documentation:** README, examples in same repo

**Best practices:**

1. **Use semantic versioning:** v1.0.0, v1.1.0, v2.0.0
2. **Pin to versions:** Don't use moving branches in production
3. **Changelog:** Document changes between versions
4. **Examples:** Include usage examples in repo

---



## Part 3: Public Module Registries

### What Are Public Registries?

**Public module registries** are collections of pre-built, community-maintained Terraform modules.

**For Google Cloud, two main registries:**

1. **Terraform Registry:** https://registry.terraform.io/browse/modules?provider=google
2. **Terraform Blueprints for Google Cloud:** https://cloud.google.com/docs/terraform/blueprints/terraform-blueprints

### Terraform Registry Benefits

**Advantages:**

- ✅ **Easy discovery:** Browse by provider and use case
- ✅ **Versioning:** Pin to tested versions
- ✅ **Documentation:** Auto-generated docs
- ✅ **Examples:** Usage examples included
- ✅ **Community-tested:** Popular modules are battle-tested
- ✅ **Free to use:** Open source

### Using Registry Modules

**Example: VPC Network Module**

```hcl
module "network" {
  source  = "terraform-google-modules/network/google"
  version = "9.0.0"
  
  project_id   = var.project_id
  network_name = "my-network"
  
  subnets = [
    {
      subnet_name   = "us-west1"
      subnet_region = "us-west1"
      subnet_ip     = "10.10.10.0/24"
    },
    {
      subnet_name   = "us-east1"
      subnet_region = "us-east1"
      subnet_ip     = "10.10.20.0/24"
    },
  ]
}
```

**Anatomy:**

```hcl
module "label" {
  source  = "namespace/name/provider"
               ↑         ↑     ↑
               |         |     └─ Provider (google, aws, azurerm)
               |         └─ Module name
               └─ Organization/namespace
  
  version = "9.0.0"  # Pin to specific version
  
  # Module-specific arguments
}
```

### Version Constraints

**Exact version:**

```hcl
version = "9.0.0"  # Only 9.0.0
```

**Version ranges:**

```hcl
version = ">= 9.0.0"           # 9.0.0 or higher
version = ">= 9.0.0, < 10.0.0" # 9.x.x only
version = "~> 9.0"             # >= 9.0.0 and < 9.1.0
version = "~> 9.0.0"           # >= 9.0.0 and < 9.1.0
```

**Best practice:** Pin to specific version in production!

### Submodules

Complex registry modules often contain **submodules** for specific use cases.

**Example: Firewall Rules Submodule**

```hcl
module "deny_ssh_ingress" {
  source  = "terraform-google-modules/network/google//modules/firewall-rules"
          #                                        ↑↑
          #                                        Double slash = submodule path
  version = "9.0.0"
  
  project_id   = var.project_id
  network_name = module.network.network_name
  
  rules = [{
    name        = "${module.network.network_name}-deny-ssh"
    description = "Deny SSH from internet"
    direction   = "INGRESS"
    priority    = 1000
    ranges      = ["0.0.0.0/0"]
    
    deny = [{
      protocol = "tcp"
      ports    = ["22"]
    }]
    
    allow = []
    
    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }
  }]
}
```

**Chaining modules:**

Notice how we reference the network module's output:

```hcl
network_name = module.network.network_name
                        ↑          ↑
                        |          └─ Output from network module
                        └─ Network module label
```

**This is module composition!**

### Example: Complete Infrastructure with Registry Modules

```hcl
# Create VPC network
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "9.0.0"
  
  project_id   = var.project_id
  network_name = "production-vpc"
  
  subnets = [
    {
      subnet_name   = "web-tier"
      subnet_region = "us-west1"
      subnet_ip     = "10.0.1.0/24"
    },
    {
      subnet_name   = "app-tier"
      subnet_region = "us-west1"
      subnet_ip     = "10.0.2.0/24"
    },
    {
      subnet_name   = "db-tier"
      subnet_region = "us-west1"
      subnet_ip     = "10.0.3.0/24"
    },
  ]
}

# Create firewall rules
module "firewall" {
  source  = "terraform-google-modules/network/google//modules/firewall-rules"
  version = "9.0.0"
  
  project_id   = var.project_id
  network_name = module.vpc.network_name
  
  rules = [
    {
      name      = "allow-web"
      direction = "INGRESS"
      ranges    = ["0.0.0.0/0"]
      
      allow = [{
        protocol = "tcp"
        ports    = ["80", "443"]
      }]
    },
    {
      name      = "deny-ssh"
      direction = "INGRESS"
      ranges    = ["0.0.0.0/0"]
      
      deny = [{
        protocol = "tcp"
        ports    = ["22"]
      }]
    },
  ]
}

# Use our custom server module
module "web_servers" {
  source = "./modules/server"
  
  count = 3
  
  name         = "web-${count.index}"
  machine_size = "medium"
  zone         = "us-west1-a"
  static_ip    = true
}
```

**What we did:**

1. ✅ Used public VPC module from registry
2. ✅ Used public firewall submodule from registry
3. ✅ Used our custom server module
4. ✅ Chained modules together (firewall uses VPC output)
5. ✅ Created 3 servers using count

### Learning from Public Modules

**Public modules are excellent learning resources!**

**How to learn:**

1. **Browse the registry:** Find modules for your use case
2. **Check the source:** Click "Source" link to GitHub
3. **Read the code:** Study how experts write Terraform
4. **Check examples:** Most modules have examples/ directory
5. **Read issues/PRs:** See common problems and solutions

**Example exploration:**

```bash
# Clone a public module
git clone https://github.com/terraform-google-modules/terraform-google-network.git

# Explore structure
cd terraform-google-network
ls -la

# modules/          ← Submodules
# examples/         ← Usage examples
# main.tf          ← Main module code
# variables.tf     ← Input variables
# outputs.tf       ← Output values
# README.md        ← Documentation
```

**What to learn from public modules:**

- ✅ Code organization patterns
- ✅ Variable naming conventions
- ✅ Validation best practices
- ✅ Documentation styles
- ✅ Testing approaches
- ✅ Complex use cases

---

## Summary: Section 2 Key Takeaways

### Flexible Modules

✅ **Abstraction layers:** Hide complexity behind simple interfaces
✅ **T-shirt sizing:** Use intuitive sizes instead of technical specs
✅ **Validation rules:** Enforce constraints and provide clear errors
✅ **Local values:** Internal calculations not exposed to callers
✅ **Smart defaults:** Make variables optional with sensible defaults

### Module Sharing

✅ **Google Cloud Storage:** Private organizational modules
✅ **Git repositories:** Version-controlled with collaboration
✅ **Versioning:** Pin to specific versions for stability
✅ **Compression:** Support for .tar.gz, .zip, etc.

### Public Registries

✅ **Terraform Registry:** Official public modules
✅ **Google Blueprints:** Google-recommended patterns
✅ **Versioning:** Pin to tested versions
✅ **Submodules:** Access specific functionality
✅ **Module composition:** Chain modules together
✅ **Learning resource:** Study production-quality code

### Best Practices

✅ **Add value:** Don't create thin wrappers
✅ **Validate inputs:** Use validation blocks
✅ **Document:** Clear descriptions for all variables
✅ **Version:** Use semantic versioning for shared modules
✅ **Test:** Include examples and test configurations
✅ **Pin versions:** Don't use moving targets in production

---

## What's Next?

**You've completed Section 2!** You now know:

- ✅ How to write flexible, user-friendly modules
- ✅ How to validate inputs and enforce policies
- ✅ How to share modules across teams and projects
- ✅ How to leverage public module registries
- ✅ How to compose complex infrastructure from modules

**Ready for hands-on practice?**

In the next section, we'll create **working examples**:

1. **local-module/** - Basic local module with server provisioning
2. **flexible-module/** - Advanced module with T-shirt sizing
3. **registry-module/** - Using public registry modules
4. **complete/** - Production-ready multi-tier architecture