# Lesson 3 | Section 2: Writing Efficient Terraform Code

## Functions, Data Sources, and Outputs

**Prerequisites:** Section 1 completed  
**What You'll Master:** Built-in functions, data sources, output values, and development workflows

---

## Overview

Terraform provides powerful built-in functions and data sources to make your code smarter and more dynamic. In this section, you'll learn:

- How to use Terraform's built-in functions
- How to reference existing cloud resources with data sources
- How to expose important information with outputs
- Development best practices with `terraform fmt` and `terraform validate`

By the end of this section, you'll write production-grade Terraform code that integrates seamlessly with existing infrastructure.

---

## Part 1: Terraform Functions

### What Are Functions?

Functions are **built-in operations** that transform or manipulate data. Think of them as Excel formulas for your infrastructure code.

**Key points:**

- ✅ Built into Terraform (no installation needed)
- ✅ Work with strings, numbers, lists, maps, and more
- ✅ Chainable - output of one function can be input to another
- ✅ Evaluated at runtime

### Testing Functions with terraform console

The **terraform console** is your playground for experimenting with functions:

```bash
$ terraform console
> upper("hello")
"HELLO"
> length([1, 2, 3, 4, 5])
5
> max(10, 20, 5, 100)
100
```

**Try it yourself:**

```bash
$ cd /path/to/terraform/project
$ terraform console
```

### Essential String Functions

#### upper() and lower()

Convert strings to uppercase or lowercase:

```hcl
> upper("hello terraform")
"HELLO TERRAFORM"

> lower("PRODUCTION-SERVER")
"production-server"
```

**Real example:**

```hcl
resource "google_compute_instance" "server" {
  # Ensure name is always lowercase (GCP requirement)
  name = lower(var.server_name)
}
```

#### format()

Create formatted strings (like printf):

```hcl
> format("server-%03d", 5)
"server-005"

> format("%s-%s", "web", "prod")
"web-prod"
```

**Format specifiers:**

- `%s` - String
- `%d` - Integer
- `%03d` - Integer padded to 3 digits with zeros
- `%f` - Float

**Real example:**

```hcl
resource "google_compute_instance" "servers" {
  count = 5
  
  # Creates: server-001, server-002, server-003, server-004, server-005
  name = format("server-%03d", count.index + 1)
}
```

#### replace() and regex()

Transform strings with pattern matching:

```hcl
> replace("hello-world", "-", "_")
"hello_world"

> replace("version: 1.2.3", "/[^0-9.]/", "")
"1.2.3"
```

**Real example:**

```hcl
locals {
  # Convert environment name to valid GCP label
  # Labels can only contain lowercase letters, numbers, hyphens
  env_label = lower(replace(var.environment, "_", "-"))
}
```

### Essential List Functions

#### length()

Count items in a list:

```hcl
> length(["us-west1", "us-west2", "us-east1"])
3

> length([])
0
```

**Real example:**

```hcl
output "zone_count" {
  value       = length(var.zones)
  description = "Total number of zones configured"
}
```

#### element()

Get an item from a list (with wrap-around):

```hcl
> element(["a", "b", "c"], 0)
"a"

> element(["a", "b", "c"], 1)
"b"

> element(["a", "b", "c"], 3)  # Index 3 wraps to 0!
"a"

> element(["a", "b", "c"], 4)  # Index 4 wraps to 1!
"b"
```

**Real example (Round-robin zone assignment):**

```hcl
variable "zones" {
  default = ["us-west1-a", "us-west1-b", "us-west1-c"]
}

resource "google_compute_instance" "servers" {
  count = 10
  
  name = "server-${count.index}"
  
  # Distribute servers across zones in round-robin fashion
  # Server 0 -> zone 0, Server 1 -> zone 1, Server 2 -> zone 2
  # Server 3 -> zone 0, Server 4 -> zone 1, etc.
  zone = element(var.zones, count.index)
}
```

#### concat()

Combine multiple lists:

```hcl
> concat(["a", "b"], ["c", "d"])
["a", "b", "c", "d"]

> concat(["us-west1"], ["us-west2", "us-east1"])
["us-west1", "us-west2", "us-east1"]
```

**Real example:**

```hcl
locals {
  default_zones = ["us-west1-a", "us-west1-b"]
  extra_zones   = var.enable_ha ? ["us-east1-a", "us-east1-b"] : []
  
  # Combine default zones with optional HA zones
  all_zones = concat(local.default_zones, local.extra_zones)
}
```

#### slice()

Extract a portion of a list:

```hcl
> slice(["a", "b", "c", "d", "e"], 1, 3)
["b", "c"]

> slice(["a", "b", "c", "d", "e"], 0, 2)
["a", "b"]
```

**Syntax:** `slice(list, start_index, end_index)`  
**Note:** End index is **exclusive** (not included)

### Essential Map Functions

#### lookup()

Safely get a value from a map with a default:

```hcl
> lookup({a = "apple", b = "banana"}, "a", "default")
"apple"

> lookup({a = "apple", b = "banana"}, "z", "default")
"default"  # Key doesn't exist, returns default
```

**Real example:**

```hcl
variable "machine_types" {
  default = {
    small  = "e2-micro"
    medium = "e2-small"
    large  = "e2-medium"
  }
}

resource "google_compute_instance" "server" {
  # If var.size doesn't exist in map, use "e2-micro"
  machine_type = lookup(var.machine_types, var.size, "e2-micro")
}
```

#### merge()

Combine multiple maps:

```hcl
> merge({a = "apple"}, {b = "banana"}, {c = "cherry"})
{
  a = "apple"
  b = "banana"
  c = "cherry"
}

# Later values override earlier ones
> merge({a = "apple"}, {a = "APPLE"})
{
  a = "APPLE"
}
```

**Real example:**

```hcl
locals {
  default_labels = {
    managed_by = "terraform"
    team       = "platform"
  }
  
  # Merge defaults with user-provided labels
  all_labels = merge(local.default_labels, var.custom_labels)
}

resource "google_compute_instance" "server" {
  labels = local.all_labels
}
```

#### keys() and values()

Extract keys or values from a map:

```hcl
> keys({a = "apple", b = "banana", c = "cherry"})
["a", "b", "c"]

> values({a = "apple", b = "banana", c = "cherry"})
["apple", "banana", "cherry"]
```

### Essential Numeric Functions

#### max() and min()

Find maximum or minimum value:

```hcl
> max(10, 20, 5, 100, 3)
100

> min(10, 20, 5, 100, 3)
3
```

**Real example:**

```hcl
variable "requested_disk_size" {
  type = number
}

resource "google_compute_disk" "data" {
  # Ensure disk is at least 10GB (GCP minimum)
  size = max(10, var.requested_disk_size)
}
```

#### ceil(), floor(), abs()

Math operations:

```hcl
> ceil(4.3)
5

> floor(4.8)
4

> abs(-42)
42
```

### IP Network Functions

#### cidrsubnet()

Calculate subnet CIDR blocks:

```hcl
> cidrsubnet("10.0.0.0/16", 8, 0)
"10.0.0.0/24"

> cidrsubnet("10.0.0.0/16", 8, 1)
"10.0.1.0/24"

> cidrsubnet("10.0.0.0/16", 8, 2)
"10.0.2.0/24"
```

**Syntax:** `cidrsubnet(prefix, newbits, netnum)`

- `prefix` - Base CIDR block
- `newbits` - How many bits to add to the prefix
- `netnum` - Which subnet number (0, 1, 2, ...)

**Real example:**

```hcl
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

resource "google_compute_subnetwork" "subnets" {
  count = 3
  
  name          = "subnet-${count.index}"
  ip_cidr_range = cidrsubnet(var.vpc_cidr, 8, count.index)
  network       = google_compute_network.vpc.id
}

# Creates:
# subnet-0: 10.0.0.0/24
# subnet-1: 10.0.1.0/24
# subnet-2: 10.0.2.0/24
```

### Experiment in terraform console!

**Try these exercises:**

```bash
$ terraform console

# Exercise 1: Create server names
> format("web-server-%02d", 5)
> format("%s-%s-%d", "prod", "db", 1)

# Exercise 2: List manipulation
> element(["a", "b", "c"], 5)  # What happens?
> length(concat(["x"], ["y", "z"]))

# Exercise 3: Map operations
> lookup({dev = "small", prod = "large"}, "staging", "medium")
> merge({a = 1}, {b = 2}, {a = 10})  # Which 'a' wins?

# Exercise 4: Subnet calculation
> cidrsubnet("192.168.0.0/16", 8, 0)
> cidrsubnet("192.168.0.0/16", 8, 255)
```

---

## Part 2: Data Sources - Reference Existing Resources

### What Are Data Sources?

**Data sources** let you **query existing resources** that Terraform didn't create. Think of them as read-only lookups.

**Key differences from resources:**

| Resources | Data Sources |
|-----------|--------------|
| **Create** infrastructure | **Read** existing infrastructure |
| `resource "google_compute_instance"` | `data "google_compute_instance"` |
| Defined by you | Already exists in cloud |
| Can be modified/destroyed | Read-only |

### Why Use Data Sources?

**Common scenarios:**

1. ✅ **Reference existing infrastructure** - VPCs, subnets, images created manually
2. ✅ **Discover cloud provider data** - Available zones, regions, machine types
3. ✅ **Share data between Terraform workspaces** - One team creates VPC, another team uses it
4. ✅ **Dynamic configurations** - Use latest Ubuntu image automatically

### Data Source: Compute Zones

**Use case:** Find all available zones in a region dynamically.

```hcl
# Query GCP for available zones in us-west1
data "google_compute_zones" "available" {
  region = "us-west1"
}

# Use the discovered zones
resource "google_compute_instance" "servers" {
  count = 3
  
  name = "server-${count.index}"
  
  # Automatically distribute across all available zones
  zone = data.google_compute_zones.available.names[count.index % length(data.google_compute_zones.available.names)]
  
  machine_type = "e2-micro"
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  
  network_interface {
    network = "default"
  }
}

# See what zones were found
output "discovered_zones" {
  value       = data.google_compute_zones.available.names
  description = "All available zones in the region"
}
```

**What happens:**

1. Terraform queries GCP: "What zones are available in us-west1?"
2. GCP responds: `["us-west1-a", "us-west1-b", "us-west1-c"]`
3. Your servers are distributed across these zones automatically

**Benefits:**

- ✅ Adapts if GCP adds new zones
- ✅ Works in any region without hardcoding
- ✅ Automatically handles region differences

### Data Source: Existing Network

**Use case:** Deploy to an existing VPC network created by another team.

```hcl
# Look up an existing VPC network
data "google_compute_network" "existing_vpc" {
  name = "production-vpc"  # Must already exist!
}

# Look up an existing subnet
data "google_compute_subnetwork" "existing_subnet" {
  name   = "production-subnet"
  region = "us-west1"
}

# Deploy instance into existing network
resource "google_compute_instance" "server" {
  name         = "new-server"
  machine_type = "e2-micro"
  zone         = "us-west1-a"
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  
  # Use the existing network and subnet
  network_interface {
    network    = data.google_compute_network.existing_vpc.self_link
    subnetwork = data.google_compute_subnetwork.existing_subnet.self_link
  }
}

output "network_info" {
  value = {
    network_name   = data.google_compute_network.existing_vpc.name
    network_id     = data.google_compute_network.existing_vpc.id
    subnet_cidr    = data.google_compute_subnetwork.existing_subnet.ip_cidr_range
  }
}
```

**Important notes:**

- ❌ If "production-vpc" doesn't exist, Terraform will error
- ✅ Data sources are **read-only** - you can't modify them
- ✅ Perfect for integrating with existing infrastructure

### Data Source: Compute Image

**Use case:** Always use the latest OS image.

```hcl
# Find the latest Debian 11 image
data "google_compute_image" "debian" {
  family  = "debian-11"
  project = "debian-cloud"
}

resource "google_compute_instance" "server" {
  name         = "server-latest-debian"
  machine_type = "e2-micro"
  zone         = "us-west1-a"
  
  boot_disk {
    initialize_params {
      # Always uses the newest Debian 11 image
      image = data.google_compute_image.debian.self_link
    }
  }
  
  network_interface {
    network = "default"
  }
}

output "image_info" {
  value = {
    image_name        = data.google_compute_image.debian.name
    image_description = data.google_compute_image.debian.description
    image_family      = data.google_compute_image.debian.family
  }
}
```

**Benefits:**

- ✅ No need to update image IDs manually
- ✅ Automatically gets security patches
- ✅ Can use `most_recent = true` for custom images

### Data Source: Project Metadata

**Use case:** Get current project information.

```hcl
# Get information about the current GCP project
data "google_project" "current" {}

output "project_info" {
  value = {
    project_id     = data.google_project.current.project_id
    project_number = data.google_project.current.number
    project_name   = data.google_project.current.name
  }
}

# Use project ID in resources
resource "google_compute_instance" "server" {
  name    = "${data.google_project.current.project_id}-server"
  project = data.google_project.current.project_id
  zone    = "us-west1-a"
  
  # ... rest of configuration
}
```

### When to Use Data Sources vs Variables

**Use variables when:**

- ✅ Values are configuration choices (machine type, region, disk size)
- ✅ Values might change between environments
- ✅ You want user input

**Use data sources when:**

- ✅ Referencing existing cloud resources
- ✅ Discovering available options (zones, images)
- ✅ Integrating with infrastructure managed elsewhere
- ✅ Querying cloud provider metadata

---

## Part 3: Outputs - Exposing Information

### What Are Outputs?

**Outputs** are like return values for your Terraform configuration. They:

- ✅ Display important information after `terraform apply`
- ✅ Can be queried with `terraform output`
- ✅ Can be used as inputs to other Terraform configurations
- ✅ Provide API endpoints, IP addresses, connection strings, etc.

### Basic Output Syntax

```hcl
output "output_name" {
  value       = expression
  description = "Human-readable description"
  sensitive   = false  # Set true for passwords/secrets
}
```

### Simple Output Examples

```hcl
output "instance_name" {
  value       = google_compute_instance.server.name
  description = "The name of the compute instance"
}

output "instance_ip" {
  value       = google_compute_instance.server.network_interface[0].access_config[0].nat_ip
  description = "The external IP address of the instance"
}

output "instance_zone" {
  value       = google_compute_instance.server.zone
  description = "The zone where the instance is deployed"
}
```

**After `terraform apply`:**

```
Outputs:

instance_name = "my-server"
instance_ip = "34.168.123.45"
instance_zone = "us-west1-a"
```

### Output Collections

**Output lists:**

```hcl
output "all_server_names" {
  value       = google_compute_instance.servers[*].name
  description = "Names of all servers created"
}

output "all_server_ips" {
  value       = google_compute_instance.servers[*].network_interface[0].access_config[0].nat_ip
  description = "External IPs of all servers"
}
```

**Output maps:**

```hcl
output "server_info" {
  value = {
    name        = google_compute_instance.server.name
    ip_address  = google_compute_instance.server.network_interface[0].access_config[0].nat_ip
    zone        = google_compute_instance.server.zone
    machine_type = google_compute_instance.server.machine_type
  }
  description = "Complete server information"
}
```

**After `terraform apply`:**

```
Outputs:

server_info = {
  "name" = "my-server"
  "ip_address" = "34.168.123.45"
  "zone" = "us-west1-a"
  "machine_type" = "e2-micro"
}
```

### The Splat Expression [*]

**Splat expressions** extract attributes from multiple resources:

```hcl
# Create 5 servers
resource "google_compute_instance" "servers" {
  count = 5
  
  name         = "server-${count.index}"
  machine_type = "e2-micro"
  zone         = "us-west1-a"
  
  # ... configuration
}

# Output all names
output "server_names" {
  value = google_compute_instance.servers[*].name
  # Returns: ["server-0", "server-1", "server-2", "server-3", "server-4"]
}

# Output all IPs
output "server_ips" {
  value = google_compute_instance.servers[*].network_interface[0].access_config[0].nat_ip
  # Returns: ["34.168.1.10", "34.168.1.11", "34.168.1.12", ...]
}

# Output all zones
output "server_zones" {
  value = google_compute_instance.servers[*].zone
  # Returns: ["us-west1-a", "us-west1-a", "us-west1-a", ...]
}
```

**Syntax:** `resource_type.resource_name[*].attribute`

**Reads as:** "For every instance of this resource, get this attribute"

### Splat with for_each

With `for_each`, use `values()`:

```hcl
resource "google_compute_instance" "servers" {
  for_each = {
    web = { type = "e2-micro" }
    api = { type = "e2-small" }
    db  = { type = "e2-medium" }
  }
  
  name         = each.key
  machine_type = each.value.type
  zone         = "us-west1-a"
  
  # ... configuration
}

# Get all server names
output "server_names" {
  value = values(google_compute_instance.servers)[*].name
  # Returns: ["web", "api", "db"]
}

# Get specific server IP
output "web_server_ip" {
  value = google_compute_instance.servers["web"].network_interface[0].access_config[0].nat_ip
}
```

### Sensitive Outputs

**Hide sensitive data** like passwords or API keys:

```hcl
output "database_password" {
  value       = random_password.db.result
  description = "Database admin password"
  sensitive   = true  # Won't be displayed in console!
}
```

**After `terraform apply`:**

```
Outputs:

database_password = <sensitive>
```

**To view sensitive outputs:**

```bash
$ terraform output database_password
```

### Querying Outputs

**View all outputs:**

```bash
$ terraform output
```

**View specific output:**

```bash
$ terraform output instance_ip
34.168.123.45
```

**Get output as JSON:**

```bash
$ terraform output -json
{
  "instance_ip": {
    "sensitive": false,
    "type": "string",
    "value": "34.168.123.45"
  }
}
```

**Use in shell scripts:**

```bash
# Store IP in variable
SERVER_IP=$(terraform output -raw instance_ip)
echo "Connecting to $SERVER_IP"
ssh user@$SERVER_IP
```

### Output Dependencies

Outputs can depend on data sources and other outputs:

```hcl
data "google_compute_zones" "available" {
  region = "us-west1"
}

output "zone_count" {
  value       = length(data.google_compute_zones.available.names)
  description = "Number of available zones"
}

output "zones_list" {
  value       = data.google_compute_zones.available.names
  description = "List of all available zones"
}

output "first_zone" {
  value       = data.google_compute_zones.available.names[0]
  description = "Primary zone"
}
```

---

## Part 4: Development Best Practices

### terraform fmt - Automatic Code Formatting

**Purpose:** Automatically format your Terraform code to follow standard style.

**Usage:**

```bash
# Format all .tf files in current directory
$ terraform fmt

# Format all .tf files recursively
$ terraform fmt -recursive

# Check if files need formatting (returns exit code)
$ terraform fmt -check
```

**What it does:**

- ✅ Standardizes indentation (2 spaces)
- ✅ Aligns equals signs
- ✅ Removes trailing whitespace
- ✅ Ensures consistent formatting

**Example:**

**Before formatting:**

```hcl
resource "google_compute_instance" "server" {
name="my-server"
  machine_type   =      "e2-micro"
zone = "us-west1-a"
}
```

**After `terraform fmt`:**

```hcl
resource "google_compute_instance" "server" {
  name         = "my-server"
  machine_type = "e2-micro"
  zone         = "us-west1-a"
}
```

**Best practice:** Run `terraform fmt` before every commit!

### terraform validate - Syntax and Logic Checking

**Purpose:** Validate your configuration syntax and internal consistency.

**Usage:**

```bash
$ terraform validate
```

**What it checks:**

- ✅ **Syntax errors** - Missing brackets, quotes, commas
- ✅ **Invalid arguments** - Typos in resource arguments
- ✅ **Type errors** - Wrong data types for variables
- ✅ **Reference errors** - References to non-existent resources
- ❌ Does **NOT** check if cloud resources actually exist

**Example errors:**

```hcl
# Invalid: machine_typ is a typo
resource "google_compute_instance" "server" {
  machine_typ = "e2-micro"  # Typo!
}
```

**Output:**

```
Error: Unsupported argument

  on main.tf line 2, in resource "google_compute_instance" "server":
   2:   machine_typ = "e2-micro"

An argument named "machine_typ" is not expected here. Did you mean "machine_type"?
```

**Best practice:** Run `terraform validate` after making changes!

### Development Workflow

**Recommended workflow:**

```bash
# 1. Write your configuration
$ vim main.tf

# 2. Format the code
$ terraform fmt

# 3. Validate syntax
$ terraform validate
Success! The configuration is valid.

# 4. Initialize (if needed)
$ terraform init

# 5. Plan to preview changes
$ terraform plan

# 6. Apply if plan looks good
$ terraform apply
```

### .gitignore for Terraform

**Always ignore these files in git:**

```gitignore
# Local .terraform directories
**/.terraform/*

# .tfstate files contain sensitive data
*.tfstate
*.tfstate.*

# Crash log files
crash.log
crash.*.log

# Exclude .tfvars files (may contain secrets)
*.tfvars
*.tfvars.json

# Ignore CLI configuration files
.terraformrc
terraform.rc

# Ignore override files
override.tf
override.tf.json
*_override.tf
*_override.tf.json
```

**Do commit:**

- ✅ `.tf` files (your configuration)
- ✅ `.tfvars.example` files (templates)
- ✅ `README.md` (documentation)

**Never commit:**

- ❌ `.tfstate` files (sensitive data!)
- ❌ `.tfvars` files (secrets!)
- ❌ `.terraform/` directory (cached plugins)

### Comments and Documentation

**Use comments to explain WHY, not WHAT:**

**Bad:**

```hcl
# Create a compute instance
resource "google_compute_instance" "server" {
  name = "my-server"  # Set the name
}
```

**Good:**

```hcl
# Use e2-micro for dev to minimize costs. Production uses e2-standard-4.
resource "google_compute_instance" "server" {
  name         = "dev-server"
  machine_type = var.environment == "dev" ? "e2-micro" : "e2-standard-4"
  
  # Static IP required for allowlist-based firewall rules
  network_interface {
    access_config {
      nat_ip = google_compute_address.static.address
    }
  }
}
```

### Using locals for Complex Expressions

**locals** are named values that simplify complex expressions:

```hcl
locals {
  # Common tags applied to all resources
  common_tags = {
    managed_by  = "terraform"
    team        = "platform"
    environment = var.environment
  }
  
  # Environment-specific machine types
  machine_types = {
    dev     = "e2-micro"
    staging = "e2-small"
    prod    = "e2-standard-4"
  }
  
  # Derived values
  instance_name = "${var.environment}-server-${formatdate("YYYYMMDD", timestamp())}"
}

resource "google_compute_instance" "server" {
  name         = local.instance_name
  machine_type = local.machine_types[var.environment]
  labels       = local.common_tags
}
```

**Benefits:**

- ✅ DRY - Define once, use everywhere
- ✅ Clarity - Name complex expressions
- ✅ Maintainability - Change in one place

---

## Summary: Section 2 Key Takeaways

### Terraform Functions

✅ **String functions:** `upper()`, `lower()`, `format()`, `replace()`  
✅ **List functions:** `length()`, `element()`, `concat()`, `slice()`  
✅ **Map functions:** `lookup()`, `merge()`, `keys()`, `values()`  
✅ **Numeric functions:** `max()`, `min()`, `ceil()`, `floor()`  
✅ **Network functions:** `cidrsubnet()`  
✅ **Testing ground:** Use `terraform console` to experiment!

### Data Sources

✅ **Purpose:** Query existing cloud resources  
✅ **Read-only:** Can't modify, only reference  
✅ **Use cases:** Existing networks, latest images, available zones, project metadata  
✅ **Syntax:** `data "google_compute_zones" "available" {}`  
✅ **Access:** `data.google_compute_zones.available.names`

### Outputs

✅ **Purpose:** Expose important values after deployment  
✅ **Syntax:** `output "name" { value = ... description = ... }`  
✅ **Collections:** Use `[*]` splat expressions for multiple resources  
✅ **Sensitive:** Mark secrets as `sensitive = true`  
✅ **Query:** Use `terraform output` and `terraform output -json`

### Development Workflow

✅ **terraform fmt:** Auto-format code before commits  
✅ **terraform validate:** Check syntax and logic  
✅ **terraform console:** Test functions interactively  
✅ **.gitignore:** Never commit `.tfstate` or `.tfvars`  
✅ **locals:** Simplify complex expressions  
✅ **Comments:** Explain WHY, not WHAT

---

## What's Next?

**You've completed Section 2!** You now know:

- ✅ How to use Terraform's built-in functions effectively
- ✅ How to query existing infrastructure with data sources
- ✅ How to expose important information with outputs
- ✅ Professional development workflows and best practices

**Ready for hands-on practice?**

In the next section, we'll create **working examples** where you'll apply everything you've learned:

1. **tf-types/** - Explore all Terraform types hands-on
2. **dynamic-block/** - Attach multiple disks dynamically
3. **conditional-expression/** - Create resources conditionally
4. **data-source/** - Query existing GCP resources
5. **output/** - Master output expressions
6. **complete/** - Build a production-ready multi-server deployment

