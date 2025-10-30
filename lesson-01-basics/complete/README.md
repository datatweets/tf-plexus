# Complete Terraform Example - Production Patterns

Comprehensive example demonstrating Terraform best practices and advanced concepts in a single configuration.

## What This Creates

```
┌─────────────────────────────────────────────────────┐
│              GCP Infrastructure                     │
│                                                     │
│  ┌──────────────────┐      ┌──────────────────┐     │
│  │  Storage Bucket  │      │  Compute VMs     │     │
│  │  • Versioning    │      │  • 2 instances   │     │
│  │  • Lifecycle     │      │  • Nginx web     │     │
│  │  • Labels        │      │  • Auto-restart  │     │
│  └──────────────────┘      │  • Labels        │     │
│                            └──────────────────┘     │
│                                                     │
│  Environment-aware: dev/staging/production          │
└─────────────────────────────────────────────────────┘
```

| Resource | Configuration |
|----------|---------------|
| **Storage Bucket** | Versioning • Lifecycle rules • Environment-specific class |
| **Compute Instances** | 2x VMs • Nginx • Environment-based sizing |
| **Machine Type** | Dev: n1-standard-2 • Staging: n1-standard-4 • Prod: n1-standard-8 |

**Cost:** ~$50-100/month (environment-dependent)

---

## Advanced Concepts Demonstrated

This example showcases Terraform features you'll use in production:

| Feature | Usage | Line Reference |
|---------|-------|----------------|
| **Terraform Block** | Version constraints | Lines 4-13 |
| **Variables** | Customizable inputs | Lines 27-44 |
| **Locals** | Computed values | Lines 49-68 |
| **Conditionals** | Environment logic | Lines 66-68, 90 |
| **Functions** | `formatdate()`, `merge()`, `file()` | Throughout |
| **Count** | Multiple instances | Line 116 |
| **Labels** | Resource organization | Lines 82-88, 151-158 |
| **Dynamic Blocks** | Conditional nested blocks | Lines 143-149 |
| **Outputs** | Export values | outputs.tf |

---

## Quick Start

### 1. Prerequisites

```bash
# Verify tools installed
terraform version
gcloud --version

# Authenticate with GCP
gcloud auth application-default login
```

**Required:**
- GCP project with billing enabled
- SSH public key at `~/.ssh/id_rsa.pub`

### 2. Update Configuration

Edit `main.tf` line 19:

```hcl
provider "google" {
  project = "YOUR-PROJECT-ID"  # ← Change this
  region  = "us-central1"
  zone    = "us-central1-a"
}
```

### 3. Customize (Optional)

Modify variables at the command line:

```bash
# Deploy 3 instances in staging environment
terraform apply -var="environment=staging" -var="instance_count=3"

# Deploy for production team
terraform apply -var="environment=production" -var="team=platform"
```

### 4. Deploy

```bash
# Initialize
terraform init

# Preview (see what will be created)
terraform plan

# Deploy with default values (dev environment, 2 instances)
terraform apply

# Or specify environment
terraform apply -var="environment=staging"
```

### 5. Verify & Access

```bash
# View outputs
terraform output

# List created VMs
gcloud compute instances list

# SSH into first instance
gcloud compute ssh engineering-dev-app-01 --zone=us-central1-a

# View Nginx webpage (if external IP exists)
# Get IP from console or terraform output
curl http://EXTERNAL_IP
```

### 6. Clean Up

```bash
terraform destroy
```

---

## Environment Behavior

The configuration adapts automatically based on `environment` variable:

| Setting | Dev | Staging | Production |
|---------|-----|---------|------------|
| **Machine Type** | n1-standard-2 | n1-standard-4 | n1-standard-8 |
| **Storage Class** | NEARLINE | NEARLINE | STANDARD |
| **Bucket Location** | us-central1 | us-central1 | US (multi-region) |
| **Versioning** | Disabled | Disabled | Enabled |
| **Lifecycle Days** | 90 days | 90 days | 365 days |
| **Disk Size** | 50 GB | 50 GB | 100 GB |
| **External IP** | No | No | Yes |
| **Auto-restart** | No | No | Yes |
| **Preemptible** | Yes | Yes | No |
| **Force Destroy** | Yes | Yes | No |

---

## File Structure

```
complete/
├── main.tf           # Main configuration (all resources)
├── outputs.tf        # Output definitions
├── startup.sh        # VM initialization script
├── .gitignore        # Ignores sensitive files
└── README.md         # This file
```

### main.tf Sections

```hcl
# 1. Terraform Block (lines 4-13)
terraform {
  required_version = ">= 1.9.0"
  required_providers {...}
}

# 2. Provider (lines 18-22)
provider "google" {...}

# 3. Variables (lines 27-44)
variable "environment" {...}
variable "team" {...}
variable "instance_count" {...}

# 4. Locals (lines 49-68)
locals {
  name_prefix = "${var.team}-${var.environment}"
  common_labels = {...}
  machine_type = (ternary condition)
}

# 5. Storage Bucket (lines 73-110)
resource "google_storage_bucket" "data" {...}

# 6. Compute Instances (lines 115-165)
resource "google_compute_instance" "app" {...}
```

---

## Key Learning Points

### 1. Conditional Logic

```hcl
# Ternary operator for conditionals
machine_type = var.environment == "production" ? "n1-standard-8" : "n1-standard-2"

# Boolean conditions
versioning {
  enabled = var.environment == "production"
}
```

### 2. Count for Multiple Resources

```hcl
resource "google_compute_instance" "app" {
  count = var.instance_count  # Creates N instances
  name  = format("app-%02d", count.index + 1)  # app-01, app-02...
}
```

### 3. Local Values

```hcl
locals {
  name_prefix = "${var.team}-${var.environment}"
  common_labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}
```

### 4. Functions

```hcl
# File reading
metadata = {
  startup-script = file("startup.sh")
}

# Date formatting
created_at = formatdate("YYYY-MM-DD", timestamp())

# Map merging
labels = merge(local.common_labels, { extra = "value" })

# String formatting
name = format("app-%02d", count.index + 1)
```

### 5. Outputs with Expressions

```hcl
# List all instance names
output "instance_names" {
  value = google_compute_instance.app[*].name
}

# For expression creating a map
output "instance_details" {
  value = {
    for instance in google_compute_instance.app :
    instance.name => {
      zone = instance.zone
      machine_type = instance.machine_type
    }
  }
}
```

---

## Common Operations

```bash
# Format code
terraform fmt

# Validate configuration
terraform validate

# Show current state
terraform show

# List resources
terraform state list

# Get specific output
terraform output bucket_name
terraform output -json instance_details

# Target specific resource
terraform apply -target=google_storage_bucket.data

# Replace a resource (recreate)
terraform apply -replace=google_compute_instance.app[0]
```

---

## Troubleshooting

**Error: "project does not exist"**
```bash
# Update project ID in main.tf line 19
# Verify project exists
gcloud projects list
```

**Error: "SSH key not found"**
```bash
# Generate SSH key if needed
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# Or comment out line 153 in main.tf
```

**Error: "quota exceeded"**
```bash
# Reduce instance_count
terraform apply -var="instance_count=1"

# Or change machine_type to smaller size
```

**Want to skip external IP error?**
```bash
# Comment out lines 143-149 (dynamic access_config block)
```

---

## What You'll Learn

- ✅ Structuring production-ready Terraform code
- ✅ Using variables for flexibility
- ✅ Computing values with locals
- ✅ Environment-specific logic with conditionals
- ✅ Creating multiple resources with count
- ✅ Organizing resources with labels
- ✅ Using Terraform functions
- ✅ Exporting data with outputs
- ✅ Dynamic nested blocks

---

## Experiments to Try

1. **Change Environment:** Deploy with `environment=production` and observe differences
2. **Scale Up:** Set `instance_count=5` to create more instances
3. **Custom Team:** Use `-var="team=yourname"` and see naming changes
4. **Add Output:** Add a new output for external IPs
5. **Modify Labels:** Add custom labels to resources
6. **Update Lifecycle:** Change retention days for different environments

---

## Next Steps

**You're ready for:**
- **Lesson 2:** State management and meta-arguments
- **Lesson 3:** Advanced types and functions (builds on this)
- **Lesson 4:** Modules (refactor this into reusable modules)

**Challenges:**
- Convert this into separate modules (networking, compute, storage)
- Add firewall rules for HTTP access
- Implement different regions per environment
- Add Cloud SQL database resource
