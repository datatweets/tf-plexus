# lifecycle Meta-Argument Example

This example demonstrates all three lifecycle options: `create_before_destroy`, `prevent_destroy`, and `ignore_changes`.

## What You'll Learn

- `create_before_destroy` for zero-downtime updates
- `prevent_destroy` to protect critical resources
- `ignore_changes` for harmony with external tools
- Combining multiple lifecycle rules
- When and why to use each option

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
gcloud services enable storage.googleapis.com
```

### Step 3: Initialize Terraform

```bash
terraform init
```

### Step 4: Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted.

## Testing Lifecycle Rules

### Test 1: create_before_destroy (Zero Downtime)

The `web-server-ha` instance uses `create_before_destroy`.

**Make a destructive change:**

Edit `main.tf` and change the machine type:
```hcl
machine_type = "e2-small"  # Changed from e2-micro
```

Run plan:
```bash
terraform plan
```

You'll see Terraform will:
1. **CREATE** the new instance first
2. **DESTROY** the old instance second

Apply the change:
```bash
terraform apply
```

Watch the process - both instances run simultaneously for a moment!

**Result:** Zero downtime! The new instance is ready before the old one is destroyed.

### Test 2: prevent_destroy (Protection)

The `critical-data` bucket uses `prevent_destroy`.

**Try to destroy it:**

```bash
terraform destroy -target=google_storage_bucket.critical_data
```

You'll get an error:
```
Error: Instance cannot be destroyed

Resource google_storage_bucket.critical_data has lifecycle.prevent_destroy
set, but the plan calls for this resource to be destroyed.
```

**Terraform refuses!** The bucket is protected.

**To actually destroy (if needed):**

1. Remove or comment out `prevent_destroy` in `main.tf`
2. Run `terraform apply` to update the lifecycle setting
3. Then run `terraform destroy`

### Test 3: ignore_changes (External Modifications)

The `monitored-server` instance uses `ignore_changes`.

**Simulate external tool adding metadata:**

```bash
# Add metadata using gcloud (simulating external tool)
gcloud compute instances add-metadata monitored-server \
  --zone=us-central1-a \
  --metadata=monitoring-agent=v2.0,cost-center=eng-123
```

**Check Terraform's reaction:**

```bash
terraform plan
```

Result: **No changes!** Terraform ignores the metadata changes because of `ignore_changes`.

**Add a label using gcloud:**

```bash
gcloud compute instances add-labels monitored-server \
  --zone=us-central1-a \
  --labels=cost-center=eng-123
```

Run plan again:
```bash
terraform plan
```

Still no changes! Labels are also ignored.

**What happens without ignore_changes?**

If you remove `ignore_changes` and run plan, Terraform will want to remove all the external changes to restore your configuration.

### Test 4: Combined Lifecycle Rules

The `production-database` instance uses all three:

```hcl
lifecycle {
  prevent_destroy       = true
  create_before_destroy = true
  ignore_changes        = [labels["cost-center"], metadata["monitoring"]]
}
```

This provides:
- ✅ Protection from deletion
- ✅ Zero downtime updates
- ✅ Harmony with external tools

## Understanding Each Lifecycle Option

### create_before_destroy

**Use when:**
- High availability is critical
- Can't tolerate downtime
- Have resources that need gradual rollover

**Trade-offs:**
- Temporarily doubles resources (and costs)
- Both old and new run simultaneously
- Name conflicts if not handled carefully

**Example use cases:**
- Production web servers
- Load-balanced applications
- Database replicas

### prevent_destroy

**Use when:**
- Resource contains critical data
- Accidental deletion would be catastrophic
- Extra safety layer needed

**Important:**
- Only prevents `terraform destroy`
- Doesn't prevent manual deletion via console/gcloud
- Must be removed before destruction

**Example use cases:**
- Production databases
- Data storage buckets
- State buckets
- Long-term archives

### ignore_changes

**Use when:**
- External tools modify resources
- Attributes managed outside Terraform
- Want to prevent configuration drift alerts

**Be careful:**
- Only ignore what's necessary
- Document why changes are ignored
- Don't use `all` unless absolutely required

**Example use cases:**
- Cost management tools add labels
- Auto-scaling modifies instance count
- Monitoring agents add metadata
- Security scanners add tags

## Clean Up

**Note:** The `production-database` and `critical-data` bucket have `prevent_destroy = true`.

### Option 1: Comment out prevent_destroy

Edit `main.tf` and change:
```hcl
lifecycle {
  # prevent_destroy = true  # Commented out
}
```

Then:
```bash
terraform apply  # Updates lifecycle setting
terraform destroy
```

### Option 2: Destroy specific resources

Destroy resources without prevent_destroy first:
```bash
terraform destroy -target=google_compute_instance.web
terraform destroy -target=google_compute_instance.monitored
```

Then manually update and destroy the protected ones.

## Key Takeaways

✅ **create_before_destroy** ensures zero downtime for replacements
✅ **prevent_destroy** protects critical resources from accidents
✅ **ignore_changes** allows harmony with external management tools
✅ Lifecycle rules can be combined for comprehensive control
✅ Use lifecycle rules strategically - they have trade-offs
✅ Always document why lifecycle rules are used

## Best Practices

| Resource Type | Recommended Lifecycle |
|--------------|----------------------|
| Production DB | prevent_destroy + create_before_destroy |
| Data Storage | prevent_destroy |
| Web Servers | create_before_destroy |
| Dev/Test Resources | None (default behavior) |
| Monitored Resources | ignore_changes for specific attributes |

## Next Steps

- Study the `complete` example that combines all meta-arguments
- Learn about modules for reusable infrastructure patterns
- Explore Terraform workspaces for multi-environment management
