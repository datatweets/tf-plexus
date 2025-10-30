# Terraform Types and Values - Hands-On Example

This example demonstrates all Terraform data types through practical GCP resource creation.

## 📚 What You'll Learn

- ✅ **Primitive types**: string, number, bool
- ✅ **Collection types**: list, map
- ✅ **Complex types**: object, nested maps
- ✅ **Type usage**: In variables, locals, and resources
- ✅ **Type manipulation**: Accessing, iterating, and transforming typed data

## 🏗️ What Gets Created

- **1 Compute instance** - Demonstrates string, number, and bool types
- **3 Firewall rules** - Demonstrates list iteration with count
- **3 Data disks** - Demonstrates map iteration with for_each
- **Multiple IP addresses** - Demonstrates nested map access
- **1 Typed server** (optional) - Demonstrates object type with validation

## 📋 Prerequisites

- GCP account with an active project
- `gcloud` CLI installed and authenticated
- Terraform >= 1.9 installed
- Project billing enabled

## 🚀 Quick Start

### Step 1: Set Up Your Project

```bash
# Clone or navigate to this directory
cd lesson-03/types/

# Copy the example tfvars file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your GCP project ID
# Required: Set your project_id
nano terraform.tfvars
```

**Edit `terraform.tfvars`:**

```hcl
project_id = "your-actual-gcp-project-id"  # REQUIRED
environment = "dev"                         # Optional: dev or prod
```

### Step 2: Authenticate with GCP

```bash
# Login to GCP
gcloud auth application-default login

# Verify your project
gcloud config get-value project

# Set your project (if needed)
gcloud config set project your-actual-gcp-project-id
```

### Step 3: Initialize Terraform

```bash
# Initialize Terraform (downloads Google provider)
terraform init
```

**Expected output:**

```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/google versions matching "~> 5.0"...
- Installing hashicorp/google v5.x.x...

Terraform has been successfully initialized!
```

### Step 4: Review the Execution Plan

```bash
# See what Terraform will create
terraform plan
```

**Review the plan carefully!** You should see:

- ✅ 1 compute instance (`google_compute_instance.demo_server`)
- ✅ 3 firewall rules (`google_compute_firewall.allow_ports`)
- ✅ 3 data disks (`google_compute_disk.data_disks`)
- ✅ Multiple IP addresses (`google_compute_address.regional_ips`)
- ✅ 1 typed server (`google_compute_instance.typed_server`)

### Step 5: Apply the Configuration

```bash
# Create the resources
terraform apply

# Type 'yes' when prompted
```

### Step 6: Explore the Outputs

After apply completes, examine the outputs demonstrating different types:

```bash
# View all outputs
terraform output

# View specific outputs
terraform output instance_name           # String
terraform output disk_count             # Number
terraform output has_external_ip        # Bool
terraform output disk_names             # List
terraform output disk_configurations    # Map
terraform output server_summary         # Object
```

## 📊 Understanding the Types

### String Type Examples

**In variables.tf:**

```hcl
variable "project_id" {
  type        = string
  description = "GCP Project ID"
}
```

**In main.tf:**

```hcl
resource "google_compute_instance" "demo_server" {
  name = var.instance_name  # String variable
  zone = var.zone           # String variable
}
```

**In outputs.tf:**

```hcl
output "instance_name" {
  value = google_compute_instance.demo_server.name  # String output
}
```

### Number Type Examples

**In variables.tf:**

```hcl
variable "disk_size" {
  type    = number
  default = 20
}
```

**In main.tf:**

```hcl
boot_disk {
  initialize_params {
    size = local.disk_size_gb  # Number value
  }
}
```

**In outputs.tf:**

```hcl
output "disk_count" {
  value = length(var.disk_configs)  # Number output
}
```

### Bool Type Examples

**In variables.tf:**

```hcl
variable "assign_external_ip" {
  type    = bool
  default = true
}
```

**In main.tf:**

```hcl
dynamic "access_config" {
  for_each = var.assign_external_ip ? [1] : []  # Bool in conditional
  content {
    # Empty block for ephemeral IP
  }
}
```

### List Type Examples

**In variables.tf:**

```hcl
variable "allowed_ports" {
  type    = list(number)
  default = [80, 443, 8080]
}
```

**In main.tf:**

```hcl
resource "google_compute_firewall" "allow_ports" {
  count = length(var.allowed_ports)  # Iterate over list

  allow {
    ports = [tostring(var.allowed_ports[count.index])]  # Access list element
  }
}
```

### Map Type Examples

**In variables.tf:**

```hcl
variable "disk_configs" {
  type = map(object({
    type = string
    size = number
  }))
  default = {
    small-disk  = { type = "pd-standard", size = 10 }
    medium-disk = { type = "pd-balanced", size = 50 }
  }
}
```

**In main.tf:**

```hcl
resource "google_compute_disk" "data_disks" {
  for_each = var.disk_configs  # Iterate over map

  name = each.key         # Map key
  type = each.value.type  # Map value property
  size = each.value.size
}
```

### Object Type Examples

**In variables.tf:**

```hcl
variable "typed_config" {
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

**In main.tf:**

```hcl
resource "google_compute_instance" "typed_server" {
  name = var.typed_config.name  # Access object property

  metadata = {
    regions = join(",", var.typed_config.regions)  # Use object's list
  }
}
```

## 🧪 Experiments to Try

### Experiment 1: Change Environment

```hcl
# In terraform.tfvars
environment = "prod"
```

```bash
terraform plan
# Notice machine type changes to "e2-standard-4"
```

### Experiment 2: Add More Ports

```hcl
# In terraform.tfvars
allowed_ports = [80, 443, 8080, 3000, 5000]
```

```bash
terraform plan
# Notice 5 firewall rules will be created
```

### Experiment 3: Modify Disk Configurations

```hcl
# In terraform.tfvars
disk_configs = {
  tiny-disk = {
    type = "pd-standard"
    size = 10
  }
  huge-disk = {
    type = "pd-ssd"
    size = 500
  }
}
```

```bash
terraform plan
# Notice old disks will be destroyed, new ones created
```

### Experiment 4: Disable External IP

```hcl
# In terraform.tfvars
assign_external_ip = false
```

```bash
terraform apply
# Instance will have no external IP
# Output "connection_command" will show IAP tunneling message
```

### Experiment 5: Change Region Group

```hcl
# In terraform.tfvars
region_group = "europe"
```

```bash
terraform plan
# IP addresses will be created in European regions
```

## 🔍 Understanding the Output

**After `terraform apply`, check the outputs:**

### String Outputs

```bash
$ terraform output instance_name
"types-demo-server"

$ terraform output instance_zone
"us-west1-a"
```

### Number Outputs

```bash
$ terraform output disk_count
3

$ terraform output total_disk_size_gb
160
```

### Bool Outputs

```bash
$ terraform output has_external_ip
true

$ terraform output monitoring_enabled
false
```

### List Outputs

```bash
$ terraform output disk_names
[
  "small-disk",
  "medium-disk",
  "large-disk",
]

$ terraform output allowed_ports
[
  80,
  443,
  8080,
]
```

### Map Outputs

```bash
$ terraform output disk_details
{
  "small-disk" = {
    "id" = "projects/.../disks/small-disk"
    "size" = 10
    "type" = "pd-standard"
    "zone" = "us-west1-a"
  }
  # ... more disks
}
```

### Object Outputs

```bash
$ terraform output server_summary
{
  "name" = "types-demo-server"
  "zone" = "us-west1-a"
  "machine_type" = "e2-micro"
  "has_external_ip" = true
  "external_ip" = "34.168.123.45"
  "internal_ip" = "10.138.0.2"
  # ... more properties
}
```

## 🧹 Cleanup

When you're done exploring:

```bash
# Destroy all resources
terraform destroy

# Type 'yes' when prompted
```

**Verify deletion:**

```bash
# Check compute instances
gcloud compute instances list

# Check disks
gcloud compute disks list

# Check firewall rules
gcloud compute firewall-rules list --filter="name~^allow-port-"
```

## 📝 Key Takeaways

### Type Usage Patterns

| Type | Used For | Access Pattern |
|------|----------|----------------|
| **String** | Names, IDs, text | Direct: `var.name` |
| **Number** | Counts, sizes, ports | Direct: `var.count` |
| **Bool** | Flags, conditionals | Conditional: `var.flag ? a : b` |
| **List** | Ordered collections | Index: `var.list[0]` or Iterate: `count` |
| **Map** | Key-value pairs | Key: `var.map["key"]` or Iterate: `for_each` |
| **Object** | Structured data | Property: `var.obj.property` |

### When to Use Each Type

✅ **string** - Names, IDs, zones, regions, text  
✅ **number** - Sizes, counts, ports, numbers  
✅ **bool** - Enable/disable flags, true/false choices  
✅ **list** - Multiple items of same type, ordered  
✅ **map** - Key-value lookups, flexible collections  
✅ **object** - Strict structured data with validation

### Best Practices

1. **Use type constraints** - Always specify `type =` in variables
2. **Add validation** - Use `validation` blocks for input checking
3. **Use objects for structure** - When data has a specific shape
4. **Use maps for flexibility** - When keys aren't known in advance
5. **Use lists for iteration** - When order matters
6. **Default values** - Provide sensible defaults when possible

## 🎯 Next Steps

- ✅ **Completed**: Understanding Terraform types
- ⏭️ **Up next**: [dynamic-block/](../dynamic-block/) - Dynamic block generation
- ⏭️ **Then**: [conditional-expression/](../conditional-expression/) - Conditional logic

## 🐛 Troubleshooting

### Error: "project: required field is not set"

**Solution:** Set your project_id in `terraform.tfvars`:

```hcl
project_id = "your-actual-gcp-project-id"
```

### Error: "Invalid value for variable"

**Solution:** Check validation constraints in `variables.tf`. For example:

- `environment` must be "dev" or "prod"
- `region_group` must be "americas", "europe", or "apac"
- `disk_size` must be between 10 and 1000

### Error: "Quota exceeded"

**Solution:** You may be trying to create too many resources. Reduce:

```hcl
# In terraform.tfvars
allowed_ports = [80]  # Create only 1 firewall rule instead of 3
```

## 📚 Related Examples

- [dynamic-block/](../dynamic-block/) - Generate repeated nested blocks
- [conditional-expression/](../conditional-expression/) - Conditional resource creation
- [data-source/](../data-source/) - Query existing resources
- [complete/](../complete/) - Production-ready combination

---

**Example Complete!** 🎉

You now understand all Terraform data types and how to use them effectively!
