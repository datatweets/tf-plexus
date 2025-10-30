# Lesson 4: Writing Reusable Code Using Modules

## Section 1: Module Basics and Structure
 
**Prerequisites:** Completion of Lessons 1-3  
**What You'll Master:** Module structure, building modules, calling modules, and the DRY principle

---

## Overview

One of the main objectives of Infrastructure as Code (IaC) is to create **reusable code** following the **Don't Repeat Yourself (DRY)** principle. In functional programming, we use functions to keep code DRY. In Terraform, we use **modules**.

Think of modules as reusable templates or blueprints. Instead of copying and pasting the same configuration multiple times, you write it once as a module and call it whenever needed.

By the end of this section, you'll understand:

- What modules are and why they matter
- The structure of Terraform modules
- How to build your first local module
- How to call modules from your root configuration
- How to pass data between modules using variables and outputs

---

## Part 1: Understanding Modules

### What Is a Module?

**A module is a self-contained chunk of Terraform code that can be called repeatedly to create cloud infrastructure.**

**Analogy:** Think of a module like a recipe:

- **Recipe (Module):** Instructions to make a cake
- **Ingredients (Variables):** What you pass to the recipe (flour, sugar, eggs)
- **Cake (Resources):** What the recipe creates
- **Recipe Notes (Outputs):** Information about the finished cake (size, calories, servings)

You can use the same recipe (module) to make multiple cakes (resources) by passing different ingredients (variables).

![alt text](image.png)

### Types of Modules

**1. Root Module**

The **root module** is the main Terraform configuration where you run `terraform apply`. It's the top-level directory containing your `.tf` files.

```
my-project/
├── main.tf          # Root module
├── variables.tf     # Root module
├── outputs.tf       # Root module
└── provider.tf      # Root module
```

**2. Child Module**

A **child module** is a module called by another module. It's stored in a subdirectory or external location.

```
my-project/
├── main.tf          # Root module (calls child modules)
├── modules/
│   └── server/      # Child module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
```

**3. Local Module**

A **local module** is stored in the same repository as your root module, typically in a `modules/` subdirectory.

**Relationship:**

```
Root Module
    ↓ calls
Child Module A
    ↓ calls
Child Module B
```

### Why Use Modules?

**Without modules (repetitive code):**

```hcl
# Create server 1
resource "google_compute_instance" "server1" {
  name         = "web-server-1"
  machine_type = "e2-micro"
  zone         = "us-west1-a"
  # ... 20 more lines ...
}

# Create server 2 (copy-paste!)
resource "google_compute_instance" "server2" {
  name         = "web-server-2"
  machine_type = "e2-micro"
  zone         = "us-west1-a"
  # ... 20 more lines ...
}

# Create server 3 (copy-paste again!)
resource "google_compute_instance" "server3" {
  name         = "web-server-3"
  machine_type = "e2-micro"
  zone         = "us-west1-a"
  # ... 20 more lines ...
}
```

**Problems:**
- ❌ Lots of copy-paste code
- ❌ Hard to maintain - need to update 3 places
- ❌ Error-prone - easy to make mistakes
- ❌ Not scalable - need 10 servers? Copy-paste 10 times!

**With modules (DRY principle):**

```hcl
# Define once, use many times
module "server1" {
  source = "./modules/server"
  name   = "web-server-1"
}

module "server2" {
  source = "./modules/server"
  name   = "web-server-2"
}

module "server3" {
  source = "./modules/server"
  name   = "web-server-3"
}
```

**Benefits:**
- ✅ Write once, use many times
- ✅ Maintain in one place
- ✅ Consistent infrastructure
- ✅ Scalable - easy to create 10 or 100 servers
- ✅ Shareable across teams

### The DRY Principle

**DRY = Don't Repeat Yourself**

First formulated by Andrew Hunt and David Thomas in "The Pragmatic Programmer" (1999), this principle states:

> "Every piece of knowledge must have a single, unambiguous, authoritative representation within a system."

**In Terraform context:**

- ✅ **Single source of truth:** Module code in one place
- ✅ **No duplication:** Call the module instead of copying code
- ✅ **Easy updates:** Change once, applies everywhere
- ✅ **Consistency:** All instances follow the same pattern

---

## Part 2: Module Structure

### Standard Module Structure

By convention, a Terraform module consists of three core files:

```
modules/server/
├── main.tf        # Main resource definitions
├── variables.tf   # Input variables
└── outputs.tf     # Output values
```

**Important notes:**

- Terraform only cares about the `.tf` extension
- You can name files anything or combine them into one file
- However, **convention matters** for maintainability
- Following conventions makes code easier for others to understand

### File Purposes

**1. variables.tf - Input Parameters**

Defines what data the module needs from the caller.

```hcl
variable "name" {
  type        = string
  description = "Name of the server"
}

variable "machine_type" {
  type        = string
  description = "GCP machine type"
  default     = "e2-micro"
}

variable "zone" {
  type        = string
  description = "GCP zone"
  default     = "us-central1-a"
}
```

**Think of variables as:**
- Function parameters in programming
- Form fields that need to be filled
- Knobs and dials to customize the module

**2. main.tf - Resource Definitions**

Contains the actual infrastructure resources to create.

```hcl
resource "google_compute_instance" "this" {
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  
  network_interface {
    network = "default"
    access_config {}
  }
}
```

**Think of main.tf as:**
- The actual recipe steps
- The implementation logic
- What the module actually creates

**3. outputs.tf - Return Values**

Exposes information back to the calling module.

```hcl
output "instance_name" {
  value       = google_compute_instance.this.name
  description = "Name of the created instance"
}

output "public_ip" {
  value       = google_compute_instance.this.network_interface[0].access_config[0].nat_ip
  description = "Public IP address"
}

output "self_link" {
  value       = google_compute_instance.this.self_link
  description = "Self link for resource references"
}
```

**Think of outputs as:**
- Return values from a function
- Information the caller might need
- Ways to chain modules together

### Module Purpose: Root vs Child

**In Root Module:**

Outputs display information to the user after `terraform apply`.

```hcl
# Root module outputs.tf
output "web_server_ip" {
  value       = module.web_server.public_ip
  description = "Connect to web server at this IP"
}
```

**After apply:**
```
Outputs:

web_server_ip = "34.168.123.45"
```

**In Child Module:**

Outputs expose information to the calling module for further use.

```hcl
# Child module outputs.tf
output "public_ip" {
  value = google_compute_instance.this.network_interface[0].access_config[0].nat_ip
}
```

**Used by root module:**
```hcl
# Root module main.tf
module "web_server" {
  source = "./modules/server"
  name   = "web"
}

# Reference the output
resource "google_dns_record_set" "web" {
  name = "web.example.com."
  type = "A"
  rrdatas = [module.web_server.public_ip]  # Using the output!
}
```

### The Importance of output Labels

**In child modules, output labels are CRITICAL:**

```hcl
output "public_ip" {  # ← This label is the name you use to reference it!
  value = google_compute_instance.this.network_interface[0].access_config[0].nat_ip
}
```

**Referenced as:**
```hcl
module.web_server.public_ip
                     ↑
               This must match the output label
```

**Key point:** Only values defined as outputs can be referenced from outside the module.

---

## Part 3: Building Your First Module 

### Scenario: Server Provisioning Module

Let's build a module that creates a GCP compute instance with optional static IP.

### Step 1: Create Module Directory Structure

```bash
mkdir -p modules/server
cd modules/server
```

### Step 2: Define Variables (variables.tf)

```hcl
# modules/server/variables.tf

variable "name" {
  type        = string
  description = "Name of the server"
}

variable "machine_type" {
  type        = string
  description = "GCP machine type (e2-micro, e2-small, etc.)"
  default     = "e2-micro"
}

variable "zone" {
  type        = string
  description = "GCP zone where server will be created"
  default     = "us-central1-a"
}

variable "static_ip" {
  type        = bool
  description = "Whether to assign a static IP address"
  default     = false
}
```

**What we defined:**

- **name:** Required (no default) - must be provided by caller
- **machine_type:** Optional (has default) - caller can override
- **zone:** Optional (has default)
- **static_ip:** Optional (defaults to false)

### Step 3: Create Resources (main.tf)

```hcl
# modules/server/main.tf

# Static IP address (conditional creation)
resource "google_compute_address" "static" {
  count = var.static_ip ? 1 : 0
  name  = "${var.name}-ipv4-address"
}

# Compute instance
resource "google_compute_instance" "this" {
  name         = var.name
  zone         = var.zone
  machine_type = var.machine_type
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  
  network_interface {
    network = "default"
    
    # Conditionally create access_config block
    dynamic "access_config" {
      for_each = google_compute_address.static
      content {
        nat_ip = access_config.value["address"]
      }
    }
  }
  
  # Startup script from module directory
  metadata_startup_script = file("${path.module}/startup.sh")
  
  tags = ["http-server"]
}
```

**Key concepts:**

**1. Conditional Resource Creation**

```hcl
count = var.static_ip ? 1 : 0
```

- If `var.static_ip` is `true`: `count = 1` → resource created
- If `var.static_ip` is `false`: `count = 0` → resource NOT created

**2. Dynamic Block for Conditional Configuration**

```hcl
dynamic "access_config" {
  for_each = google_compute_address.static
  content {
    nat_ip = access_config.value["address"]
  }
}
```

- If static IP exists: `for_each` iterates once → access_config created
- If static IP doesn't exist: `for_each` over empty list → no access_config

**Result:** Server has no external IP at all (not even ephemeral)

**3. The path.module Variable**

```hcl
metadata_startup_script = file("${path.module}/startup.sh")
```

**Why not use relative path `./ `?**

- `./` would evaluate to where `terraform apply` is run (root module directory)
- `${path.module}` evaluates to where the module files are located
- **Always use `${path.module}` in modules for file references!**

**Example:**

```
project/
├── main.tf              # Root module (terraform apply runs here)
└── modules/
    └── server/
        ├── main.tf
        └── startup.sh   # Need to reference this from main.tf
```

If module's main.tf uses:
- `./startup.sh` → Looks in `project/` (WRONG!)
- `${path.module}/startup.sh` → Looks in `project/modules/server/` (CORRECT!)

### Step 4: Define Outputs (outputs.tf)

```hcl
# modules/server/outputs.tf

output "public_ip_address" {
  value       = var.static_ip ? google_compute_instance.this.network_interface[0].access_config[0].nat_ip : null
  description = "Public IP address (null if no static IP)"
}

output "private_ip_address" {
  value       = google_compute_instance.this.network_interface[0].network_ip
  description = "Private IP address"
}

output "self_link" {
  value       = google_compute_instance.this.self_link
  description = "Self link for resource references"
}

output "instance_id" {
  value       = google_compute_instance.this.instance_id
  description = "Unique instance ID"
}
```

**Why expose self_link?**

The `self_link` attribute is crucial for referencing resources in GCP. It provides the full resource URI needed for many operations.

**Example use case:**

```hcl
# In another module
resource "google_compute_instance_group" "web" {
  instances = [
    module.server1.self_link,
    module.server2.self_link,
  ]
}
```

### Step 5: Create Startup Script (startup.sh)

```bash
#!/bin/bash
# modules/server/startup.sh

echo "Server provisioned by Terraform module!"
apt-get update
apt-get install -y nginx
systemctl start nginx
systemctl enable nginx
```

### Step 6: Call the Module (Root Module)

Now create the root module that calls our new server module:

```hcl
# main.tf (root module)

module "server1" {
  source       = "./modules/server"
  name         = "${var.server_name}-1"
  zone         = var.zone
  machine_type = var.machine_type
  static_ip    = true
}

module "server2" {
  source       = "./modules/server"
  name         = "${var.server_name}-2"
  zone         = var.zone
  machine_type = var.machine_type
  static_ip    = false
}

module "server3" {
  source       = "./modules/server"
  name         = "${var.server_name}-3"
  zone         = var.zone
  machine_type = "e2-small"
  static_ip    = true
}
```

**Anatomy of a module block:**

```hcl
module "label" {           # ← Label for this module instance
  source = "path"          # ← Required: where module is located
  
  # Arguments the module expects (from variables.tf)
  name         = "value"
  machine_type = "value"
  static_ip    = true
}
```

**Key points:**

- **source attribute:** ALWAYS required, tells Terraform where to find the module
- **Label:** Used to reference module outputs (`module.label.output_name`)
- **Arguments:** Must match variable names in the module's variables.tf
- **Required vs Optional:** Variables without defaults must be provided

**What we created:**

1. **server1:**
   - Uses default machine type from variables
   - Has static IP
   - Zone from root module variable

2. **server2:**
   - Same as server1 BUT no static IP
   - Shows how to override specific settings

3. **server3:**
   - Explicitly sets machine_type to "e2-small"
   - Has static IP
   - Demonstrates overriding defaults

### Step 7: Root Module Variables

```hcl
# variables.tf (root module)

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "server_name" {
  type        = string
  description = "Base name for servers"
  default     = "demo-server"
}

variable "zone" {
  type        = string
  description = "Default zone for servers"
  default     = "us-central1-c"
}

variable "machine_type" {
  type        = string
  description = "Default machine type"
  default     = "e2-micro"
}
```

### Step 8: Root Module Outputs

```hcl
# outputs.tf (root module)

output "server1_ip" {
  value       = module.server1.public_ip_address
  description = "Server 1 public IP"
}

output "server2_ip" {
  value       = module.server2.public_ip_address
  description = "Server 2 public IP (null - no static IP)"
}

output "server3_ip" {
  value       = module.server3.public_ip_address
  description = "Server 3 public IP"
}

output "all_server_ips" {
  value = {
    server1 = module.server1.public_ip_address
    server2 = module.server2.public_ip_address
    server3 = module.server3.public_ip_address
  }
  description = "All server IPs in a map"
}
```

**Accessing module outputs:**

```hcl
module.label.output_name
   ↑      ↑        ↑
   |      |        └─ Output label from module's outputs.tf
   |      └─ Module label from module block
   └─ Keyword
```

### Step 9: Apply the Configuration

```bash
# Initialize (downloads providers, initializes modules)
terraform init

# See what will be created
terraform plan

# Create the infrastructure
terraform apply
```

**After apply:**

```
Outputs:

server1_ip = "34.168.1.10"
server2_ip = null
server3_ip = "34.168.1.20"
```

Notice:
- ✅ server1 has public IP (static_ip = true)
- ❌ server2 has null (static_ip = false, no external IP at all)
- ✅ server3 has public IP (static_ip = true)

---

## Summary: Section 1 Key Takeaways

### Module Concepts

✅ **Modules = Reusable Infrastructure Templates**
✅ **Root Module:** Where you run terraform apply
✅ **Child Module:** Called by other modules
✅ **Local Module:** Stored in same repository
✅ **DRY Principle:** Write once, use many times

### Module Structure

✅ **Three core files:** main.tf, variables.tf, outputs.tf
✅ **variables.tf:** Input parameters (what module needs)
✅ **main.tf:** Resource definitions (what module creates)
✅ **outputs.tf:** Return values (what module exposes)

### Building Modules

✅ **Variables:** Define required and optional inputs
✅ **Resources:** Can define multiple resources in one module
✅ **Outputs:** Only expose what callers need
✅ **path.module:** Always use for file references in modules
✅ **Conditional creation:** Use count with conditionals

### Calling Modules

✅ **source attribute:** Always required
✅ **module label:** Used to reference outputs
✅ **Arguments:** Must match module's variables
✅ **Defaults:** Variables with defaults are optional

### Benefits of Modules

✅ **Reusability:** Write once, call many times

✅ **Consistency:** All instances follow same pattern

✅ **Maintainability:** Update in one place

✅ **Scalability:** Easy to create many resources

✅ **Shareability:** Share across teams and projects

