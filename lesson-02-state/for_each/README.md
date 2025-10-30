# for_each Meta-Argument Example

This example demonstrates the `for_each` meta-argument for creating resources with meaningful keys instead of numeric indices. This example creates a VPC network with subnets and VMs in multiple regions.

## What You'll Learn

- Using `for_each` with maps for complex resource creation
- Working with `each.key` and `each.value`
- Creating dependent resources with `for_each`
- Using `self_link` for unambiguous resource references
- Managing dependencies with `depends_on`
- Lifecycle meta-arguments (prevent_destroy, create_before_destroy, ignore_changes)

## Prerequisites

- Terraform installed (>= 1.9)
- Google Cloud project with billing enabled
- `gcloud` CLI authenticated

## Setup Instructions

### Step 1: Configure Your Project

Copy the example tfvars file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set your project ID.

### Step 2: Enable Required APIs

```bash
gcloud services enable compute.googleapis.com
```

### Step 3: Initialize Terraform

```bash
terraform init
```

### Step 4: Review the Plan

```bash
terraform plan
```

Notice how resources are identified by meaningful keys like `["iowa"]`, `["virginia"]`, `["singapore"]` instead of `[0]`, `[1]`, `[2]`.

### Step 5: Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted.

## Understanding the Code

### for_each with Maps

```hcl
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
    # ...
  }
}

resource "google_compute_subnetwork" "this" {
  for_each = var.subnets
  
  name          = each.key               # "iowa"
  region        = each.value.region      # "us-central1"
  ip_cidr_range = each.value.ip_cidr_range  # "192.168.1.0/24"
}
```

### Using each.key and each.value

- **`each.key`**: The map key ("iowa", "virginia", "singapore")
- **`each.value`**: The complete object for that key

### Cross-referencing for_each Resources

```hcl
resource "google_compute_instance" "vm" {
  for_each = var.subnets
  
  name = "vm-${each.key}"
  
  network_interface {
    # Reference subnet with same key!
    subnetwork = google_compute_subnetwork.this[each.key].self_link
  }
}
```

### Using self_link

Always use `self_link` for resource references in Google Cloud:

```hcl
network = google_compute_network.this.self_link
# Not: network = google_compute_network.this.name
```

Benefits:
- ✅ Unambiguous reference
- ✅ Works across projects and regions
- ✅ More robust
- ✅ Google Cloud best practice

## Exploring Resources

### List all resources

```bash
terraform state list
```

You'll see:
```
google_compute_network.this
google_compute_subnetwork.this["iowa"]
google_compute_subnetwork.this["singapore"]
google_compute_subnetwork.this["virginia"]
google_compute_instance.vm["iowa"]
google_compute_instance.vm["singapore"]
google_compute_instance.vm["virginia"]
```

### Show specific resource

```bash
terraform state show 'google_compute_subnetwork.this["iowa"]'
```

### View outputs

```bash
terraform output
terraform output vm_details
terraform output ssh_commands
```

## Adding/Removing Regions

### Add a new region

Edit `terraform.tfvars`:

```hcl
subnets = {
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
  "london" = {
    region        = "europe-west2"
    ip_cidr_range = "192.168.4.0/24"
  }
}
```

Run plan:
```bash
terraform plan
```

Only the new "london" resources will be added! Existing ones remain untouched.

### Remove a region

Remove "virginia" from the map and run plan:
```bash
terraform plan
```

Only "virginia" resources will be destroyed. "iowa" and "singapore" remain intact!

**This is the key advantage over `count`!**

## Testing the VMs

### SSH into a VM

```bash
# Get SSH command from output
terraform output ssh_commands

# SSH to iowa VM
gcloud compute ssh vm-iowa --zone=us-central1-a
```

### Test HTTP

```bash
# Get HTTP URLs from output
terraform output http_urls

# Test with curl
curl http://EXTERNAL_IP
```

You should see: "VM in iowa"

## Clean Up

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted.

## Key Takeaways

✅ `for_each` uses meaningful keys instead of numeric indices
✅ Use `each.key` for the map key, `each.value` for the value
✅ Perfect for resources with different configurations
✅ Adding/removing resources doesn't affect others
✅ Use `self_link` for Google Cloud resource references
✅ `depends_on` ensures proper resource ordering
✅ Lifecycle rules control resource behavior

## count vs for_each Comparison

| Aspect | count | for_each |
|--------|-------|----------|
| Identifier | Numeric index (0, 1, 2) | Meaningful key (iowa, virginia) |
| Add/Remove | Can cause re-indexing | No impact on others |
| Configuration | All identical | Each can be different |
| Best for | Simple, numbered resources | Complex, named resources |
| Reference | `resource[0]` | `resource["key"]` |

## Next Steps

- Explore the `lifecycle` example for resource behavior control
- Study the `complete` example for all concepts combined
- Learn about modules for reusable infrastructure code
