# Lesson 3 | Section 1: Writing Efficient Terraform Code
## Types, Values, and Expressions

**Prerequisites:** Completion of Lessons 1 and 2  
**What You'll Master:** Terraform types, dynamic blocks, conditional expressions, and efficient code patterns

---

## Overview

While Terraform is a declarative language (you declare what you want, not how to do it), there are times when you need functional programming constructs to write efficient, flexible code. In this section, we'll cover:

- Terraform data types and values
- Dynamic blocks for repeatable nested structures
- Conditional expressions for flexible configurations
- Practical patterns for production code

By the end of this section, you'll write Terraform code that's both powerful and maintainable.

---

## Part 1: Advanced Types and Structured Data

> **Prerequisites:** This section builds on the type system covered in **Lesson 1, Section 2**. 
> If you need a refresher on basic types (string, number, bool, list, map) and how to access 
> their values, please review that lesson first.

### Quick Type System Recap

You already learned Terraform's five basic types in Lesson 1:
- **String** - Text values: `"hello"`
- **Number** - Numeric values: `42`, `3.14`
- **Bool** - True/false: `true`, `false`
- **List** - Ordered collections: `["a", "b", "c"]`
- **Map** - Key-value pairs: `{ key = "value" }`

Now let's explore **advanced type patterns** and introduce the powerful **Object type**.

### Complex Types (Nested Collections)

#### Nested Maps - Maps Within Maps

Maps can contain lists or other maps, creating sophisticated data structures:

```hcl
variable "regional_zones" {
  type = map(list(string))
  default = {
    americas = ["us-west1", "us-west2", "us-east1"]
    europe   = ["europe-west1", "europe-west2"]
    apac     = ["asia-south1", "asia-southeast1"]
  }
}
```

**Accessing nested values:**
```hcl
var.regional_zones.americas     # Returns ["us-west1", "us-west2", "us-east1"]
var.regional_zones.americas[0]  # Returns "us-west1"
var.regional_zones.europe[1]    # Returns "europe-west2"
```

**Real example:**
```hcl
server_configs = {
  web = {
    instance_type = "e2-medium"
    disk_size     = 50
    ports         = [80, 443]
  }
  db = {
    instance_type = "n1-standard-4"
    disk_size     = 500
    ports         = [3306, 5432]
  }
}

# Access nested values
web_type = var.server_configs.web.instance_type  # "e2-medium"
web_port = var.server_configs.web.ports[0]       # 80
```

### Object Type (Structured Data with Constraints)

Objects are like maps but with **strict rules** about what keys must exist and their types:

```hcl
variable "server_config" {
  type = object({
    name     = string
    location = string
    regions  = list(string)
  })
  
  default = {
    name     = "production-server"
    location = "US"
    regions  = ["us-west1", "us-east1"]
  }
}
```

**Why use objects instead of maps?**

**Maps:**
- Flexible - any keys allowed
- No type checking on structure
- Good for variable-length data

**Objects:**
- Strict - must have exactly these keys
- Type-checked - enforces correct types
- Good for structured configurations
- **Terraform will error if keys are missing!**

**Example:**
```hcl
variable "database_config" {
  type = object({
    name            = string
    version         = string
    tier            = string
    disk_size_gb    = number
    backup_enabled  = bool
    allowed_regions = list(string)
  })
}

# If you forget a key or use wrong type, Terraform errors immediately!
```

### The Special null Value

`null` represents **absence** or **nothing**:

```hcl
# When you want to explicitly say "no value"
variable "static_ip" {
  type    = string
  default = null  # No static IP by default
}

# In conditionals
nat_ip = var.assign_public_ip ? google_compute_address.static.address : null
```

**Use cases for null:**
- Optional configurations
- Conditional resource creation
- Default to cloud provider's defaults

---


## Part 2: Dynamic Blocks - Repeatable Nested Structures

### The Problem: Repetitive Nested Blocks

Let's say you want to attach multiple disks to a server. The naive approach:

```hcl
resource "google_compute_instance" "server" {
  name = "my-server"
  
  # Attach first disk
  attached_disk {
    source = google_compute_disk.disk1.name
    mode   = "READ_WRITE"
  }
  
  # Attach second disk
  attached_disk {
    source = google_compute_disk.disk2.name
    mode   = "READ_WRITE"
  }
  
  # Attach third disk
  attached_disk {
    source = google_compute_disk.disk3.name
    mode   = "READ_WRITE"
  }
  
  # ... more repetition ...
}
```

**Problems:**
- ❌ Lots of copy-paste
- ❌ Hard to maintain
- ❌ Can't make number of disks flexible
- ❌ Want 10 disks? Copy-paste 10 times!

### The Solution: Dynamic Blocks

**Dynamic blocks let you generate repeated nested blocks programmatically.**

Think of it like a loop that creates blocks:

```hcl
# Instead of repeating attached_disk multiple times...
dynamic "attached_disk" {
  for_each = var.disks  # Loop over this collection
  
  content {
    # Generate one attached_disk block per item
    source = google_compute_disk.this[attached_disk.key].name
    mode   = attached_disk.value["mode"]
  }
}
```

### Step-by-Step Dynamic Block Example

**Step 1: Define your data structure**

Create a map of disks with their configurations:

```hcl
# terraform.tfvars
disks = {
  small-disk = {
    type = "pd-ssd"
    size = 10
    mode = "READ_WRITE"
  }
  medium-disk = {
    type = "pd-balanced"
    size = 50
    mode = "READ_WRITE"
  }
  large-disk = {
    type = "pd-standard"
    size = 100
    mode = "READ_ONLY"
  }
}
```

**Step 2: Create the disks using for_each**

```hcl
resource "google_compute_disk" "this" {
  for_each = var.disks
  
  name = each.key              # "small-disk", "medium-disk", "large-disk"
  type = each.value["type"]    # "pd-ssd", "pd-balanced", "pd-standard"
  size = each.value["size"]    # 10, 50, 100
  zone = var.zone
}
```

This creates three disks:
- `google_compute_disk.this["small-disk"]`
- `google_compute_disk.this["medium-disk"]`
- `google_compute_disk.this["large-disk"]`

**Step 3: Attach all disks using dynamic block**

```hcl
resource "google_compute_instance" "server" {
  name         = "dynamic-block-demo"
  machine_type = "e2-micro"
  zone         = var.zone
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  
  # Dynamic block - generates multiple attached_disk blocks
  dynamic "attached_disk" {
    for_each = var.disks  # Loop over the disks map
    
    content {
      # attached_disk.key = "small-disk", "medium-disk", "large-disk"
      source = google_compute_disk.this[attached_disk.key].name
      mode   = attached_disk.value["mode"]
    }
  }
  
  network_interface {
    network = "default"
    access_config {}
  }
}
```

**What happens?**

Terraform **generates** this code at runtime:

```hcl
attached_disk {
  source = google_compute_disk.this["small-disk"].name
  mode   = "READ_WRITE"
}

attached_disk {
  source = google_compute_disk.this["medium-disk"].name
  mode   = "READ_WRITE"
}

attached_disk {
  source = google_compute_disk.this["large-disk"].name
  mode   = "READ_ONLY"
}
```

### Understanding Dynamic Block Syntax

```hcl
dynamic "BLOCK_NAME" {
  for_each = COLLECTION_TO_ITERATE
  
  content {
    # Define the contents of each generated block
    # Use BLOCK_NAME.key and BLOCK_NAME.value to access items
  }
}
```

**Components:**

1. **`dynamic "attached_disk"`** - Declares a dynamic block for `attached_disk`
2. **`for_each = var.disks`** - Loops over your collection
3. **`content { }`** - Defines what goes inside each generated block
4. **`attached_disk.key`** - The map key ("small-disk", "medium-disk", etc.)
5. **`attached_disk.value`** - The map value (the disk configuration object)

### Dynamic Block with Lists

You can also use lists:

```hcl
variable "firewall_rules" {
  type = list(object({
    port     = number
    protocol = string
  }))
  
  default = [
    { port = 80, protocol = "tcp" },
    { port = 443, protocol = "tcp" },
    { port = 8080, protocol = "tcp" }
  ]
}

resource "google_compute_firewall" "allow" {
  name    = "allow-multiple-ports"
  network = "default"
  
  dynamic "allow" {
    for_each = var.firewall_rules
    
    content {
      protocol = allow.value.protocol
      ports    = [allow.value.port]
    }
  }
}
```

**With a list, use:**
- `allow.value` - The current item in the list
- `allow.key` - The index (0, 1, 2, ...)

### Benefits of Dynamic Blocks

✅ **Flexible** - Add/remove items by changing data, not code

✅ **DRY** - Don't Repeat Yourself

✅ **Maintainable** - One block definition for all instances

✅ **Scalable** - Works with 3 disks or 300 disks

**Without dynamic block:** 300 disks = 300 copy-pasted blocks  
**With dynamic block:** 300 disks = 1 dynamic block + data

---

## Part 3: Conditional Expressions - Flexible Infrastructure

> **Building on Lesson 1:** We introduced the ternary operator syntax in Lesson 1, Section 2 
> as part of expressions. Now we'll master using it for **conditional resource creation** and 
> advanced infrastructure patterns.

### Ternary Operator Recap

**Syntax:** `condition ? true_value : false_value`

**Quick examples:**

```hcl
# Choose based on environment
cpu_count = var.environment == "production" ? 4 : 1
disk_type = var.disk_size > 100 ? "pd-ssd" : "pd-standard"
```

### Conditional Resource Creation with count

> **Note:** The `count` meta-argument was introduced in **Lesson 2, Section 2**. 
> This section shows how to combine count with conditional expressions for optional resources.

**The Pattern:** Create resources conditionally using:

```hcl
count = condition ? 1 : 0
```

- **If condition is true:** `count = 1` → Resource is created
- **If condition is false:** `count = 0` → Resource is NOT created

**Example: Optional Static IP Address**

Let's create a server that can optionally have a static IP:

```hcl
variable "static_ip" {
  type        = bool
  description = "Whether to assign a static IP address"
  default     = false
}

# Only create static IP if var.static_ip is true
resource "google_compute_address" "static" {
  count = var.static_ip ? 1 : 0  # Conditional creation!
  name  = "ipv4-address"
}

resource "google_compute_instance" "server" {
  name         = "conditional-server"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  
  network_interface {
    network = "default"
    
    access_config {
      # If static IP exists, use it; otherwise use null (ephemeral IP)
      nat_ip = var.static_ip ? google_compute_address.static[0].address : null
    }
  }
}
```

**How it works:**

**Scenario 1: static_ip = false**
```bash
$ terraform apply -var static_ip=false
```
- `count = false ? 1 : 0` → `count = 0`
- No static IP resource created
- `nat_ip = null` → Google assigns ephemeral IP

**Scenario 2: static_ip = true**
```bash
$ terraform apply -var static_ip=true
```
- `count = true ? 1 : 0` → `count = 1`
- Static IP resource created
- `nat_ip = google_compute_address.static[0].address` → Uses static IP

### Using null for Optional Blocks

> **Note:** This pattern combines `count` (Lesson 2) with `dynamic` blocks and `for_each` 
> to conditionally create entire nested blocks.

**Advanced Pattern:** Create entire blocks conditionally using dynamic + conditional.

**Use Case:** Either assign a static IP OR no external IP at all (not even ephemeral).

```hcl
resource "google_compute_address" "static" {
  count = var.static_ip ? 1 : 0
  name  = "ipv4-address"
}

resource "google_compute_instance" "server" {
  name         = "conditional-server"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  
  network_interface {
    network = "default"
    
    # Conditionally create the entire access_config block
    dynamic "access_config" {
      for_each = google_compute_address.static  # If empty, no block created!
      
      content {
        nat_ip = google_compute_address.static[0].address
      }
    }
  }
}
```

**How this works:**

**When static_ip = false:**
- `google_compute_address.static` is empty (count = 0)
- `for_each` over empty collection → **No access_config block generated**
- Result: **No external IP at all** (fully private server)

**When static_ip = true:**
- `google_compute_address.static` exists (count = 1)
- `for_each` loops once → **access_config block generated**
- Result: **Static external IP assigned**

**Test it:**

```bash
# No external IP
$ terraform apply -var static_ip=false
# Check console - server has no external IP!

# Static external IP
$ terraform apply -var static_ip=true
# Check console - server has static IP!
```

### Complex Conditional Example

**Scenario:** Different configurations based on environment.

```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

resource "google_compute_instance" "server" {
  name         = "${var.environment}-server"
  
  # Production: 4 CPUs, Dev/Staging: 1 CPU
  machine_type = var.environment == "prod" ? "e2-standard-4" : "e2-micro"
  
  zone = var.environment == "prod" ? "us-central1-a" : "us-west1-a"
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      
      # Production: 100GB, Others: 20GB
      size = var.environment == "prod" ? 100 : 20
    }
  }
  
  network_interface {
    network = "default"
    access_config {
      # Production gets static IP, others get ephemeral
      nat_ip = var.environment == "prod" ? google_compute_address.prod_ip[0].address : null
    }
  }
  
  labels = {
    environment = var.environment
    
    # Only production gets this label
    critical = var.environment == "prod" ? "true" : "false"
  }
}

# Static IP only for production
resource "google_compute_address" "prod_ip" {
  count = var.environment == "prod" ? 1 : 0
  name  = "production-static-ip"
}
```

### Nested Conditionals

You can nest conditions:

```hcl
machine_type = (
  var.environment == "prod" ? "e2-standard-4" :
  var.environment == "staging" ? "e2-small" :
  "e2-micro"  # default for dev
)
```

**But be careful!** Too many nested conditions become hard to read. Consider using locals:

```hcl
locals {
  machine_types = {
    prod    = "e2-standard-4"
    staging = "e2-small"
    dev     = "e2-micro"
  }
}

resource "google_compute_instance" "server" {
  machine_type = local.machine_types[var.environment]
}
```

**Much cleaner!**

---

## Summary: Section 1 Key Takeaways

### Advanced Types (Building on Lesson 1)

✅ **Reviewed:** Basic types (string, number, bool, list, map) from Lesson 1  
✅ **Advanced:** Nested maps and complex data structures  
✅ **New:** Object type for strict type validation  
✅ **Special value:** null for absence  
✅ **Best practice:** Use objects when structure matters, maps when flexible

### Dynamic Blocks

✅ **Purpose:** Generate repeated nested blocks programmatically  
✅ **Syntax:** `dynamic "block_name" { for_each = ... content { } }`  
✅ **Access:** Use `block_name.key` and `block_name.value`  
✅ **Benefits:** DRY, flexible, scalable code  
✅ **Use when:** You need multiple similar nested blocks

### Conditional Expressions (Building on Lesson 1 & 2)

✅ **Syntax:** `condition ? true_value : false_value` (from Lesson 1)  
✅ **With count:** Create resources conditionally (uses Lesson 2 concepts)  
✅ **With null:** Omit optional configurations  
✅ **With dynamic:** Create entire blocks conditionally  
✅ **Best practice:** Use locals for complex conditions

### Real-World Applications

You can now:
- ✅ Use advanced type patterns for complex configurations
- ✅ Handle variable numbers of resources flexibly
- ✅ Create environment-specific configurations
- ✅ Write DRY (Don't Repeat Yourself) code
- ✅ Implement optional features cleanly
- ✅ Build truly reusable Terraform modules

