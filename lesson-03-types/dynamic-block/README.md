# Dynamic Blocks - Hands-On Example

This example demonstrates how to use **dynamic blocks** to generate repeated nested blocks programmatically, avoiding repetitive code.

## 📚 What You'll Learn

- ✅ **Dynamic block syntax** - `dynamic` blocks with `for_each`
- ✅ **Disk attachment** - Attach multiple disks to a VM dynamically
- ✅ **Firewall rules** - Create multiple rules in one block
- ✅ **Accessing values** - Using `block_name.key` and `block_name.value`
- ✅ **Nested dynamic blocks** - Dynamic blocks within dynamic blocks
- ✅ **Real-world patterns** - Production-ready examples

## 🏗️ What Gets Created

- **1 VM instance** with 3 dynamically attached data disks
- **3 Data disks** (10GB standard, 50GB balanced, 100GB SSD)
- **1 Firewall rule** with 3 ports (80, 443, 8080) using dynamic blocks
- **Optional multi-NIC instance** demonstrating nested dynamic blocks

## 📋 Prerequisites

- GCP account with an active project
- `gcloud` CLI installed and authenticated
- Terraform >= 1.9 installed
- Project billing enabled

## 🚀 Quick Start

### Step 1: Set Up Your Project

```bash
# Navigate to this directory
cd lesson-03/dynamic-block/

# Copy the example tfvars file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your GCP project ID
nano terraform.tfvars
```

**Edit `terraform.tfvars`:**

```hcl
project_id = "your-actual-gcp-project-id"  # REQUIRED
```

### Step 2: Authenticate with GCP

```bash
# Login to GCP
gcloud auth application-default login

# Set your project
gcloud config set project your-actual-gcp-project-id
```

### Step 3: Initialize and Apply

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Create the resources
terraform apply
```

### Step 4: Verify Disk Attachments

```bash
# SSH into the instance
gcloud compute ssh dynamic-block-demo --zone=us-west1-a

# List attached disks
lsblk

# You should see:
# - Boot disk (sda)
# - Three data disks (sdb, sdc, sdd)

# Exit SSH
exit
```

## 🔍 Understanding Dynamic Blocks

### The Problem: Repetitive Code

**Without dynamic blocks:**

```hcl
resource "google_compute_instance" "server" {
  name = "my-server"
  
  # First disk
  attached_disk {
    source = google_compute_disk.disk1.name
    mode   = "READ_WRITE"
  }
  
  # Second disk (copy-paste!)
  attached_disk {
    source = google_compute_disk.disk2.name
    mode   = "READ_WRITE"
  }
  
  # Third disk (copy-paste again!)
  attached_disk {
    source = google_compute_disk.disk3.name
    mode   = "READ_WRITE"
  }
}
```

**Problems:**
- ❌ Repetitive code
- ❌ Hard to maintain
- ❌ Can't make number of disks flexible
- ❌ Need 10 disks? Copy-paste 10 times!

### The Solution: Dynamic Blocks

**With dynamic blocks:**

```hcl
resource "google_compute_instance" "server" {
  name = "my-server"
  
  # Dynamic block generates multiple attached_disk blocks
  dynamic "attached_disk" {
    for_each = var.disks
    
    content {
      source = google_compute_disk.data_disks[attached_disk.key].name
      mode   = attached_disk.value["mode"]
    }
  }
}
```

**Benefits:**
- ✅ One block definition for all disks
- ✅ Flexible - add/remove by changing data
- ✅ Maintainable - update in one place
- ✅ Scalable - works with 3 or 300 disks

### Dynamic Block Syntax

```hcl
dynamic "BLOCK_NAME" {
  for_each = COLLECTION
  
  content {
    # Block contents using BLOCK_NAME.key and BLOCK_NAME.value
  }
}
```

**Components:**

1. **`dynamic "attached_disk"`** - Declares which block type to generate
2. **`for_each = var.disks`** - Collection to iterate over
3. **`content { }`** - Template for each generated block
4. **`attached_disk.key`** - Current item's key (map key or list index)
5. **`attached_disk.value`** - Current item's value

### Example: Disk Configuration

**Input data:**

```hcl
disks = {
  data-disk-1 = {
    type = "pd-standard"
    size = 10
    mode = "READ_WRITE"
  }
  data-disk-2 = {
    type = "pd-balanced"
    size = 50
    mode = "READ_WRITE"
  }
  data-disk-3 = {
    type = "pd-ssd"
    size = 100
    mode = "READ_ONLY"
  }
}
```

**Dynamic block:**

```hcl
dynamic "attached_disk" {
  for_each = var.disks
  
  content {
    source = google_compute_disk.data_disks[attached_disk.key].name
    mode   = attached_disk.value["mode"]
  }
}
```

**What Terraform generates at runtime:**

```hcl
attached_disk {
  source = google_compute_disk.data_disks["data-disk-1"].name
  mode   = "READ_WRITE"
}

attached_disk {
  source = google_compute_disk.data_disks["data-disk-2"].name
  mode   = "READ_WRITE"
}

attached_disk {
  source = google_compute_disk.data_disks["data-disk-3"].name
  mode   = "READ_ONLY"
}
```

## 🧪 Experiments to Try

### Experiment 1: Add More Disks

```hcl
# In terraform.tfvars
disks = {
  data-disk-1 = {
    type = "pd-standard"
    size = 10
    mode = "READ_WRITE"
  }
  data-disk-2 = {
    type = "pd-ssd"
    size = 50
    mode = "READ_WRITE"
  }
  # Add new disks
  backup-disk = {
    type = "pd-standard"
    size = 200
    mode = "READ_WRITE"
  }
  logs-disk = {
    type = "pd-balanced"
    size = 30
    mode = "READ_WRITE"
  }
}
```

```bash
terraform plan
# Notice: 2 new disks will be created and attached
```

### Experiment 2: Change Disk Modes

```hcl
# Make disk read-only
disks = {
  data-disk-3 = {
    type = "pd-ssd"
    size = 100
    mode = "READ_ONLY"  # Changed from READ_WRITE
  }
}
```

```bash
terraform apply
# Disk will be reattached in read-only mode
```

### Experiment 3: Modify Firewall Ports

```hcl
# In terraform.tfvars
firewall_rules = [
  { protocol = "tcp", port = 80 },
  { protocol = "tcp", port = 443 },
  { protocol = "tcp", port = 22 },    # Add SSH
  { protocol = "tcp", port = 3306 },  # Add MySQL
  { protocol = "tcp", port = 5432 }   # Add PostgreSQL
]
```

```bash
terraform apply
# Firewall rule will be updated to allow all 5 ports
```

### Experiment 4: Enable Multi-NIC Instance

```hcl
# In terraform.tfvars
create_multi_nic = true

network_interfaces = [
  {
    network     = "default"
    subnetwork  = ""
    external_ip = true
  },
  {
    network     = "default"
    subnetwork  = ""
    external_ip = false
  }
]
```

```bash
terraform apply
# Creates instance with 2 network interfaces
```

## 📊 Understanding the Output

**After `terraform apply`:**

```bash
$ terraform output

instance_name = "dynamic-block-demo"
instance_ip = "34.168.123.45"

attached_disks = {
  "data-disk-1" = {
    "id" = "projects/.../disks/data-disk-1"
    "mode" = "READ_WRITE"
    "size" = 10
    "type" = "pd-standard"
  }
  "data-disk-2" = {
    "id" = "projects/.../disks/data-disk-2"
    "mode" = "READ_WRITE"
    "size" = 50
    "type" = "pd-balanced"
  }
  "data-disk-3" = {
    "id" = "projects/.../disks/data-disk-3"
    "mode" = "READ_ONLY"
    "size" = 100
    "type" = "pd-ssd"
  }
}

disk_count = 3

firewall_rules = {
  "name" = "dynamic-block-demo-allow-ports"
  "ports" = [80, 443, 8080]
}
```

## 🔍 Verifying Disk Attachments

**SSH into the instance:**

```bash
gcloud compute ssh dynamic-block-demo --zone=us-west1-a
```

**List all block devices:**

```bash
lsblk
```

**Expected output:**

```
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   20G  0 disk 
└─sda1   8:1    0   20G  0 part /
sdb      8:16   0   10G  0 disk    # data-disk-1
sdc      8:32   0   50G  0 disk    # data-disk-2
sdd      8:48   0  100G  1 disk    # data-disk-3 (READ_ONLY = 1)
```

**Check disk details:**

```bash
sudo fdisk -l
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
# Check instances
gcloud compute instances list

# Check disks
gcloud compute disks list

# Check firewall rules
gcloud compute firewall-rules list --filter="name:dynamic-block-demo"
```

## 📝 Key Takeaways

### Dynamic Block Patterns

| Use Case | Pattern |
|----------|---------|
| **Map iteration** | `for_each = var.map_variable` |
| **List iteration** | `for_each = var.list_variable` |
| **Conditional block** | `for_each = condition ? [1] : []` |
| **Access key** | `block_name.key` |
| **Access value** | `block_name.value` |

### When to Use Dynamic Blocks

✅ **Use dynamic blocks when:**
- Creating multiple similar nested blocks
- Number of blocks is variable
- Configuration is data-driven
- Avoiding repetitive code

❌ **Don't use dynamic blocks when:**
- Only creating 1-2 blocks (just write them out)
- Block contents are very different
- Makes code harder to read

### Best Practices

1. **Use meaningful names** - `attached_disk`, not `ad` or `x`
2. **Validate input data** - Use validation blocks
3. **Keep it simple** - Don't over-nest dynamic blocks
4. **Document** - Explain what each dynamic block generates
5. **Test variations** - Ensure it works with 0, 1, and many items

### Common Pitfalls

❌ **Empty collection** - `for_each` over empty map/list generates nothing
✅ **Solution** - This is often desired for conditional blocks

❌ **Wrong accessor** - Using `.key` when you need `.value`
✅ **Solution** - Remember: map has both, list uses `.value` for item

❌ **Nested too deep** - Dynamic blocks within dynamic blocks within dynamic blocks
✅ **Solution** - Keep nesting to 1-2 levels maximum

## 🎯 Next Steps

- ✅ **Completed**: Understanding dynamic blocks
- ⏭️ **Up next**: [conditional-expression/](../conditional-expression/) - Conditional resource creation
- ⏭️ **Then**: [data-source/](../data-source/) - Query existing resources

## 🐛 Troubleshooting

### Error: "Disk already attached"

**Solution:** Destroy and recreate:

```bash
terraform destroy
terraform apply
```

### Error: "Invalid disk mode"

**Solution:** Mode must be "READ_WRITE" or "READ_ONLY":

```hcl
disks = {
  my-disk = {
    mode = "READ_WRITE"  # Not "RW" or "read-write"
  }
}
```

### Disks not showing in lsblk

**Solution:** They may need formatting:

```bash
# List unformatted disks
sudo lsblk -f

# Format a disk (WARNING: Destroys data!)
sudo mkfs.ext4 /dev/sdb

# Mount it
sudo mkdir -p /mnt/data
sudo mount /dev/sdb /mnt/data
```

## 📚 Related Examples

- [types/](../types/) - Terraform data types
- [conditional-expression/](../conditional-expression/) - Conditional logic
- [complete/](../complete/) - Production-ready combination

---

**Example Complete!** 🎉

You now understand how to use dynamic blocks to generate repeated nested blocks programmatically!
