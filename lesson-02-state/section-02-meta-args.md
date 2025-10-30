# Lesson Two | Section 2: Meta-Arguments and Advanced Concepts

**Prerequisites:** Completion of Section 1  
**Learning Objectives:**

- Master the count meta-argument for creating multiple resources
- Understand for_each for more flexible resource creation
- Learn dependency management with depends_on
- Control resource lifecycle with lifecycle meta-argument
- Use Google Cloud's self_link attribute effectively

---

## Part 1: The count Meta-Argument - Creating Multiple Resources

### The Problem: Repetitive Code

Imagine you need 3 identical servers. The beginner approach:

```hcl
# BAD: Repetitive code
resource "google_compute_instance" "server1" {
  name         = "web-server-1"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  # ... 50 more lines
}

resource "google_compute_instance" "server2" {
  name         = "web-server-2"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  # ... 50 more lines (copy-paste of above)
}

resource "google_compute_instance" "server3" {
  name         = "web-server-3"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  # ... 50 more lines (copy-paste again!)
}
```

**Problems:**

- 150+ lines for 3 identical servers
- Error-prone copy-paste
- Hard to maintain
- Need 10 servers? Copy-paste 10 times!

### The Solution: count Meta-Argument

```hcl
# GOOD: One resource block, multiple instances
resource "google_compute_instance" "server" {
  count = 3  # ← Magic happens here!
  
  name         = "web-server-${count.index + 1}"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  
  network_interface {
    network = "default"
    access_config {}
  }
  
  tags = ["http-server"]
}
```

**What Happens?**

Terraform creates 3 instances:

1. `google_compute_instance.server[0]` → name: "web-server-1"
2. `google_compute_instance.server[1]` → name: "web-server-2"
3. `google_compute_instance.server[2]` → name: "web-server-3"

### Understanding count.index

**`count.index`** is a special variable available when using count:

- First instance: `count.index = 0`
- Second instance: `count.index = 1`
- Third instance: `count.index = 2`
- (Zero-indexed, like most programming!)

**Example: Creating Unique Names**

```hcl
resource "google_compute_instance" "server" {
  count = 3
  
  # count.index = 0 → "web-server-1"
  # count.index = 1 → "web-server-2"
  # count.index = 2 → "web-server-3"
  name = "web-server-${count.index + 1}"
}
```

**Example: Distribute Across Zones**

```hcl
variable "zones" {
  default = ["us-central1-a", "us-central1-b", "us-central1-c"]
}

resource "google_compute_instance" "server" {
  count = 3
  
  name = "web-server-${count.index + 1}"
  zone = var.zones[count.index]  # Uses count.index to pick zone
  
  # Server 0 → us-central1-a
  # Server 1 → us-central1-b
  # Server 2 → us-central1-c
}
```

### Conditional count - Create or Not?

**Powerful Pattern: Use count for conditional creation**

```hcl
variable "create_instance" {
  type    = bool
  default = true
}

resource "google_compute_instance" "optional" {
  count = var.create_instance ? 1 : 0
  # If true: count = 1 (create 1 instance)
  # If false: count = 0 (create nothing!)
  
  name = "optional-server"
  # ... rest of config
}
```

**Use Case:**

```hcl
variable "environment" {
  default = "dev"
}

# Create monitoring instance only in production
resource "google_compute_instance" "monitoring" {
  count = var.environment == "production" ? 1 : 0
  
  name = "monitoring-server"
  # Only created when environment = "production"
}
```

### Working with count Resources

**Referencing Individual Instances:**

```hcl
# Create 3 instances
resource "google_compute_instance" "server" {
  count = 3
  name  = "web-${count.index + 1}"
  # ...
}

# Reference specific instance
output "first_server_ip" {
  value = google_compute_instance.server[0].network_interface[0].network_ip
}

output "second_server_ip" {
  value = google_compute_instance.server[1].network_interface[0].network_ip
}
```

**Referencing All Instances (Splat Syntax):**

```hcl
# Get all server IPs at once!
output "all_server_ips" {
  value = google_compute_instance.server[*].network_interface[0].network_ip
}

# Results in a list:
# ["10.128.0.2", "10.128.0.3", "10.128.0.4"]
```

### Complete count Example

**Full working example:**

```hcl
# variables.tf
variable "project_id" {
  description = "GCP Project ID"
}

variable "server_count" {
  description = "Number of servers to create"
  default     = 3
}

variable "zones" {
  description = "List of zones"
  default     = ["us-central1-a", "us-central1-b", "us-central1-c"]
}

# main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
}

resource "google_compute_instance" "web" {
  count        = var.server_count
  name         = format("web-server-%02d", count.index + 1)
  machine_type = "e2-micro"
  zone         = var.zones[count.index % length(var.zones)]
  # Modulo operator distributes evenly across zones
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  
  network_interface {
    network = "default"
    access_config {}
  }
  
  metadata = {
    server_index = count.index
  }
  
  tags = ["web-server", "server-${count.index}"]
}

# outputs.tf
output "server_details" {
  value = {
    names = google_compute_instance.web[*].name
    zones = google_compute_instance.web[*].zone
    ips   = google_compute_instance.web[*].network_interface[0].network_ip
  }
}
```

**Deploy it:**

```bash
$ terraform init
$ terraform apply

Plan: 3 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + server_details = {
      + ips   = [
          + "10.128.0.2",
          + "10.128.0.3",
          + "10.128.0.4",
        ]
      + names = [
          + "web-server-01",
          + "web-server-02",
          + "web-server-03",
        ]
      + zones = [
          + "us-central1-a",
          + "us-central1-b",
          + "us-central1-c",
        ]
    }
```

### When count Gets Tricky

**The Index Problem:**

```bash
# Initial: 3 servers
$ terraform apply
# Creates: server[0], server[1], server[2]

# Now change count to 2
count = 2

$ terraform plan
# Terraform will DESTROY server[2]!
# But what if you wanted to remove server[1] instead?
```

**The Issue:**

- count uses index position
- Removing from middle causes re-indexing
- Can lead to unexpected resource destruction

**For more complex scenarios, use for_each instead!**

---



## Part 2: The for_each Meta-Argument - Flexible Resource Creation

### Why for_each is Better for Complex Scenarios

With `count`, resources are identified by index number (0, 1, 2...). This causes problems when you need to:

- Add/remove resources from the middle
- Identify resources by meaningful names
- Create resources from a map of configurations

**for_each** uses keys instead of indices!

### for_each with Sets (Simple List)

**Example: Create Servers in Different Regions**

```hcl
variable "regions" {
  default = toset(["us-central1", "us-east1", "europe-west1"])
}

resource "google_compute_network" "regional" {
  for_each = var.regions  # Iterate over set
  
  name                    = "network-${each.key}"
  auto_create_subnetworks = false
}
```

**What Happens:**

Terraform creates 3 networks:

1. `google_compute_network.regional["us-central1"]` → name: "network-us-central1"
2. `google_compute_network.regional["us-east1"]` → name: "network-us-east1"
3. `google_compute_network.regional["europe-west1"]` → name: "network-europe-west1"

**Key Difference from count:**

```
With count:
google_compute_network.regional[0]
google_compute_network.regional[1]
google_compute_network.regional[2]

With for_each:
google_compute_network.regional["us-central1"]
google_compute_network.regional["us-east1"]
google_compute_network.regional["europe-west1"]
```

**Meaningful keys instead of numbers!**

### for_each with Maps (Complex Configurations)

**This is where for_each really shines!**

**Example: Create Subnetworks with Different Configurations**

```hcl
# variables.tf
variable "subnets" {
  type = map(object({
    region        = string
    ip_cidr_range = string
  }))
  
  default = {
    "iowa" = {
      region        = "us-central1"
      ip_cidr_range = "192.168.1.0/24"
    }
    "virginia" = {
      region        = "us-east1"
      ip_cidr_range = "192.168.2.0/24"
    }
    "singapore" = {
      region        = "asia-southeast1"
      ip_cidr_range = "192.168.3.0/24"
    }
  }
}

variable "network" {
  default = "my-network"
}

# vpc.tf
resource "google_compute_network" "this" {
  name                    = var.network
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "this" {
  for_each = var.subnets  # Iterate over map
  
  project                  = var.project_id
  network                  = google_compute_network.this.name
  name                     = each.key
  region                   = each.value["region"]
  ip_cidr_range            = each.value["ip_cidr_range"]
  private_ip_google_access = true
}
```

**Understanding each.key and each.value:**

```
For "iowa":
  each.key               = "iowa"
  each.value             = { region = "us-central1", ip_cidr_range = "192.168.1.0/24" }
  each.value["region"]   = "us-central1"
  each.value["ip_cidr_range"] = "192.168.1.0/24"

For "virginia":
  each.key               = "virginia"
  each.value             = { region = "us-east1", ip_cidr_range = "192.168.2.0/24" }
  each.value["region"]   = "us-east1"
  each.value["ip_cidr_range"] = "192.168.2.0/24"
```

**Terraform creates:**

```
google_compute_subnetwork.this["iowa"]
  name          = "iowa"
  region        = "us-central1"
  ip_cidr_range = "192.168.1.0/24"

google_compute_subnetwork.this["virginia"]
  name          = "virginia"
  region        = "us-east1"
  ip_cidr_range = "192.168.2.0/24"

google_compute_subnetwork.this["singapore"]
  name          = "singapore"
  region        = "asia-southeast1"
  ip_cidr_range = "192.168.3.0/24"
```

```text
┌───────────────────────────────────────────────────────────────┐
│                     🟦 VPC: my-network                        │
│                (google_compute_network.this)                  │
│                                                               │
│   ┌──────────────────────────┐  ┌──────────────────────────┐  │
│   │ 🟨 Subnet: iowa          │  │ 🟧 Subnet: virginia      │  │
│   │                          │  │                          │  │
│   │ Region: us-central1      │  │ Region: us-east1         │  │
│   │ IP Range: 192.168.1.0/24 │  │ IP Range: 192.168.2.0/24 │  │
│   └──────────────────────────┘  └──────────────────────────┘  │
│                                                               │
│                 ┌──────────────────────────┐                  │
│                 │ 🟪 Subnet: singapore     │                  │
│                 │                          │                  │
│                 │ Region: asia-se-1        │                  │
│                 │ IP: 192.168.3.0/24       │                  │
│                 └──────────────────────────┘                  │
│                                                               │
└───────────────────────────────────────────────────────────────┘

```

> In GCP, a VPC is a global network.
>  Subnets exist directly inside the VPC and are regional.
>  No extra “network layer” like AWS.



### Adding and Removing with for_each

**The Beauty: Add/Remove Without Affecting Others!**

**Scenario: Remove "virginia" subnet**

```hcl
variable "subnets" {
  default = {
    "iowa" = {
      region        = "us-central1"
      ip_cidr_range = "192.168.1.0/24"
    }
    # "virginia" removed - just delete these lines
    "singapore" = {
      region        = "asia-southeast1"
      ip_cidr_range = "192.168.3.0/24"
    }
  }
}
$ terraform plan

Terraform will perform the following actions:

  # google_compute_subnetwork.this["virginia"] will be destroyed
  - resource "google_compute_subnetwork" "this" {
      - name          = "virginia" -> null
      # ...
    }

Plan: 0 to add, 0 to change, 1 to destroy.
```

**Only "virginia" is destroyed!**

- "iowa" stays: `google_compute_subnetwork.this["iowa"]`
- "singapore" stays: `google_compute_subnetwork.this["singapore"]`

**With count, removing the middle item would have caused:**

- server[1] (virginia) → destroyed
- server[2] (singapore) → becomes server[1], recreated!

### Creating VMs with for_each

**Example: VM per Subnet**

```hcl
# main.tf
resource "google_compute_instance" "vm" {
  for_each = var.subnets  # Create VM for each subnet
  
  name         = "vm-${each.key}"
  machine_type = "e2-micro"
  zone         = "${each.value["region"]}-a"  # Convert region to zone
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  
  network_interface {
    subnetwork = google_compute_subnetwork.this[each.key].name
    # References the subnet with same key!
  }
  
  tags = ["${each.key}-vm"]
}
```

**Creates:**

```
google_compute_instance.vm["iowa"]
  name       = "vm-iowa"
  zone       = "us-central1-a"
  subnetwork = google_compute_subnetwork.this["iowa"].name

google_compute_instance.vm["virginia"]
  name       = "vm-virginia"
  zone       = "us-east1-a"
  subnetwork = google_compute_subnetwork.this["virginia"].name

google_compute_instance.vm["singapore"]
  name       = "vm-singapore"
  zone       = "asia-southeast1-a"
  subnetwork = google_compute_subnetwork.this["singapore"].name
```

**Referencing for_each Resources:**

```hcl
# Reference specific resource
output "iowa_vm_ip" {
  value = google_compute_instance.vm["iowa"].network_interface[0].network_ip
}

# Get all values using for expression
output "all_vm_ips" {
  value = {
    for key, instance in google_compute_instance.vm :
    key => instance.network_interface[0].network_ip
  }
}

# Result:
# {
#   "iowa"      = "192.168.1.2"
#   "virginia"  = "192.168.2.2"
#   "singapore" = "192.168.3.2"
# }
```

### count vs for_each: When to Use Each

**Use count when:**

- Creating identical resources
- Number of resources is most important
- Resources don't need unique identifiers
- Simple use cases

```hcl
# Perfect for count
resource "google_compute_instance" "worker" {
  count = 10  # Just need 10 workers
  name  = "worker-${count.index + 1}"
  # All identical except name
}
```

**Use for_each when:**

- Resources have meaningful identifiers
- Need to add/remove from middle
- Each resource has different configuration
- Complex use cases

```hcl
# Perfect for for_each
variable "environments" {
  default = {
    dev = {
      machine_type = "e2-micro"
      disk_size    = 20
    }
    staging = {
      machine_type = "e2-small"
      disk_size    = 50
    }
    prod = {
      machine_type = "e2-standard-4"
      disk_size    = 100
    }
  }
}

resource "google_compute_instance" "env" {
  for_each     = var.environments
  name         = "${each.key}-server"
  machine_type = each.value.machine_type
  # Different config for each environment!
}
```

---



## Part 3: The depends_on Meta-Argument - Managing Dependencies

### How Terraform Handles Dependencies Automatically

**Terraform is Smart!**

When you reference one resource in another, Terraform automatically knows the order:

```hcl
# Network must be created first
resource "google_compute_network" "main" {
  name = "main-network"
}

# Subnet references network
resource "google_compute_subnetwork" "subnet" {
  name    = "subnet-1"
  network = google_compute_network.main.name  # ← Reference!
  # Terraform knows: Create network BEFORE subnet
}

# VM references subnet
resource "google_compute_instance" "vm" {
  name = "vm-1"
  network_interface {
    subnetwork = google_compute_subnetwork.subnet.name  # ← Reference!
    # Terraform knows: Create subnet BEFORE VM
  }
}
```

**Terraform's Dependency Graph:**

```
google_compute_network.main
         ↓
google_compute_subnetwork.subnet
         ↓
google_compute_instance.vm
```

**Automatic and perfect!**

### When Automatic Dependencies Aren't Enough

**The Problem: Race Conditions**

Sometimes resources finish creating before they're *fully* ready.

**Example from our for_each code:**

```hcl
resource "google_compute_network" "this" {
  name = "my-network"
}

resource "google_compute_subnetwork" "this" {
  for_each  = var.subnets
  network   = var.network  # ← Just a string, not a reference!
  name      = each.key
  region    = each.value["region"]
  ip_cidr_range = each.value["ip_cidr_range"]
}
```

**What Happens:**

```bash
$ terraform apply

google_compute_network.this: Creating...
google_compute_network.this: Still creating... [10s elapsed]
google_compute_subnetwork.this["iowa"]: Creating...
google_compute_subnetwork.this["virginia"]: Creating...
google_compute_subnetwork.this["singapore"]: Creating...

Error: Error creating subnetwork: Network not ready yet
```

**Why?**

1. Terraform starts creating the network
2. Before network is fully ready, Terraform starts creating subnets (parallel execution!)
3. Subnets fail because network isn't ready

**Terraform's Parallelism:**

By default, Terraform runs **10 operations in parallel** for speed!

### Solution 1: Explicit depends_on

```hcl
resource "google_compute_subnetwork" "this" {
  depends_on = [google_compute_network.this]  # ← Explicit dependency!
  
  for_each              = var.subnets
  network               = var.network
  name                  = each.key
  region                = each.value["region"]
  ip_cidr_range         = each.value["ip_cidr_range"]
  private_ip_google_access = true
}
```

**Now Terraform knows:**

```
1. Create google_compute_network.this
2. Wait for it to be COMPLETELY finished
3. Then create all subnets
```

**The depends_on Meta-Argument:**

```hcl
depends_on = [
  resource1,
  resource2,
  resource3
]
```

Takes a **list of resources** that must be created first.

### Solution 2: Better - Use Reference Instead

**Even better approach:**

```hcl
resource "google_compute_subnetwork" "this" {
  for_each = var.subnets
  
  # Instead of:
  # network = var.network  # Just a string
  
  # Use reference:
  network = google_compute_network.this.name  # ← Reference!
  
  name                     = each.key
  region                   = each.value["region"]
  ip_cidr_range            = each.value["ip_cidr_range"]
  private_ip_google_access = true
}
```

**Why this is better:**

- Creates implicit dependency automatically
- More idiomatic Terraform
- Easier to read and understand
- Less prone to errors

### When to Use depends_on

**Use depends_on only when:**

1. **No direct reference possible:**

   ```hcl
   # IAM policy needs time to propagate
   resource "google_project_iam_member" "admin" {
     project = var.project_id
     role    = "roles/editor"
     member  = "user:admin@company.com"
   }
   
   # Resource needs that permission to work
   resource "google_storage_bucket" "data" {
     depends_on = [google_project_iam_member.admin]
     name       = "my-bucket"
     # Can't reference the IAM directly, but needs it to exist
   }
   ```

2. **Timing issues not captured by references:**

   ```hcl
   resource "google_sql_database_instance" "db" {
     name = "my-db"
   }
   
   # Needs database to be fully initialized
   resource "google_sql_user" "user" {
     depends_on = [google_sql_database_instance.db]
     name       = "app-user"
     instance   = google_sql_database_instance.db.name
   }
   ```

**General Rule:**

- **Prefer references** when possible
- **Use depends_on** as last resort

### Limiting Parallelism (Alternative Solution)

If you're having timing issues:

```bash
# Run operations one at a time (very slow!)
$ terraform apply -parallelism=1

# Run 5 operations at a time (balanced)
$ terraform apply -parallelism=5
```

**Trade-off:**

- Lower parallelism = Slower but fewer race conditions
- Higher parallelism = Faster but more race conditions

**Best Practice:**

- Fix dependencies properly with depends_on or references
- Keep default parallelism (10) for speed

---



## Part 4: The lifecycle Meta-Argument - Controlling Resource Behavior

The `lifecycle` meta-argument controls how Terraform manages resource lifecycle events.

### Three lifecycle Options

#### Option 1: create_before_destroy

**The Default Behavior (Destructive Change):**

```hcl
resource "google_compute_instance" "web" {
  name = "web-server"
  machine_type = "e2-micro"
  # ...
}

# Change machine type
machine_type = "e2-small"  # Forces replacement

$ terraform apply
# 1. DESTROY old instance (downtime starts!)
# 2. CREATE new instance
# 3. Downtime ends
```

**With create_before_destroy:**

```hcl
resource "google_compute_instance" "web" {
  name         = "web-server"
  machine_type = "e2-small"
  
  lifecycle {
    create_before_destroy = true
  }
  
  # ... rest of config
}

$ terraform apply
# 1. CREATE new instance (both running!)
# 2. DESTROY old instance
# 3. Zero downtime!
```

**Use Case:** High-availability services that can't have downtime.

**Note:** May temporarily double your resources (and costs)!

#### Option 2: prevent_destroy

**Prevent Accidental Deletion:**

```hcl
resource "google_storage_bucket" "critical_data" {
  name     = "company-critical-data-prod"
  location = "US"
  
  lifecycle {
    prevent_destroy = true  # ← Safety lock!
  }
}
```

**What happens if you try to destroy:**

```bash
$ terraform destroy

Error: Instance cannot be destroyed

  on main.tf line 10:
  10: resource "google_storage_bucket" "critical_data" {

Resource google_storage_bucket.critical_data has lifecycle.prevent_destroy
set, but the plan calls for this resource to be destroyed. To avoid this
error and continue with the plan, either disable lifecycle.prevent_destroy
or reduce the scope of the plan using the -target flag.
```

**Terraform refuses to destroy it!**

**Use Cases:**

- Production databases
- Critical storage buckets
- Long-term data storage
- Anything containing important data

**To Actually Destroy (if needed):**

1. Remove the `prevent_destroy` setting
2. Run terraform apply (to update the setting)
3. Then run terraform destroy

```hcl
# Step 1: Comment out or remove prevent_destroy
resource "google_storage_bucket" "critical_data" {
  name     = "company-critical-data-prod"
  location = "US"
  
  # lifecycle {
  #   prevent_destroy = true
  # }
}

# Step 2: Apply the change
$ terraform apply

# Step 3: Now you can destroy
$ terraform destroy
```

#### Option 3: ignore_changes

**The Problem: External Changes**

Sometimes external tools modify your infrastructure:

**Example: Cost Management Tool Adds Labels**

```hcl
resource "google_compute_instance" "web" {
  name   = "web-server"
  labels = {
    environment = "production"
    team        = "engineering"
  }
  # ... rest of config
}
```

**External tool adds a label via API:**

- Adds label: `cost-center = "cc-1234"`

**Next terraform plan:**

```bash
$ terraform plan

Terraform will perform the following actions:

  # google_compute_instance.web will be updated in-place
  ~ resource "google_compute_instance" "web" {
      ~ labels = {
          - "cost-center"  = "cc-1234" -> null
            "environment"  = "production"
            "team"         = "engineering"
        }
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

**Terraform wants to remove the label!** (Because it's not in your config)

**Solution: ignore_changes**

```hcl
resource "google_compute_instance" "web" {
  name = "web-server"
  
  labels = {
    environment = "production"
    team        = "engineering"
  }
  
  lifecycle {
    ignore_changes = [
      labels,  # Ignore any changes to labels
    ]
  }
  
  # ... rest of config
}
```

**Now when external tool adds labels:**

```bash
$ terraform plan

No changes. Your infrastructure matches the configuration.

# Terraform ignores the label differences!
```

**Multiple Attributes:**

```hcl
lifecycle {
  ignore_changes = [
    labels,
    tags,
    metadata,
  ]
}
```

**Ignore Everything:**

```hcl
lifecycle {
  ignore_changes = all  # Ignore all attribute changes
}
```

**⚠️ Use with Caution!**

- Only ignore what external tools manage
- Don't use `all` unless absolutely necessary
- Document why you're ignoring changes

**Use Cases:**

- Cost management tools add labels
- Auto-scaling modifies instance count
- Monitoring tools add metadata
- Security tools add tags

### Complete lifecycle Example

```hcl
resource "google_compute_instance" "production_db" {
  name         = "production-database"
  machine_type = "n1-standard-8"
  zone         = "us-central1-a"
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 100
    }
  }
  
  network_interface {
    network = "default"
  }
  
  labels = {
    environment = "production"
    purpose     = "database"
  }
  
  lifecycle {
    # Prevent accidental deletion of production DB
    prevent_destroy = true
    
    # Create new instance before destroying old (zero downtime)
    create_before_destroy = true
    
    # Ignore changes made by cost management and monitoring tools
    ignore_changes = [
      labels,  # Cost center adds labels
      tags,    # Security team adds tags
    ]
  }
}
```

**This provides:**

- ✅ Protection against accidental deletion
- ✅ Zero-downtime updates
- ✅ Harmony with external tools

---



## Part 5: Using the self_link Attribute

### What is self_link?

In Google Cloud, nearly every resource has a unique identifier called **self_link**.

**Example: Let's Look at a Subnet**

**Using gcloud:**

```bash
$ gcloud compute networks subnets describe iowa --region us-central1

gatewayAddress: 192.168.1.1
id: '4434945742234922953'
ipCidrRange: 192.168.1.0/24
kind: compute#subnetwork
name: iowa
network: https://www.googleapis.com/compute/v1/projects/my-project/global/networks/my-network
region: https://www.googleapis.com/compute/v1/projects/my-project/regions/us-central1
selfLink: https://www.googleapis.com/compute/v1/projects/my-project/regions/us-central1/subnetworks/iowa
stackType: IPV4_ONLY
```

**Using terraform state show:**

```bash
$ terraform state show 'google_compute_subnetwork.this["iowa"]'

resource "google_compute_subnetwork" "this" {
    gateway_address            = "192.168.1.1"
    id                         = "projects/my-project/regions/us-central1/subnetworks/iowa"
    ip_cidr_range              = "192.168.1.0/24"
    name                       = "iowa"
    network                    = "https://www.googleapis.com/compute/v1/projects/my-project/global/networks/my-network"
    project                    = "my-project"
    region                     = "us-central1"
    self_link                  = "https://www.googleapis.com/compute/v1/projects/my-project/regions/us-central1/subnetworks/iowa"
    stack_type                 = "IPV4_ONLY"
}
```

### Why Use self_link?

**The self_link is a unique identifier that includes:**

- Full URL path to the resource
- Project ID
- Region/Zone
- Resource type
- Resource name

**Comparison:**

```hcl
# Using name (ambiguous)
resource "google_compute_instance" "vm" {
  name = "my-vm"
  
  network_interface {
    subnetwork = "iowa"  # Which iowa? In which project? Region?
  }
}

# Using self_link (unambiguous)
resource "google_compute_instance" "vm" {
  name = "my-vm"
  
  network_interface {
    subnetwork = google_compute_subnetwork.this["iowa"].self_link
    # Full path: projects/my-project/regions/us-central1/subnetworks/iowa
    # No ambiguity!
  }
}
```

### Best Practice: Always Use self_link

**Update our earlier example:**

```hcl
# Before (using name)
resource "google_compute_instance" "vm" {
  for_each = var.subnets
  
  name = "vm-${each.key}"
  zone = "${each.value["region"]}-a"
  
  network_interface {
    subnetwork = google_compute_subnetwork.this[each.key].name
  }
}

# After (using self_link) - BETTER!
resource "google_compute_instance" "vm" {
  for_each = var.subnets
  
  name = "vm-${each.key}"
  zone = "${each.value["region"]}-a"
  
  network_interface {
    subnetwork = google_compute_subnetwork.this[each.key].self_link
  }
}
```

**Benefits:**

- ✅ Unambiguous reference
- ✅ Works across projects
- ✅ Works across regions
- ✅ More robust
- ✅ Follows Google Cloud best practices

**From now on, we'll always use self_link for resource references!**

---

## Complete Working Example: Putting It All Together

Let's create a complete example using everything we learned:

**Directory Structure:**

```
chap02-complete/
├── main.tf
├── variables.tf
├── outputs.tf
└── backend.tf
```

**backend.tf:**

```hcl
terraform {
  required_version = ">= 1.9"
  
  backend "gcs" {
    bucket = "my-terraform-state-bucket"
    prefix = "terraform/state/lesson2"
  }
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
```

**variables.tf:**

```hcl
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "regions" {
  description = "Map of regions and their configurations"
  type = map(object({
    zone          = string
    ip_cidr_range = string
  }))
  
  default = {
    iowa = {
      zone          = "us-central1-a"
      ip_cidr_range = "192.168.1.0/24"
    }
    virginia = {
      zone          = "us-east1-b"
      ip_cidr_range = "192.168.2.0/24"
    }
    singapore = {
      zone          = "asia-southeast1-a"
      ip_cidr_range = "192.168.3.0/24"
    }
  }
}
```

**main.tf:**

```hcl
provider "google" {
  project = var.project_id
  region  = "us-central1"
}

# Create a VPC network
resource "google_compute_network" "main" {
  name                    = "main-network"
  auto_create_subnetworks = false
  
  lifecycle {
    prevent_destroy = true  # Protect production network
  }
}

# Create subnetworks using for_each
resource "google_compute_subnetwork" "regional" {
  for_each = var.regions
  
  name                     = "subnet-${each.key}"
  region                   = replace(each.value.zone, "/-[a-z]$/", "")  # Extract region from zone
  network                  = google_compute_network.main.self_link  # Use self_link!
  ip_cidr_range            = each.value.ip_cidr_range
  private_ip_google_access = true
  
  depends_on = [google_compute_network.main]  # Explicit dependency
  
  lifecycle {
    ignore_changes = [
      secondary_ip_range,  # Allow external tools to manage this
    ]
  }
}

# Create VMs in each subnet using for_each
resource "google_compute_instance" "regional" {
  for_each = var.regions
  
  name         = "vm-${each.key}"
  machine_type = "e2-micro"
  zone         = each.value.zone
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }
  
  network_interface {
    subnetwork = google_compute_subnetwork.regional[each.key].self_link  # Use self_link!
    
    access_config {
      // Ephemeral public IP
    }
  }
  
  metadata = {
    region = each.key
    startup-script = <<-EOF
      #!/bin/bash
      echo "Hello from ${each.key}!" > /tmp/hello.txt
    EOF
  }
  
  labels = {
    environment = "demo"
    region      = each.key
  }
  
  tags = ["${each.key}-vm", "web-server"]
  
  lifecycle {
    create_before_destroy = true  # Zero downtime updates
    
    ignore_changes = [
      labels,  # Allow cost management tools to add labels
      metadata,  # Allow monitoring tools to add metadata
    ]
  }
}

# Create firewall rule for SSH access using count
resource "google_compute_firewall" "ssh" {
  count = 1  # Conditional: Only create if needed
  
  name    = "allow-ssh"
  network = google_compute_network.main.self_link  # Use self_link!
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  source_ranges = ["0.0.0.0/0"]  # Allow from anywhere (adjust for security!)
  target_tags   = ["web-server"]
}
```

**outputs.tf:**

```hcl
output "network_self_link" {
  description = "Self-link of the main network"
  value       = google_compute_network.main.self_link
}

output "subnet_details" {
  description = "Details of all subnets"
  value = {
    for key, subnet in google_compute_subnetwork.regional :
    key => {
      name      = subnet.name
      region    = subnet.region
      cidr      = subnet.ip_cidr_range
      self_link = subnet.self_link
    }
  }
}

output "vm_details" {
  description = "Details of all VMs"
  value = {
    for key, vm in google_compute_instance.regional :
    key => {
      name        = vm.name
      zone        = vm.zone
      internal_ip = vm.network_interface[0].network_ip
      external_ip = vm.network_interface[0].access_config[0].nat_ip
      self_link   = vm.self_link
    }
  }
}

output "ssh_command" {
  description = "SSH commands for each VM"
  value = {
    for key, vm in google_compute_instance.regional :
    key => "gcloud compute ssh ${vm.name} --zone=${vm.zone}"
  }
}
```

**Deploy the Complete Example:**

```bash
# Initialize
$ terraform init

# Plan and review
$ terraform plan

# Apply
$ terraform apply

Outputs:

network_self_link = "https://www.googleapis.com/compute/v1/projects/my-project/global/networks/main-network"

subnet_details = {
  "iowa" = {
    "cidr" = "192.168.1.0/24"
    "name" = "subnet-iowa"
    "region" = "us-central1"
    "self_link" = "https://www.googleapis.com/compute/v1/projects/my-project/regions/us-central1/subnetworks/subnet-iowa"
  }
  "singapore" = {
    "cidr" = "192.168.3.0/24"
    "name" = "subnet-singapore"
    "region" = "asia-southeast1"
    "self_link" = "https://www.googleapis.com/compute/v1/projects/my-project/regions/asia-southeast1/subnetworks/subnet-singapore"
  }
  "virginia" = {
    "cidr" = "192.168.2.0/24"
    "name" = "subnet-virginia"
    "region" = "us-east1"
    "self_link" = "https://www.googleapis.com/compute/v1/projects/my-project/regions/us-east1/subnetworks/subnet-virginia"
  }
}

vm_details = {
  "iowa" = {
    "external_ip" = "34.123.45.67"
    "internal_ip" = "192.168.1.2"
    "name" = "vm-iowa"
    "self_link" = "https://www.googleapis.com/compute/v1/projects/my-project/zones/us-central1-a/instances/vm-iowa"
    "zone" = "us-central1-a"
  }
  # ... (virginia and singapore)
}

ssh_command = {
  "iowa" = "gcloud compute ssh vm-iowa --zone=us-central1-a"
  "singapore" = "gcloud compute ssh vm-singapore --zone=asia-southeast1-a"
  "virginia" = "gcloud compute ssh vm-virginia --zone=us-east1-b"
}
```

---

## Summary: Section 2 Key Takeaways

### Meta-Arguments Mastered

#### count Meta-Argument

✅ **Create multiple identical resources**  
✅ **Use `count.index`** for unique names and properties  
✅ **Conditional creation** with `count = condition ? 1 : 0`  
✅ **Splat syntax `[*]`** to reference all instances  
✅ **Best for:** Simple, numbered resources

#### for_each Meta-Argument

✅ **Create resources with meaningful keys**  
✅ **Use with sets** for simple lists  
✅ **Use with maps** for complex configurations  
✅ **Access via `each.key` and `each.value`**  
✅ **Add/remove without affecting others**  
✅ **Best for:** Complex, named resources

#### depends_on Meta-Argument

✅ **Explicit dependency declaration**  
✅ **Use when references aren't enough**  
✅ **Handles timing and race conditions**  
✅ **Prefer references when possible**  
✅ **Last resort for complex dependencies**

#### lifecycle Meta-Argument

✅ **`create_before_destroy`** - Zero downtime updates  
✅ **`prevent_destroy`** - Protect critical resources  
✅ **`ignore_changes`** - Harmony with external tools  
✅ **Control resource behavior precisely**

### Google Cloud Best Practices

#### self_link Attribute

✅ **Unique identifier for resources**  
✅ **Includes full path and context**  
✅ **More robust than names**  
✅ **Always use for resource references**  
✅ **Google Cloud best practice**

### When to Use Each

| Use Case                                  | Tool                            | Why                           |
| ----------------------------------------- | ------------------------------- | ----------------------------- |
| 10 identical web servers                  | count                           | Simple numbering              |
| Servers per region with different configs | for_each                        | Named keys, different configs |
| Network must finish before subnets        | depends_on                      | Timing dependency             |
| Production database                       | lifecycle.prevent_destroy       | Safety                        |
| Zero-downtime deployment                  | lifecycle.create_before_destroy | High availability             |
| Cost tool adds labels                     | lifecycle.ignore_changes        | External management           |
| Reference subnet in VM                    | self_link                       | Unambiguous identification    |

---

## Complete Lesson 2 Summary

### What You've Accomplished

**Section 1: State Management**

- ✅ Understand Terraform state and its critical importance
- ✅ Master state inspection commands
- ✅ Distinguish destructive vs non-destructive changes
- ✅ Set up remote backend for team collaboration
- ✅ Implement state locking for safety

**Section 2: Advanced Concepts**

- ✅ Use count for creating multiple resources
- ✅ Master for_each for flexible resource management
- ✅ Control dependencies with depends_on
- ✅ Manage lifecycle with lifecycle meta-argument
- ✅ Follow Google Cloud best practices with self_link

### Real-World Application

You can now:

- **Manage infrastructure state** professionally
- **Collaborate with teams** without conflicts
- **Write efficient Terraform code** using meta-arguments
- **Build complex infrastructure** with proper dependencies
- **Protect critical resources** from accidental deletion
- **Deploy with zero downtime** using lifecycle rules

### Next Steps

**Practice Exercises:**

1. Create a multi-region infrastructure using for_each
2. Set up backend state with your team
3. Build a production-grade configuration with all meta-arguments
4. Experiment with lifecycle rules

**Further Learning:**

- Modules (Chapter 3)
- Variables and Outputs (Chapter 3)
- Functions and Expressions (Chapter 3)
- Managing multiple environments
- CI/CD integration

---

**Congratulations!** 

You've completed Lesson 2 and significantly advanced your Terraform expertise. You now understand the internals of how Terraform works and can write professional, production-ready infrastructure code.