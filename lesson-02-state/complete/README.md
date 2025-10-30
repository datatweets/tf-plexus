# Complete Meta-Arguments Example

This is the comprehensive example that combines all meta-arguments learned in Section 2:
- `for_each` for flexible resource creation
- `count` for conditional resources
- `depends_on` for explicit dependencies  
- `lifecycle` (create_before_destroy, prevent_destroy, ignore_changes)
- `self_link` for proper resource references

## What This Example Creates

- 1 VPC network with protection against accidental deletion
- 3 subnets across different regions (iowa, virginia, singapore)
- 3 VMs, one in each subnet with zero-downtime update capability
- 2 firewall rules (SSH and HTTP access)
- Complete outputs with all resource details

## Architecture

```
VPC Network (main-network)
├── Subnet: subnet-iowa (us-central1, 192.168.1.0/24)
│   └── VM: vm-iowa
├── Subnet: subnet-virginia (us-east1, 192.168.2.0/24)
│   └── VM: vm-virginia
└── Subnet: subnet-singapore (asia-southeast1, 192.168.3.0/24)
    └── VM: vm-singapore

Firewall Rules:
- allow-ssh (port 22)
- allow-http (port 80)
```

## Prerequisites

- Terraform installed (>= 1.9)
- Google Cloud project with billing enabled
- `gcloud` CLI authenticated

## Setup Instructions

### Step 1: Configure Your Project

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set your project ID.

### Step 2: Enable Required APIs

```bash
gcloud services enable compute.googleapis.com
```

### Step 3: Initialize and Apply

```bash
terraform init
terraform plan
terraform apply
```

## Key Features Demonstrated

### 1. for_each with Maps

```hcl
resource "google_compute_subnetwork" "regional" {
  for_each = var.regions
  # Creates subnets keyed by region name
}
```

Resources are referenced as:
- `google_compute_subnetwork.regional["iowa"]`
- `google_compute_subnetwork.regional["virginia"]`
- `google_compute_subnetwork.regional["singapore"]`

### 2. count for Conditional Resources

```hcl
resource "google_compute_firewall" "ssh" {
  count = 1  # Can be made conditional: var.create_ssh ? 1 : 0
}
```

### 3. depends_on for Explicit Dependencies

```hcl
resource "google_compute_subnetwork" "regional" {
  depends_on = [google_compute_network.main]
  # Ensures network is fully ready before creating subnets
}
```

### 4. lifecycle Rules

**prevent_destroy** on network:
```hcl
lifecycle {
  prevent_destroy = false  # Set to true in production!
}
```

**create_before_destroy** on VMs:
```hcl
lifecycle {
  create_before_destroy = true  # Zero downtime updates
}
```

**ignore_changes** on VMs:
```hcl
lifecycle {
  ignore_changes = [labels, metadata]  # Harmony with external tools
}
```

### 5. self_link References

```hcl
network = google_compute_network.main.self_link
# Not: network = google_compute_network.main.name
```

## Testing the Infrastructure

### View All Resources

```bash
terraform state list
```

### Get VM Details

```bash
terraform output vm_details
```

### SSH to a VM

```bash
# Get SSH commands
terraform output ssh_commands

# SSH to iowa VM
gcloud compute ssh vm-iowa --zone=us-central1-a
```

### Test HTTP

```bash
# Get HTTP URLs
terraform output http_urls

# Test with curl
curl http://EXTERNAL_IP
```

You should see: "VM in iowa"

## Adding a New Region

Edit `terraform.tfvars`:

```hcl
regions = {
  "iowa" = {
    zone          = "us-central1-a"
    ip_cidr_range = "192.168.1.0/24"
  }
  "virginia" = {
    zone          = "us-east1-b"
    ip_cidr_range = "192.168.2.0/24"
  }
  "singapore" = {
    zone          = "asia-southeast1-a"
    ip_cidr_range = "192.168.3.0/24"
  }
  "london" = {
    zone          = "europe-west2-a"
    ip_cidr_range = "192.168.4.0/24"
  }
}
```

Run:
```bash
terraform plan
terraform apply
```

Only the new "london" resources are added! Existing infrastructure remains intact.

## Testing lifecycle Features

### Test create_before_destroy

Change a VM's machine type to trigger replacement:

```hcl
machine_type = "e2-small"  # Changed from e2-micro
```

Run `terraform apply` and watch:
1. New VM is created first
2. Old VM is destroyed second
3. Zero downtime!

### Test ignore_changes

Add metadata externally:
```bash
gcloud compute instances add-metadata vm-iowa \
  --zone=us-central1-a \
  --metadata=cost-center=eng-123
```

Run `terraform plan` - no changes! Terraform ignores it.

## Clean Up

```bash
terraform destroy
```

Type `yes` when prompted.

**Note:** If you set `prevent_destroy = true` on the network, you'll need to remove it first, apply, then destroy.

## What You've Learned

✅ **for_each** - Flexible resource creation with meaningful keys
✅ **count** - Conditional resource creation
✅ **depends_on** - Explicit dependency management
✅ **lifecycle** - Resource behavior control
✅ **self_link** - Proper Google Cloud resource references
✅ **Cross-referencing** - Resources referencing each other correctly
✅ **For expressions** - Creating structured outputs

## Real-World Applications

This pattern is production-ready for:
- Multi-region deployments
- Environment-specific infrastructure
- Scalable web applications
- Infrastructure requiring high availability
- Resources managed by multiple tools

## Next Steps

- Add Cloud SQL databases to each region
- Implement load balancers for multi-region traffic
- Add Cloud Storage buckets
- Create IAM roles and permissions
- Set up VPN connections between regions
- Explore Terraform modules for reusable components

---

**Congratulations!** You've mastered all meta-arguments and can build production-grade infrastructure with Terraform!
