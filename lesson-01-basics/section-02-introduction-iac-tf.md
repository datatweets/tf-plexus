# Lesson One | Section 2: Terraform Syntax and Basic Commands
  
**Prerequisites:** Completion of Section 1  
**Learning Objectives:**

- Master HashiCorp Configuration Language (HCL) syntax
- Understand the six essential Terraform commands
- Create real infrastructure on Google Cloud Platform
- Learn best practices and avoid common mistakes

---

## Part 1: Mastering HCL Syntax and Structure

### Understanding the Language of Infrastructure

HashiCorp Configuration Language (HCL) is Terraform's native language. Think of it as the grammar and vocabulary you use to describe your infrastructure. Just like learning any language, we'll start with the basics and build up to complex sentences.

### The Three Building Blocks of HCL

Every HCL configuration is built from three fundamental elements: blocks, arguments, and expressions. Master these, and you can build anything.

---

### Building Block 1: Blocks - The Containers

**What is a Block?**

A block is a container that groups related configuration together. Think of it like a box that holds related items.

**Block Anatomy:**

```hcl
block_type "label" "name" {
  # Contents go here
}
```

**Real Example:**

```hcl
resource "google_storage_bucket" "my_data" {
  name     = "my-unique-bucket-name"
  location = "US"
}
```

**Breaking It Down:**

- `resource` = Block type (what kind of block is this?)
- `"google_storage_bucket"` = First label (what type of resource?)
- `"my_data"` = Second label (what do we call this resource?)
- `{ ... }` = Block body (the configuration details)

**The Four Main Block Types:**

#### Block Type 1: terraform {} - Configuration Block

This block configures Terraform itself. It's like the "settings" for your entire project.

```hcl
terraform {
  required_version = ">= 1.9.0"  # Require Terraform 1.9.0 or newer
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.38.0"
    }
  }
}
```

**What This Does:**

- Sets minimum Terraform version required
- Declares which providers (plugins) you need
- Specifies provider versions for consistency

**Why This Matters:**

- Ensures team members use compatible versions
- Prevents surprises from provider changes
- Documents dependencies clearly

**Real-World Analogy:**
Like specifying "This recipe requires a mixer (not a whisk) and fresh ingredients (not frozen)."

#### Block Type 2: provider {} - Provider Configuration

This block configures how Terraform connects to cloud services. It's like logging into your cloud account.

```hcl
provider "google" {
  project     = "my-project-id"
  region      = "us-central1"
  zone        = "us-central1-a"
  credentials = file("~/.gcp/credentials.json")
}
```

**What Each Argument Means:**

**`project`:** Your Google Cloud project ID

- Where to create resources
- Like your account number
- Example: `"terraform-made-easy"`

**`region`:** Geographic region for resources

- Affects latency and compliance
- Example: `"us-central1"` (Iowa, USA)
- Major regions: us-central1, europe-west1, asia-east1

**`zone`:** Specific data center within region

- For fine-grained placement
- Example: `"us-central1-a"`
- Zones: a, b, c, f within each region

**`credentials`:** How to authenticate

- Path to service account JSON key
- Or uses Application Default Credentials
- Security best practice: Don't hardcode!

**Multiple Provider Configurations:**

Sometimes you need to work with multiple accounts or regions:

```hcl
# Default provider for US resources
provider "google" {
  project = "my-us-project"
  region  = "us-central1"
}

# Separate provider for European resources
provider "google" {
  alias   = "europe"
  project = "my-eu-project"
  region  = "europe-west1"
}

# Use the European provider
resource "google_storage_bucket" "eu_data" {
  provider = google.europe  # Use the aliased provider
  name     = "eu-bucket"
  location = "EU"
}
```

**Why Multiple Providers:**

- Different projects for different teams
- Different regions for compliance
- Separate billing accounts
- Dev vs prod environments

#### Block Type 3: resource {} - Infrastructure Resources

This is the heart of Terraform. Resource blocks define the actual infrastructure you want to create.

**Basic Structure:**

```hcl
resource "provider_resourcetype" "local_name" {
  argument1 = "value1"
  argument2 = "value2"
}
```

**Complete Example:**

```hcl
resource "google_storage_bucket" "data_lake" {
  name          = "company-data-lake-prod"
  location      = "US"
  storage_class = "STANDARD"
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
}
```

**Understanding Resource Naming:**

**The Resource Type:** `google_storage_bucket`

- `google` = Provider name
- `storage_bucket` = Resource type
- Full name describes exactly what it creates

**The Local Name:** `data_lake`

- Your nickname for this resource
- Used to reference it elsewhere in code
- Should be descriptive and meaningful

**Referencing Resources:**

Once created, reference this resource in other parts of your code:

```hcl
# Reference the bucket's name
output "bucket_name" {
  value = google_storage_bucket.data_lake.name
}

# Reference the bucket's URL
output "bucket_url" {
  value = google_storage_bucket.data_lake.url
}

# Use in another resource
resource "google_storage_bucket_iam_member" "viewer" {
  bucket = google_storage_bucket.data_lake.name
  role   = "roles/storage.objectViewer"
  member = "user:sarah@company.com"
}
```

**The Reference Pattern:**

```
  resource_type.local_name.attribute
        ↓               ↓        ↓
google_storage_bucket.data_lake.name
```

#### Block Type 4: Nested Blocks - Blocks Within Blocks

Many resources have complex configurations that use nested blocks.

**Example: Virtual Machine with Complex Configuration**

```hcl
resource "google_compute_instance" "web_server" {
  name         = "web-server-01"
  machine_type = "n1-standard-2"
  zone         = "us-central1-a"
  
  # Nested block: Boot disk configuration
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 100
      type  = "pd-ssd"
    }
  }
  
  # Nested block: Network interface
  network_interface {
    network = "default"
    
    # Nested block within nested block!
    access_config {
      # External IP configuration
      nat_ip = "34.123.45.67"
    }
  }
  
  # Nested block: Metadata
  metadata = {
    ssh-keys = "admin:${file("~/.ssh/id_rsa.pub")}"
  }
  
  # Nested block: Service account
  service_account {
    email  = "service-account@project.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }
  
  # Nested block: Scheduling
  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }
}
```

**Why Nested Blocks:**

- Organize complex configurations logically
- Group related settings together
- Mirror the structure of the cloud service
- Make code more readable

**Reading Nested Blocks:**

Think of nested blocks as folders within folders:

```
Virtual Machine
├── Boot Disk
│   └── Initialization Settings
├── Network Interface
│   └── External IP Config
├── Metadata
├── Service Account
└── Scheduling
```

---

### Building Block 2: Arguments - The Settings

**What are Arguments?**

Arguments are key-value pairs that configure your resources. They're like filling out a form.

**Argument Syntax:**

```hcl
key = value
```

**The Five Types of Values:**

#### Value Type 1: Strings (Text)

Strings are text values, enclosed in double quotes.

```hcl
name     = "my-bucket"
location = "US"
project  = "my-gcp-project"
```

**String Interpolation:**

You can embed expressions inside strings using `${}`:

```hcl
name = "bucket-${var.environment}-${var.team}"
# Results in: "bucket-production-engineering"

description = "Created by ${var.created_by} on ${timestamp()}"
# Results in: "Created by sarah@company.com on 2025-10-26T10:30:00Z"
```

**Multi-line Strings:**

For longer text, use heredoc syntax:

```hcl
startup_script = <<-EOF
  #!/bin/bash
  apt-get update
  apt-get install -y nginx
  systemctl start nginx
  echo "Hello from Terraform!" > /var/www/html/index.html
EOF
```

**String Functions:**

```hcl
# Convert to uppercase
name = upper("my-bucket")  # "MY-BUCKET"

# Convert to lowercase  
name = lower("MY-BUCKET")  # "my-bucket"

# Replace text
name = replace("my-old-bucket", "old", "new")  # "my-new-bucket"

# Trim whitespace
name = trimspace("  my-bucket  ")  # "my-bucket"
```

#### Value Type 2: Numbers

Numbers don't need quotes.

```hcl
disk_size          = 100        # Integer
min_cpu_platform   = 2.5        # Decimal
instance_count     = 3          # Integer
auto_delete        = true       # Boolean (also a number: 1 or 0)
```

**Number Operations:**

```hcl
# Basic math
total_size = 50 + 50                    # 100
half_size  = 100 / 2                    # 50
doubled    = 25 * 2                     # 50

# Using variables
disk_size = var.base_size * var.multiplier
```

#### Value Type 3: Booleans (True/False)

Booleans represent yes/no, on/off, true/false.

```hcl
auto_delete              = true
uniform_bucket_access    = true
enable_cdn               = false
force_destroy            = false
```

**Boolean Logic:**

```hcl
# AND operator
enabled = var.is_production && var.monitoring_enabled

# OR operator  
enabled = var.is_dev || var.is_test

# NOT operator
disabled = !var.is_production
```

#### Value Type 4: Lists (Arrays)

Lists are ordered collections of values, enclosed in square brackets.

```hcl
# List of strings
zones = ["us-central1-a", "us-central1-b", "us-central1-c"]

# List of numbers
port_numbers = [80, 443, 8080]

# List of mixed types (avoid if possible)
mixed = ["text", 123, true]
```

**Accessing List Elements:**

```hcl
# Lists are zero-indexed
first_zone  = zones[0]  # "us-central1-a"
second_zone = zones[1]  # "us-central1-b"
last_zone   = zones[2]  # "us-central1-c"
```

**List Functions:**

```hcl
# Length of list
zone_count = length(zones)  # 3

# Concatenate lists
all_zones = concat(us_zones, eu_zones)

# Get unique elements
unique_zones = distinct(zones)

# Sort list
sorted_zones = sort(zones)
```

**Using Lists in Resources:**

```hcl
resource "google_compute_firewall" "web" {
  name    = "allow-web-traffic"
  network = "default"
  
  # Allow multiple ports using a list
  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"]
  }
  
  # Allow traffic from multiple IP ranges
  source_ranges = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16"
  ]
}
```

#### Value Type 5: Maps (Objects)

Maps are collections of key-value pairs, enclosed in curly braces.

```hcl
# Map of strings
labels = {
  environment = "production"
  team        = "engineering"
  cost_center = "cc-1234"
  managed_by  = "terraform"
}

# Map of numbers
resource_limits = {
  cpu    = 4
  memory = 16
  disk   = 100
}

# Map of mixed types
config = {
  name    = "my-config"
  enabled = true
  count   = 5
}
```

**Accessing Map Values:**

```hcl
# Using dot notation
environment_name = labels.environment  # "production"

# Using bracket notation (required for keys with special characters)
cost_center = labels["cost_center"]    # "cc-1234"
```

**Using Maps in Resources:**

```hcl
resource "google_storage_bucket" "data" {
  name     = "my-bucket"
  location = "US"
  
  # Apply labels as a map
  labels = {
    environment = "production"
    team        = "data-science"
    project     = "ml-pipeline"
    cost_center = "cc-5678"
  }
}
```

**Dynamic Maps:**

```hcl
# Merge multiple maps
all_labels = merge(
  var.default_labels,
  var.team_labels,
  {
    created_by = "terraform"
    created_at = timestamp()
  }
)

# Result:
# {
#   environment = "production"     # from default_labels
#   team        = "engineering"    # from team_labels
#   created_by  = "terraform"      # from inline map
#   created_at  = "2025-10-26..."  # from inline map
# }
```

---

### Building Block 3: Expressions - The Logic

**What are Expressions?**

Expressions are combinations of values, operators, and functions that produce a result. They add intelligence to your configurations.

#### Expression Type 1: References

**Referencing Other Resources:**

```hcl
# Create a network
resource "google_compute_network" "main" {
  name = "main-network"
}

# Reference that network in a subnet
resource "google_compute_subnetwork" "subnet" {
  name    = "main-subnet"
  network = google_compute_network.main.id  # Reference!
  #           └──────────────────────────┘
  #           resource_type.name.attribute
}

# Reference the subnet in an instance
resource "google_compute_instance" "vm" {
  name = "web-server"
  
  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id  # Reference!
  }
}
```

**Why References Matter:**

1. **Creates Dependencies:**
   - Terraform knows: "Create network before subnet before instance"
   - Automatic ordering, no manual dependency management

2. **Enables Resource Chaining:**
   - Output from one resource becomes input to another
   - Build complex infrastructure from simple components

3. **Prevents Errors:**
   - Can't reference something that doesn't exist
   - Type checking ensures correct usage

**Referencing Variables:**

```hcl
# Define a variable
variable "environment" {
  type    = string
  default = "production"
}

# Use the variable
resource "google_storage_bucket" "data" {
  name     = "bucket-${var.environment}"
  #                   └──────────────┘
  #                   var.variable_name
  location = "US"
}
```

**Referencing Data Sources:**

```hcl
# Query existing infrastructure
data "google_compute_network" "existing" {
  name = "legacy-network"
}

# Use the queried data
resource "google_compute_subnetwork" "new_subnet" {
  name    = "new-subnet"
  network = data.google_compute_network.existing.id
  #         └───────────────────────────────────────┘
  #         data.data_source_type.name.attribute
}
```

#### Expression Type 2: Operators

**Arithmetic Operators:**

```hcl
# Addition
total_storage = var.data_storage + var.backup_storage  # 100 + 50 = 150

# Subtraction
remaining = var.total_budget - var.spent  # 1000 - 750 = 250

# Multiplication
total_cost = var.price_per_unit * var.unit_count  # 10 * 5 = 50

# Division
average = var.total_score / var.test_count  # 450 / 5 = 90

# Modulo (remainder)
is_even = var.number % 2  # 10 % 2 = 0 (even), 11 % 2 = 1 (odd)
```

**Comparison Operators:**

```hcl
# Equality
is_production = var.environment == "production"  # true or false

# Inequality
is_not_dev = var.environment != "development"

# Greater than
needs_upgrade = var.cpu_usage > 80  # true if usage > 80%

# Less than
within_budget = var.cost < var.budget

# Greater than or equal
can_deploy = var.test_coverage >= 80

# Less than or equal
under_limit = var.user_count <= var.max_users
```

**Logical Operators:**

```hcl
# AND - both conditions must be true
enable_backup = var.is_production && var.has_critical_data

# OR - at least one condition must be true
enable_monitoring = var.is_production || var.is_staging

# NOT - reverses the condition
disable_debugging = !var.is_development
```

**Real-World Example:**

```hcl
resource "google_compute_instance" "app_server" {
  name = "app-${var.environment}"
  
  # Use larger machine for production
  machine_type = var.environment == "production" ? "n1-standard-8" : "n1-standard-2"
  #              └──── condition ────┘             └─ if true ──┘   └─ if false ─┘
  
  # Enable automatic restart only in production
  scheduling {
    automatic_restart = var.environment == "production" ? true : false
  }
}
```

#### Expression Type 3: Conditional Expressions (Ternary Operator)

The ternary operator lets you choose between two values based on a condition.

> **💡 Coming Up:** You'll use this extensively with `count` in Lesson 2 (meta-arguments) 
> and master conditional resource creation in Lesson 3 (types and expressions).

**Syntax:**

```hcl
condition ? true_value : false_value
```

**Simple Examples:**

```hcl
# Choose machine type based on environment
machine_type = var.is_production ? "n1-standard-8" : "n1-standard-2"

# Set disk size based on tier
disk_size = var.tier == "premium" ? 500 : 100

# Enable feature based on plan
feature_enabled = var.plan == "enterprise" ? true : false
```

**Nested Conditionals:**

```hcl
# Choose machine type based on multiple conditions
machine_type = (
  var.environment == "production" ? "n1-standard-8" :
  var.environment == "staging"    ? "n1-standard-4" :
  "n1-standard-2"  # default for dev
)

# Complex logic
storage_class = (
  var.access_frequency == "frequent" ? "STANDARD" :
  var.access_frequency == "occasional" ? "NEARLINE" :
  var.access_frequency == "rare" ? "COLDLINE" :
  "ARCHIVE"  # default
)
```

**Real-World Usage:**

```hcl
resource "google_storage_bucket" "backup" {
  name     = "backup-${var.environment}"
  location = var.environment == "production" ? "US" : "us-central1"
  
  # Different storage class for production
  storage_class = var.environment == "production" ? "STANDARD" : "NEARLINE"
  
  # Longer retention for production
  lifecycle_rule {
    condition {
      age = var.environment == "production" ? 365 : 90
    }
    action {
      type = "Delete"
    }
  }
  
  # Enable versioning only for production
  versioning {
    enabled = var.environment == "production" ? true : false
  }
}
```

#### Expression Type 4: Functions

Terraform includes 100+ built-in functions. Here are the most useful ones:

**String Functions:**

```hcl
# Format strings
name = format("server-%03d", 5)  # "server-005"

# Join list into string
servers = join(",", ["web-1", "web-2", "web-3"])  # "web-1,web-2,web-3"

# Split string into list
ports = split(",", "80,443,8080")  # ["80", "443", "8080"]

# String replacement
name = replace("my-old-name", "old", "new")  # "my-new-name"

# Substring
prefix = substr("production", 0, 4)  # "prod"
```

**Collection Functions:**

```hcl
# Length of list or map
zone_count = length(["us-east1-a", "us-east1-b"])  # 2

# Merge maps
all_tags = merge(
  var.default_tags,
  var.custom_tags
)

# Get element from list
first_zone = element(var.zones, 0)

# Create list from range
numbers = range(1, 5)  # [1, 2, 3, 4]
```

**Numeric Functions:**

```hcl
# Minimum value
min_value = min(10, 20, 5, 15)  # 5

# Maximum value
max_value = max(10, 20, 5, 15)  # 20

# Ceiling (round up)
rounded_up = ceil(10.3)  # 11

# Floor (round down)
rounded_down = floor(10.9)  # 10
```

**Date/Time Functions:**

```hcl
# Current timestamp
created_at = timestamp()  # "2025-10-26T10:30:00Z"

# Format timestamp
date = formatdate("YYYY-MM-DD", timestamp())  # "2025-10-26"
```

**File Functions:**

```hcl
# Read file contents
ssh_key = file("~/.ssh/id_rsa.pub")

# Read file as base64
image_data = filebase64("logo.png")

# Read JSON file
config = jsondecode(file("config.json"))

# Read YAML file  
settings = yamldecode(file("settings.yaml"))
```

**Encoding Functions:**

```hcl
# Encode to JSON
json_data = jsonencode({
  name = "server-01"
  type = "web"
})

# Encode to YAML
yaml_data = yamlencode({
  version = "1.0"
  enabled = true
})

# Base64 encode
encoded = base64encode("Hello, World!")

# Base64 decode
decoded = base64decode("SGVsbG8sIFdvcmxkIQ==")
```

**Real-World Function Example:**

```hcl
# Create multiple similar resources with numbering
resource "google_compute_instance" "web" {
  count = 3
  
  # Use function to create unique names
  name = format("web-server-%02d", count.index + 1)
  # Results in: "web-server-01", "web-server-02", "web-server-03"
  
  machine_type = "n1-standard-2"
  zone         = element(var.zones, count.index)
  # Distributes across zones: zones[0], zones[1], zones[2]
  
  metadata = {
    ssh-keys = "admin:${file("~/.ssh/id_rsa.pub")}"
    startup-script = file("startup.sh")
  }
  
  labels = merge(
    var.default_labels,
    {
      server_number = tostring(count.index + 1)
      created_at    = formatdate("YYYY-MM-DD", timestamp())
    }
  )
}
```

---

### Putting It All Together: Complete Example

Let's create a real-world example that uses everything we've learned:

```hcl
# ============================================================================
# Terraform Configuration Block
# ============================================================================
terraform {
  required_version = ">= 1.9.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.38"
    }
  }
}

# ============================================================================
# Provider Configuration
# ============================================================================
provider "google" {
  project = "terraform-made-easy"
  region  = "us-central1"
  zone    = "us-central1-a"
}

# ============================================================================
# Variables (Inputs)
# ============================================================================
variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "dev"
}

variable "team" {
  description = "Team name"
  type        = string
  default     = "engineering"
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 2
}

# ============================================================================
# Local Values (Computed Variables)
# ============================================================================
locals {
  # Combine variables into useful values
  name_prefix = "${var.team}-${var.environment}"
  
  # Common labels for all resources
  common_labels = {
    environment = var.environment
    team        = var.team
    managed_by  = "terraform"
    created_at  = formatdate("YYYY-MM-DD", timestamp())
  }
  
  # Determine machine type based on environment
  machine_type = (
    var.environment == "production" ? "n1-standard-8" :
    var.environment == "staging"    ? "n1-standard-4" :
    "n1-standard-2"
  )
}

# ============================================================================
# Storage Bucket
# ============================================================================
resource "google_storage_bucket" "data" {
  # Use expression to create unique name
  name     = "${local.name_prefix}-data-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  location = var.environment == "production" ? "US" : "us-central1"
  
  # Different storage class per environment
  storage_class = var.environment == "production" ? "STANDARD" : "NEARLINE"
  
  # Apply common labels
  labels = merge(
    local.common_labels,
    {
      resource_type = "storage"
      purpose       = "data-storage"
    }
  )
  
  # Enable versioning for production only
  versioning {
    enabled = var.environment == "production"
  }
  
  # Lifecycle rule - delete old objects
  lifecycle_rule {
    condition {
      age = var.environment == "production" ? 365 : 90
    }
    action {
      type = "Delete"
    }
  }
  
  # Prevent accidental deletion
  force_destroy = var.environment != "production"
}

# ============================================================================
# Compute Instances
# ============================================================================
resource "google_compute_instance" "app" {
  count = var.instance_count
  
  # Create unique names using count index
  name         = format("${local.name_prefix}-app-%02d", count.index + 1)
  machine_type = local.machine_type
  zone         = "us-central1-a"
  
  # Boot disk configuration (nested block)
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = var.environment == "production" ? 100 : 50
      type  = "pd-ssd"
    }
  }
  
  # Network configuration (nested block)
  network_interface {
    network = "default"
    
    # Dynamic blocks enable conditional nested blocks
    # (You'll learn this pattern in detail in Lesson 3, Section 1)
    dynamic "access_config" {
      for_each = var.environment == "production" ? [1] : []
      content {
        # External IP will be assigned
      }
    }
  }
  
  # Metadata (using map and function)
  metadata = {
    ssh-keys       = "admin:${file("~/.ssh/id_rsa.pub")}"
    startup-script = file("startup.sh")
    environment    = var.environment
    team           = var.team
    instance_index = tostring(count.index + 1)
  }
  
  # Labels (using merge function and locals)
  labels = merge(
    local.common_labels,
    {
      resource_type  = "compute"
      purpose        = "application-server"
      instance_index = tostring(count.index + 1)
    }
  )
  
  # Scheduling (using conditional)
  scheduling {
    automatic_restart   = var.environment == "production"
    on_host_maintenance = "MIGRATE"
    preemptible         = var.environment != "production"
  }
}

# ============================================================================
# Outputs
# ============================================================================
output "bucket_name" {
  description = "Name of the created storage bucket"
  value       = google_storage_bucket.data.name
}

output "bucket_url" {
  description = "URL of the storage bucket"
  value       = google_storage_bucket.data.url
}

output "instance_names" {
  description = "Names of all created instances"
  value       = google_compute_instance.app[*].name
}

output "instance_ips" {
  description = "Internal IP addresses of instances"
  value       = google_compute_instance.app[*].network_interface[0].network_ip
}

output "instance_details" {
  description = "Detailed instance information"
  value = {
    for instance in google_compute_instance.app :
    instance.name => {
      zone         = instance.zone
      machine_type = instance.machine_type
      internal_ip  = instance.network_interface[0].network_ip
    }
  }
}
```

**What This Configuration Does:**

1. **Configures Terraform and Provider**
   - Requires Terraform 1.9.0+
   - Uses Google Cloud provider version 5.38

2. **Defines Inputs (Variables)**
   - Environment, team, instance count
   - Allows customization without changing code

3. **Computes Local Values**
   - Creates reusable expressions
   - Determines machine types based on environment

4. **Creates Storage Bucket**
   - Unique name with timestamp
   - Different settings per environment
   - Versioning for production
   - Lifecycle rules for cost optimization

5. **Creates Multiple Instances**
   - Number determined by variable
   - Unique names with numbering
   - Different configurations per environment
   - Complete metadata and labels

6. **Outputs Important Information**
   - Bucket names and URLs
   - Instance names and IPs
   - Detailed instance information

---

## Part 2: The Six Essential Terraform Commands

Now that you understand HCL syntax, let's learn the commands that bring your infrastructure to life.

### The Terraform Workflow

Think of Terraform workflow like building with LEGO:

```
1. init    → Open the LEGO box, sort the pieces
2. fmt     → Organize your building instructions neatly
3. validate → Make sure you have all the pieces you need
4. plan    → Read the instructions, understand what you'll build
5. apply   → Actually build the LEGO structure
6. destroy → Take it apart when you're done
```

---

### Command 1: terraform init - Initialize Your Project

**What It Does:**

`terraform init` is always the first command you run. It sets up your working directory and downloads everything Terraform needs to work.

**When to Run It:**

- First time setting up a project
- After adding new providers
- After adding new modules
- When cloning a project from Git

**What Happens Behind the Scenes:**

```bash
$ terraform init

Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/google versions matching "5.38.0"...
- Installing hashicorp/google v5.38.0...
- Installed hashicorp/google v5.38.0 (signed by HashiCorp)

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure.
```

**Step-by-Step Breakdown:**

**Step 1: Backend Initialization**

```
Initializing the backend...
```

- Sets up where to store state file
- Default: Local directory
- Production: Remote storage (Cloud Storage, S3, etc.)

**Step 2: Provider Plugin Download**

```
- Finding hashicorp/google versions matching "5.38.0"...
- Installing hashicorp/google v5.38.0...
```

- Downloads Google Cloud provider plugin
- Stores in `.terraform/` directory
- Caches for reuse

**Step 3: Dependency Lock**

```
Terraform has created a lock file .terraform.lock.hcl
```

- Records exact provider versions used
- Ensures team uses same versions
- Commit this file to Git!

**What Gets Created:**

```
my-project/
├── .terraform/           # Plugin directory (don't commit to Git)
│   └── providers/
│       └── hashicorp/
│           └── google/
│               └── 5.38.0/
├── .terraform.lock.hcl   # Lock file (DO commit to Git)
├── main.tf               # Your configuration
└── terraform.tfstate     # State file (created after apply)
```

**Reinitializing:**

Sometimes you need to reinit:

```bash
# After adding new provider
$ terraform init

# Force reinit (download everything again)
$ terraform init -upgrade

# Reinit from fresh start
$ rm -rf .terraform .terraform.lock.hcl
$ terraform init
```

---

### Command 2: terraform fmt - Format Your Code

**What It Does:**

`terraform fmt` automatically formats your Terraform files to follow standard style conventions.

**When to Run It:**

- After writing or editing `.tf` files
- Before committing to Git
- As part of CI/CD pipeline

**Before Formatting:**

```hcl
resource "google_storage_bucket" "data" {
name="my-bucket"
  location    =     "US"
    storage_class="STANDARD"
}
```

**After Formatting:**

```hcl
resource "google_storage_bucket" "data" {
  name          = "my-bucket"
  location      = "US"
  storage_class = "STANDARD"
}
```

**Running the Command:**

```bash
# Format all .tf files in current directory
$ terraform fmt

# Format specific file
$ terraform fmt main.tf

# Format recursively (all subdirectories)
$ terraform fmt -recursive

# Check if formatting is needed (don't change files)
$ terraform fmt -check
```

**What Gets Fixed:**

1. **Indentation:**
   - Uses 2 spaces (never tabs)
   - Aligns nested blocks properly

2. **Alignment:**
   - Aligns equal signs in blocks
   - Makes code more readable

3. **Spacing:**
   - Removes extra blank lines
   - Adds space after commas

4. **Quotes:**
   - Uses consistent quote style

**Example Output:**

```bash
$ terraform fmt
main.tf
variables.tf
outputs.tf

# Three files were formatted
```

**Best Practice - Pre-commit Hook:**

Automatically format before every Git commit:

```bash
# .git/hooks/pre-commit
#!/bin/bash
terraform fmt -recursive
git add -u
```

---

### Command 3: terraform validate - Check Your Code

**What It Does:**

`terraform validate` checks your configuration for errors without accessing any remote services.

**When to Run It:**

- After writing new configuration
- Before running `plan` or `apply`
- As part of CI/CD pipeline

**What Gets Checked:**

1. **Syntax Errors:**
   - Missing brackets
   - Incorrect block structure
   - Typos in keywords

2. **Required Arguments:**
   - All mandatory fields present
   - Correct data types

3. **Valid References:**
   - Referenced resources exist
   - Attribute names correct

4. **Provider Configuration:**
   - Provider blocks properly defined

**Success Example:**

```bash
$ terraform validate
Success! The configuration is valid.
```

**Error Examples:**

**Error 1: Missing Required Argument**

```hcl
resource "google_storage_bucket" "data" {
  location = "US"
  # ERROR: Missing required argument "name"
}
$ terraform validate
╷
│ Error: Missing required argument
│ 
│   on main.tf line 10, in resource "google_storage_bucket" "data":
│   10: resource "google_storage_bucket" "data" {
│ 
│ The argument "name" is required, but no definition was found.
╵
```

**Fix:**

```hcl
resource "google_storage_bucket" "data" {
  name     = "my-bucket"  # Added!
  location = "US"
}
```

**Error 2: Invalid Reference**

```hcl
resource "google_compute_instance" "vm" {
  name = "my-vm"
  network_interface {
    network = google_compute_network.main.id
    # ERROR: Resource "google_compute_network.main" doesn't exist
  }
}
$ terraform validate
╷
│ Error: Reference to undeclared resource
│ 
│   on main.tf line 15, in resource "google_compute_instance" "vm":
│   15:     network = google_compute_network.main.id
│ 
│ A managed resource "google_compute_network" "main" has not been declared in the root module.
╵
```

**Fix:**

```hcl
# First, create the network
resource "google_compute_network" "main" {
  name = "main-network"
}

# Then reference it
resource "google_compute_instance" "vm" {
  name = "my-vm"
  network_interface {
    network = google_compute_network.main.id  # Now valid!
  }
}
```

**Error 3: Syntax Error**

```hcl
resource "google_storage_bucket" "data" {
  name = "my-bucket"
  location = "US"
  # ERROR: Missing closing brace
$ terraform validate
╷
│ Error: Unclosed configuration block
│ 
│   on main.tf line 10, in resource "google_storage_bucket" "data":
│   10: resource "google_storage_bucket" "data" {
│ 
│ The block started here was not properly closed before the end of the file.
╵
```

**Validation in CI/CD:**

```yaml
# GitHub Actions example
- name: Validate Terraform
  run: |
    terraform init
    terraform validate
```

---

### Command 4: terraform plan - Preview Changes

**What It Does:**

`terraform plan` shows you exactly what Terraform will do before making any changes. This is your safety net.

**When to Run It:**

- Always before `terraform apply`
- To review proposed changes
- To understand infrastructure differences
- To share plans with team

**The Plan Process:**

```bash
$ terraform plan

Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  + create
  ~ update in-place
  - destroy
-/+ destroy and then create replacement

Terraform will perform the following actions:

  # google_storage_bucket.default will be created
  + resource "google_storage_bucket" "default" {
      + force_destroy               = false
      + id                          = (known after apply)
      + location                    = "US"
      + name                        = "ivys_bucket_a"
      + project                     = (known after apply)
      + public_access_prevention    = (known after apply)
      + self_link                   = (known after apply)
      + storage_class               = "STANDARD"
      + uniform_bucket_level_access = (known after apply)
      + url                         = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

**Understanding the Symbols:**

**`+` (Create):** New resource will be created

```
  + resource "google_storage_bucket" "new_bucket" {
      + name = "new-bucket"
    }
```

**`-` (Destroy):** Resource will be deleted

```
  - resource "google_storage_bucket" "old_bucket" {
      - name = "old-bucket"
    }
```

**`~` (Update in-place):** Resource will be modified without replacement

```
  ~ resource "google_storage_bucket" "bucket" {
        name          = "my-bucket"
      ~ storage_class = "NEARLINE" -> "STANDARD"
    }
```

**`-/+` (Replace):** Resource will be destroyed and recreated

```
  -/+ resource "google_compute_instance" "vm" {
      ~ name = "old-name" -> "new-name"  # Forces replacement
    }
```

**`(known after apply)`:** Value will be determined during creation

```
  + resource "google_storage_bucket" "bucket" {
      + id        = (known after apply)  # Cloud assigns this
      + self_link = (known after apply)  # Computed from ID
    }
```

**Reading the Summary:**

```
Plan: 2 to add, 1 to change, 1 to destroy.
      │         │              └─ Resources to delete
      │         └─ Resources to modify in-place
      └─ Resources to create
```

**Detailed Plan Example:**

Let's say you change a bucket's storage class:

```hcl
# Before
resource "google_storage_bucket" "data" {
  name          = "my-data-bucket"
  location      = "US"
  storage_class = "NEARLINE"
}

# After (you change NEARLINE to STANDARD)
resource "google_storage_bucket" "data" {
  name          = "my-data-bucket"
  location      = "US"
  storage_class = "STANDARD"  # Changed!
}
```

**The Plan Shows:**

```bash
$ terraform plan

  ~ resource "google_storage_bucket" "data" {
        id            = "my-data-bucket"
        name          = "my-data-bucket"
      ~ storage_class = "NEARLINE" -> "STANDARD"
        # (8 unchanged attributes hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

**Saving Plans:**

You can save a plan to review later or apply exactly as reviewed:

```bash
# Create and save plan
$ terraform plan -out=tfplan

Saved the plan to: tfplan

# Review saved plan (human-readable)
$ terraform show tfplan

# Apply the saved plan (no confirmation prompt)
$ terraform apply tfplan
```

**Plan with Variables:**

```bash
# Plan with specific variable values
$ terraform plan -var="environment=production"

# Plan with variable file
$ terraform plan -var-file="production.tfvars"

# Plan targeting specific resource
$ terraform plan -target=google_storage_bucket.data
```

---

### Command 5: terraform apply - Create Infrastructure

**What It Does:**

`terraform apply` executes your plan and makes actual changes to your infrastructure. This is where the magic happens.

**When to Run It:**

- After reviewing `terraform plan`
- When you're ready to create or update infrastructure
- When team has approved changes

**The Apply Process:**

```bash
$ terraform apply

Terraform will perform the following actions:

  # google_storage_bucket.default will be created
  + resource "google_storage_bucket" "default" {
      + name     = "ivys_bucket_a"
      + location = "US"
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

google_storage_bucket.default: Creating...
google_storage_bucket.default: Creation complete after 2s [id=ivys_bucket_a]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

**Step-by-Step Breakdown:**

**Step 1: Generate Plan**

```
Terraform will perform the following actions:
```

- Same as running `terraform plan`
- Shows what will change

**Step 2: Confirmation Prompt**

```
Do you want to perform these actions?
  Only 'yes' will be accepted to approve.

  Enter a value:
```

- Safety check
- Type exactly "yes" (not "y" or "YES")
- Ctrl+C to cancel

**Step 3: Execution**

```
google_storage_bucket.default: Creating...
```

- Terraform makes API calls
- Shows progress in real-time
- Can take seconds to minutes

**Step 4: Completion**

```
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

- Summary of what happened
- State file updated
- Infrastructure is live!

**Auto-Approve (Use with Caution):**

```bash
# Skip confirmation prompt
$ terraform apply -auto-approve
```

**⚠️ Warning:** Use only in:

- Automated CI/CD pipelines
- Development environments
- When you're absolutely sure

**Never use in production without review!**

**Apply with Saved Plan:**

```bash
# First, create and review plan
$ terraform plan -out=tfplan

# Team reviews and approves

# Apply exactly what was reviewed
$ terraform apply tfplan  # No confirmation prompt needed
```

**What Gets Created:**

After successful apply:

```
my-project/
├── main.tf
├── terraform.tfstate      # State file (updated)
└── terraform.tfstate.backup  # Previous state (backup)
```

**Handling Failures:**

**Scenario: Partial Apply Failure**

```bash
$ terraform apply -auto-approve

google_storage_bucket.bucket1: Creating...
google_storage_bucket.bucket1: Creation complete [id=bucket1]

google_storage_bucket.bucket2: Creating...
╷
│ Error: Error creating bucket: googleapi: Error 409: Bucket name already taken.
╵

Apply failed. Resources: 1 added, 0 changed, 0 destroyed.
```

**What Happened:**

- bucket1 was created successfully
- bucket2 failed
- State file reflects reality (bucket1 exists)

**How to Recover:**

```bash
# Fix the issue (change bucket2 name)
$ vim main.tf

# Run apply again
$ terraform apply
# Terraform will:
# - Leave bucket1 alone (already exists)
# - Try to create bucket2 again (with new name)
```

**Terraform's Idempotency:**

- Running apply multiple times is safe
- Terraform only changes what's needed
- Already-correct resources are left alone

---

### Command 6: terraform destroy - Delete Infrastructure

**What It Does:**

`terraform destroy` deletes all resources defined in your configuration. Use with extreme caution.

**When to Run It:**

- Tearing down test environments
- Cleaning up after demos
- Decommissioning projects
- Cost savings (delete unused infrastructure)

**⚠️ CRITICAL WARNINGS:**

- **Irreversible:** Deleted resources cannot be recovered
- **Data Loss:** All data in resources will be deleted
- **No Undo:** There is no "undo" button
- **Review Carefully:** Always read the plan
- **Team Coordination:** Confirm with team before running

**The Destroy Process:**

```bash
$ terraform destroy

Terraform will perform the following actions:

  # google_storage_bucket.default will be destroyed
  - resource "google_storage_bucket" "default" {
      - id            = "ivys_bucket_a" -> null
      - location      = "US" -> null
      - name          = "ivys_bucket_a" -> null
      - storage_class = "STANDARD" -> null
    }

Plan: 0 to add, 0 to change, 1 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

google_storage_bucket.default: Destroying... [id=ivys_bucket_a]
google_storage_bucket.default: Destruction complete after 1s

Destroy complete! Resources: 1 destroyed.
```

**Step-by-Step Breakdown:**

**Step 1: Destruction Plan**

```
  - resource "google_storage_bucket" "default" {
      - name = "ivys_bucket_a" -> null
    }
```

- Shows what will be deleted
- All values become `null`

**Step 2: Serious Confirmation**

```
Do you really want to destroy all resources?
  There is no undo. Only 'yes' will be accepted to confirm.
```

- More serious warning than apply
- Type exactly "yes"
- Think before typing!

**Step 3: Deletion**

```
google_storage_bucket.default: Destroying...
```

- Makes deletion API calls
- Shows progress

**Step 4: Completion**

```
Destroy complete! Resources: 1 destroyed.
```

- All resources deleted
- State file updated (now empty)

**Selective Destruction:**

```bash
# Destroy only specific resource
$ terraform destroy -target=google_storage_bucket.test_bucket

# Destroy with auto-approve (DANGEROUS!)
$ terraform destroy -auto-approve
```

**Protection Against Accidental Destruction:**

**Method 1: Lifecycle Rule**

```hcl
resource "google_storage_bucket" "critical_data" {
  name     = "critical-production-data"
  location = "US"
  
  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }
}
```

If you try to destroy:

```bash
$ terraform destroy
╷
│ Error: Instance cannot be destroyed
│ 
│ Resource google_storage_bucket.critical_data has lifecycle.prevent_destroy set,
│ but the plan calls for this resource to be destroyed.
╵
```

**Method 2: Confirmation Checklist**

Before running destroy, verify:

- [ ] Backed up all important data?
- [ ] Confirmed with team?
- [ ] Read the destruction plan completely?
- [ ] This is the correct environment?
- [ ] Not in production?
- [ ] Have a recovery plan?

**Safe Destruction Workflow:**

```bash
# 1. Review what will be destroyed
$ terraform plan -destroy

# 2. Save destruction plan
$ terraform plan -destroy -out=destroy.tfplan

# 3. Review with team
$ terraform show destroy.tfplan

# 4. If approved, execute
$ terraform apply destroy.tfplan
```

**What Happens to State:**

After destroy:

```
my-project/
├── main.tf
├── terraform.tfstate        # Empty (all resources removed)
└── terraform.tfstate.backup # Contains pre-destroy state
```

**Recovering from Accidental Destroy:**

**If you haven't run another command:**

```bash
# Restore from backup
$ cp terraform.tfstate.backup terraform.tfstate

# Recreate infrastructure
$ terraform apply
```

**If state is lost:**

- No easy recovery
- Must recreate everything manually
- Or import existing resources (advanced topic)

---

## Part 3: Best Practices and Common Mistakes (5 minutes)

### The Ten Golden Rules

#### Rule 1: Always Run Plan Before Apply

**Why:**

- Catch mistakes before they happen
- Understand impact of changes
- Share plans with team for review

**Good Practice:**

```bash
$ terraform plan  # Review carefully
# [Review the output]
$ terraform apply  # Execute
```

**Bad Practice:**

```bash
$ terraform apply -auto-approve  # YOLO! (Don't do this in production)
```

#### Rule 2: Use Version Control (Git)

**Why:**

- Track all changes
- Collaborate with team
- Rollback if needed
- Audit trail

**What to Commit:**

```bash
git add *.tf          # All Terraform files
git add *.tfvars      # Variable files (if not sensitive)
git add .terraform.lock.hcl  # Lock file

git commit -m "Add production database infrastructure"
```

**What NOT to Commit:**

```bash
# .gitignore
.terraform/          # Plugins directory
*.tfstate            # State files (contain secrets)
*.tfstate.backup     # State backups
*.tfvars             # If contains secrets
.terraform.tfstate.lock.info
```

#### Rule 3: Use Meaningful Names

**Good Names:**

```hcl
resource "google_storage_bucket" "user_uploads_production" {
  name = "company-user-uploads-prod"
}

resource "google_compute_instance" "web_server_frontend" {
  name = "web-fe-prod-01"
}
```

**Bad Names:**

```hcl
resource "google_storage_bucket" "bucket1" {
  name = "bucket123"
}

resource "google_compute_instance" "instance" {
  name = "vm1"
}
```

#### Rule 4: Add Comments

**Good Practice:**

```hcl
# Storage bucket for user-uploaded profile images
# Retention: 90 days in STANDARD class, then move to NEARLINE
# Security: Public read access, private write
resource "google_storage_bucket" "user_profile_images" {
  name     = "user-profile-images-prod"
  location = "US"
  
  # Cost optimization: Move old images to cheaper storage
  lifecycle_rule {
    condition {
      age = 90  # Days
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
}
```

#### Rule 5: Protect State Files

**State files contain:**

- Passwords
- API keys
- Private information
- Complete infrastructure details

**Best Practices:**

**Use Remote State:**

```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-state-prod"
    prefix = "infrastructure"
  }
}
```

**Enable Encryption:**

```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-state-prod"
    encryption_key = "projects/my-project/locations/global/keyRings/terraform/cryptoKeys/state"
  }
}
```

**Enable State Locking:**

- Prevents concurrent modifications
- Avoids state corruption
- Automatic with most remote backends

#### Rule 6: Use Variables for Reusability

**Bad: Hardcoded Values**

```hcl
resource "google_compute_instance" "vm" {
  name         = "web-server-production"
  machine_type = "n1-standard-4"
  zone         = "us-central1-a"
}
```

**Good: Parameterized**

```hcl
variable "environment" {
  type = string
}

variable "machine_type" {
  type = string
}

resource "google_compute_instance" "vm" {
  name         = "web-server-${var.environment}"
  machine_type = var.machine_type
  zone         = var.zone
}
```

**Usage:**

```bash
$ terraform apply -var="environment=production" -var="machine_type=n1-standard-4"
```

#### Rule 7: Test in Dev Before Prod

**Workflow:**

```bash
# 1. Test in dev
$ cd environments/dev
$ terraform apply

# 2. If successful, test in staging
$ cd environments/staging
$ terraform apply

# 3. Finally, deploy to prod
$ cd environments/prod
$ terraform plan  # Extra careful review
$ terraform apply
```

#### Rule 8: Review Destroy Plans Carefully

**Always:**

```bash
# Generate destroy plan
$ terraform plan -destroy

# Read EVERY line
# Confirm with team
# Double-check environment

# Only then destroy
$ terraform destroy
```

#### Rule 9: Keep Terraform Updated

**Check versions:**

```bash
# Current version
$ terraform version
Terraform v1.9.0

# Check for updates
$ terraform version
# Visit: https://www.terraform.io/downloads
```

**Update providers:**

```bash
# Update to latest matching version
$ terraform init -upgrade
```

#### Rule 10: Document Your Infrastructure

**Create README.md:**

```markdown
# Production Infrastructure

## Overview
This Terraform configuration manages our production infrastructure on GCP.

## Prerequisites
- Terraform >= 1.9.0
- GCP Project: production-project-123
- Service Account with appropriate permissions

## Usage

### Initialize
terraform init

### Plan Changes
terraform plan

### Apply Changes
terraform apply

## Resources Managed
- Compute instances (web servers)
- Storage buckets (user data)
- Cloud SQL (application database)
- Load balancers

## Contacts
- Owner: DevOps Team
- Email: devops@company.com
```

---

### Common Mistakes and How to Avoid Them

#### Mistake 1: Forgetting to Run terraform init

**Error:**

```bash
$ terraform plan
╷
│ Error: Could not load plugin
│ Plugin reinitialization required. Please run "terraform init".
╵
```

**Solution:**

```bash
$ terraform init  # Always first!
```

#### Mistake 2: Non-Unique Resource Names

**Error:**

```bash
$ terraform apply
╷
│ Error: Error creating bucket: googleapi: Error 409: You already own this bucket.
╵
```

**Cause:**

```hcl
resource "google_storage_bucket" "data" {
  name = "my-bucket"  # This name exists somewhere
}
```

**Solution:**

```hcl
resource "google_storage_bucket" "data" {
  # Make it unique with timestamp or random suffix
  name = "my-company-data-${formatdate("YYYYMMDDhhmmss", timestamp())}"
}
```

#### Mistake 3: Hardcoding Credentials

**BAD:**

```hcl
provider "google" {
  credentials = "{\"type\": \"service_account\", \"private_key\": \"...\"}"
}
```

**GOOD:**

```hcl
provider "google" {
  credentials = file("~/.gcp/credentials.json")
}

# Or use environment variable
# export GOOGLE_APPLICATION_CREDENTIALS="path/to/key.json"
```

#### Mistake 4: Not Using .gitignore

**Must ignore:**

```bash
# .gitignore
.terraform/
*.tfstate
*.tfstate.backup
*.tfvars  # If contains secrets
```

#### Mistake 5: Manual State File Editing

**Never do this:**

```bash
$ vim terraform.tfstate  # DON'T!
```

**Instead:**

```bash
# Use Terraform commands to manage state
$ terraform state list
$ terraform state show resource_name
$ terraform state rm resource_name  # If needed
```

---

## Hands-On Exercise: Your First Real Infrastructure

Let's put everything together and create real infrastructure!

### Exercise: Create a Complete Application Environment

**What You'll Build:**

- Storage bucket for application data
- Storage bucket for backups
- Compute instance for web server
- Firewall rule to allow HTTP traffic

**Step 1: Create Project Directory**

```bash
mkdir terraform-first-app
cd terraform-first-app
```

**Step 2: Create main.tf**

```hcl
# main.tf

# ============================================================================
# Terraform and Provider Configuration
# ============================================================================
terraform {
  required_version = ">= 1.9.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.38"
    }
  }
}

provider "google" {
  project = "YOUR-PROJECT-ID-HERE"  # Change this!
  region  = "us-central1"
  zone    = "us-central1-a"
}

# ============================================================================
# Storage Buckets
# ============================================================================

# Application data bucket
resource "google_storage_bucket" "app_data" {
  name          = "YOUR-NAME-app-data-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  location      = "US"
  storage_class = "STANDARD"
  
  labels = {
    purpose     = "application-data"
    environment = "development"
    managed_by  = "terraform"
  }
  
  versioning {
    enabled = true
  }
}

# Backup bucket
resource "google_storage_bucket" "backups" {
  name          = "YOUR-NAME-backups-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  location      = "US"
  storage_class = "NEARLINE"  # Cheaper for backups
  
  labels = {
    purpose     = "backups"
    environment = "development"
    managed_by  = "terraform"
  }
  
  lifecycle_rule {
    condition {
      age = 30  # Delete backups older than 30 days
    }
    action {
      type = "Delete"
    }
  }
}

# ============================================================================
# Compute Instance
# ============================================================================

resource "google_compute_instance" "web_server" {
  name         = "web-server-dev"
  machine_type = "e2-small"
  zone         = "us-central1-a"
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }
  
  network_interface {
    network = "default"
    
    access_config {
      # Assigns external IP
    }
  }
  
  metadata = {
    environment = "development"
  }
  
  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl start nginx
    echo "<h1>Hello from Terraform!</h1>" > /var/www/html/index.html
  EOF
  
  labels = {
    purpose     = "web-server"
    environment = "development"
    managed_by  = "terraform"
  }
}

# ============================================================================
# Firewall Rule
# ============================================================================

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http-dev"
  network = "default"
  
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  
  source_ranges = ["0.0.0.0/0"]  # Allow from anywhere
  target_tags   = ["web-server"]
}

# ============================================================================
# Outputs
# ============================================================================

output "app_data_bucket_name" {
  description = "Name of the application data bucket"
  value       = google_storage_bucket.app_data.name
}

output "backup_bucket_name" {
  description = "Name of the backup bucket"
  value       = google_storage_bucket.backups.name
}

output "web_server_ip" {
  description = "External IP of web server"
  value       = google_compute_instance.web_server.network_interface[0].access_config[0].nat_ip
}

output "web_server_url" {
  description = "URL to access web server"
  value       = "http://${google_compute_instance.web_server.network_interface[0].access_config[0].nat_ip}"
}
```

**Step 3: Initialize Terraform**

```bash
$ terraform init

Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/google versions matching "~> 5.38"...
- Installing hashicorp/google v5.38.0...
- Installed hashicorp/google v5.38.0

Terraform has been successfully initialized!
```

**Step 4: Format the Code**

```bash
$ terraform fmt
main.tf
```

**Step 5: Validate Configuration**

```bash
$ terraform validate
Success! The configuration is valid.
```

**Step 6: Review the Plan**

```bash
$ terraform plan

Plan: 4 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + app_data_bucket_name = "your-name-app-data-20251026103000"
  + backup_bucket_name   = "your-name-backups-20251026103000"
  + web_server_ip        = (known after apply)
  + web_server_url       = (known after apply)
```

**Step 7: Create Infrastructure**

```bash
$ terraform apply

Do you want to perform these actions?
  Only 'yes' will be accepted to approve.

  Enter a value: yes

google_storage_bucket.app_data: Creating...
google_storage_bucket.backups: Creating...
google_compute_firewall.allow_http: Creating...
google_storage_bucket.app_data: Creation complete after 2s
google_storage_bucket.backups: Creation complete after 2s
google_compute_firewall.allow_http: Creation complete after 5s
google_compute_instance.web_server: Creating...
google_compute_instance.web_server: Still creating... [10s elapsed]
google_compute_instance.web_server: Creation complete after 15s

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

app_data_bucket_name = "your-name-app-data-20251026103000"
backup_bucket_name = "your-name-backups-20251026103000"
web_server_ip = "34.123.45.67"
web_server_url = "http://34.123.45.67"
```

**Step 8: Test Your Infrastructure**

```bash
# Visit the web server URL in your browser
# You should see: "Hello from Terraform!"

# Or use curl
$ curl http://34.123.45.67
<h1>Hello from Terraform!</h1>
```

**Step 9: Clean Up**

```bash
$ terraform destroy

Plan: 0 to add, 0 to change, 4 to destroy.

Do you really want to destroy all resources?
  Enter a value: yes

google_compute_instance.web_server: Destroying...
google_compute_instance.web_server: Destruction complete after 10s
google_compute_firewall.allow_http: Destroying...
google_storage_bucket.app_data: Destroying...
google_storage_bucket.backups: Destroying...
google_compute_firewall.allow_http: Destruction complete after 5s
google_storage_bucket.app_data: Destruction complete after 2s
google_storage_bucket.backups: Destruction complete after 2s

Destroy complete! Resources: 4 destroyed.
```

---

## Summary: What You've Mastered

### Section 2 Recap

**Part 1: HCL Syntax (15 minutes)**

- ✅ The three building blocks: Blocks, Arguments, Expressions
- ✅ Four main block types: terraform, provider, resource, nested blocks
- ✅ Five value types: strings, numbers, booleans, lists, maps
- ✅ Three expression types: references, operators, functions
- ✅ Complete real-world example combining everything

**Part 2: Six Essential Commands (15 minutes)**

- ✅ `terraform init` - Initialize project
- ✅ `terraform fmt` - Format code
- ✅ `terraform validate` - Check for errors
- ✅ `terraform plan` - Preview changes
- ✅ `terraform apply` - Create infrastructure
- ✅ `terraform destroy` - Delete infrastructure

**Part 3: Best Practices (5 minutes)**

- ✅ Ten golden rules for Terraform success
- ✅ Common mistakes and how to avoid them
- ✅ Hands-on exercise creating real infrastructure

---

## Course Completion: You're Now a Terraform Practitioner!

### What You Can Do Now

✅ **Understand Infrastructure as Code**

- Why manual management doesn't scale
- How IaC solves modern infrastructure challenges

✅ **Write Terraform Configuration**

- Use HCL syntax confidently
- Create complex resources with nested blocks
- Use variables and expressions

✅ **Manage Infrastructure Lifecycle**

- Initialize projects
- Plan and apply changes safely
- Destroy infrastructure when needed

✅ **Follow Best Practices**

- Version control infrastructure
- Protect state files
- Write maintainable code

### Your Next Steps

**Immediate Practice:**

1. Create different types of GCP resources
2. Experiment with variables and outputs
3. Build multi-resource projects
4. Practice the complete workflow

**Advanced Learning:**

- Modules (reusable infrastructure components)
- Remote state management
- Team collaboration workflows
- CI/CD integration
- Multiple environments (dev/staging/prod)
- Advanced providers (Kubernetes, AWS, Azure)

**Resources:**

- Terraform Documentation: https://www.terraform.io/docs
- Google Provider Docs: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- Terraform Registry: https://registry.terraform.io
- HashiCorp Learn: https://learn.hashicorp.com/terraform

---

## Quick Reference Sheet

### Essential Commands

```bash
terraform init          # Initialize project (always first)
terraform fmt           # Format code
terraform validate      # Check for errors
terraform plan          # Preview changes
terraform apply         # Create infrastructure
terraform destroy       # Delete infrastructure
terraform show          # Show current state
terraform state list    # List all resources
terraform output        # Show outputs
```

### HCL Syntax Cheat Sheet

```hcl
# Block
resource "type" "name" {
  argument = "value"
}

# String
name = "my-resource"

# Number
count = 3

# Boolean
enabled = true

# List
zones = ["zone-a", "zone-b"]

# Map
labels = {
  key = "value"
}

# Reference
network = google_compute_network.main.id

# Variable
name = var.environment

# Function
name = format("server-%03d", 1)

# Conditional
size = var.is_prod ? 100 : 50
```

### Workflow Checklist

- [ ] Initialize: `terraform init`
- [ ] Format: `terraform fmt`
- [ ] Validate: `terraform validate`
- [ ] Plan: `terraform plan`
- [ ] Review plan output
- [ ] Apply: `terraform apply`
- [ ] Type "yes" to confirm
- [ ] Verify infrastructure created

---

**Congratulations!** 

You've completed the comprehensive Terraform course. You now have the knowledge and skills to manage infrastructure as code professionally. Keep practicing, stay curious, and happy terraforming!