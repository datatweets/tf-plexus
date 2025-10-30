# Data Sources - Hands-On Example

Query and reference existing GCP resources dynamically without hardcoding values.

## What You'll Learn

- ✅ **Data sources** - Query existing cloud resources
- ✅ **Zone discovery** - Find available zones automatically
- ✅ **Image lookup** - Use latest OS images
- ✅ **Project metadata** - Get current project information
- ✅ **Network references** - Use existing networks
- ✅ **Dynamic distribution** - Distribute resources across discovered zones

## What Gets Created

- **3 Debian instances** distributed across all available zones in region
- **1 Ubuntu instance** using latest Ubuntu image
- **1 Data disk** in first available zone
- All using **dynamically discovered** zones and images!

## Quick Start

```bash
cd lesson-03/data-source/
cp terraform.tfvars.example terraform.tfvars
# Edit project_id in terraform.tfvars
terraform init
terraform plan  # Notice the data sources being queried!
terraform apply
```

## Understanding Data Sources

### Data Sources vs Resources

| Resources | Data Sources |
|-----------|--------------|
| **Create** infrastructure | **Read** existing infrastructure |
| `resource "google_compute_instance"` | `data "google_compute_instance"` |
| Managed by Terraform | Already exists in cloud |
| Can modify/destroy | Read-only |

### Example: Zone Discovery

```hcl
# Query GCP for available zones
data "google_compute_zones" "available" {
  region = "us-west1"
}

# Use discovered zones
resource "google_compute_instance" "server" {
  zone = data.google_compute_zones.available.names[0]
}
```

## Key Concepts

### 1. Automatic Zone Discovery

**Without data sources (hardcoded):**
```hcl
zone = "us-west1-a"  # What if this zone is down?
```

**With data sources (dynamic):**
```hcl
data "google_compute_zones" "available" {
  region = "us-west1"
  status = "UP"
}

zone = element(data.google_compute_zones.available.names, count.index)
```

### 2. Latest Image Lookup

**Without data sources:**
```hcl
image = "debian-11-bullseye-v20231212"  # Gets outdated!
```

**With data sources:**
```hcl
data "google_compute_image" "debian" {
  family = "debian-11"
  project = "debian-cloud"
}

image = data.google_compute_image.debian.self_link  # Always latest!
```

### 3. Round-Robin Distribution

```hcl
# Distribute 3 servers across discovered zones
count = 3
zone = element(data.google_compute_zones.available.names, count.index)

# Server 0 → zone 0
# Server 1 → zone 1
# Server 2 → zone 2
```

## View Discovered Data

**Before applying, see what will be discovered:**

```bash
terraform plan

# You'll see:
# data.google_compute_zones.available: Reading...
# data.google_compute_image.debian: Reading...
# data.google_compute_image.ubuntu: Reading...
```

**After applying:**

```bash
terraform output discovered_zones
# ["us-west1-a", "us-west1-b", "us-west1-c"]

terraform output debian_image_info
# {
#   "name" = "debian-11-bullseye-v20240110"
#   "family" = "debian-11"
# }
```

## Experiments

### Experiment 1: Change Region

```hcl
region = "us-east1"
```

Result: Discovers zones in us-east1, servers distributed there

### Experiment 2: More Instances

```hcl
instance_count = 6
```

Result: 6 servers distributed round-robin across discovered zones

### Experiment 3: Use Different Image Family

```hcl
# In main.tf, change:
family = "debian-12"
```

Result: Uses latest Debian 12 instead of Debian 11

## Outputs Explained

```bash
$ terraform output

discovered_zones = [
  "us-west1-a",
  "us-west1-b",
  "us-west1-c",
]

server_distribution = {
  "data-source-demo-0" = {
    "external_ip" = "34.168.1.10"
    "zone" = "us-west1-a"
  }
  "data-source-demo-1" = {
    "external_ip" = "34.168.1.11"
    "zone" = "us-west1-b"
  }
  "data-source-demo-2" = {
    "external_ip" = "34.168.1.12"
    "zone" = "us-west1-c"
  }
}

zone_distribution = {
  "us-west1-a" = 1
  "us-west1-b" = 1
  "us-west1-c" = 1
}
```

## Benefits

✅ **No hardcoding** - Adapts to any region
✅ **Always current** - Uses latest images automatically  
✅ **Resilient** - Only uses available zones
✅ **Flexible** - Works across different GCP projects
✅ **Maintainable** - No manual updates needed

## Cleanup

```bash
terraform destroy
```

## Common Data Sources

```hcl
# Zones
data "google_compute_zones" "available" { }

# Images  
data "google_compute_image" "debian" { }

# Networks
data "google_compute_network" "vpc" { }

# Project info
data "google_project" "current" { }

# Regions
data "google_compute_regions" "available" { }

# Subnetworks
data "google_compute_subnetwork" "subnet" { }
```

## Next Steps

- ✅ **Completed**: Understanding data sources
- ⏭️ **Up next**: [output/](../output/) - Master output expressions
- ⏭️ **Then**: [complete/](../complete/) - Production-ready example

---

**Example Complete!** 🎉

You now understand how to query and use existing cloud resources with data sources!
