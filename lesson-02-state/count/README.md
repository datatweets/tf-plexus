# count Meta-Argument Example

This example demonstrates the `count` meta-argument for creating multiple similar resources efficiently.

## What You'll Learn

- Using `count` to create multiple resources
- Working with `count.index` for unique naming
- Distributing resources across zones
- Referencing count-based resources with splat syntax `[*]`
- Individual and bulk resource references

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

Notice how Terraform will create 3 instances with indices [0], [1], [2].

### Step 5: Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted.

## Understanding the Code

### count Meta-Argument

```hcl
resource "google_compute_instance" "web" {
  count = var.server_count  # Creates 3 instances by default
  # ...
}
```

### Using count.index

```hcl
name = format("web-server-%02d", count.index + 1)
# count.index = 0 → "web-server-01"
# count.index = 1 → "web-server-02"
# count.index = 2 → "web-server-03"
```

### Zone Distribution

```hcl
zone = var.zones[count.index % length(var.zones)]
# Modulo operator cycles through zones:
# 0 % 3 = 0 → us-central1-a
# 1 % 3 = 1 → us-central1-b
# 2 % 3 = 2 → us-central1-c
```

## Exploring Resources

### List all resources

```bash
terraform state list
```

You'll see:
```
google_compute_instance.web[0]
google_compute_instance.web[1]
google_compute_instance.web[2]
```

### Show specific resource

```bash
terraform state show 'google_compute_instance.web[0]'
```

### View outputs

```bash
terraform output
```

See all server details, IPs, and SSH commands.

## Testing Different Counts

### Change the count

Edit `terraform.tfvars`:
```hcl
server_count = 5
```

Run plan to see changes:
```bash
terraform plan
```

Terraform will add 2 more servers: web[3] and web[4].

### Remove servers

Set `server_count = 2` and run plan:
```bash
terraform plan
```

Terraform will destroy web[2] (the last one).

**Note:** With count, removing from the middle causes re-indexing issues. Use `for_each` for more complex scenarios.

## Conditional Creation

You can use count for conditional creation. Edit `variables.tf` to add:

```hcl
variable "create_servers" {
  type    = bool
  default = true
}
```

Then use:
```hcl
count = var.create_servers ? var.server_count : 0
```

If `create_servers = false`, no resources are created!

## Clean Up

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted.

## Key Takeaways

✅ `count` creates multiple instances of a resource
✅ `count.index` provides zero-based index (0, 1, 2...)
✅ Resources are referenced as `resource_type.name[index]`
✅ Use splat `[*]` to get all instances at once
✅ Perfect for identical resources with numeric naming
✅ For complex scenarios with named resources, use `for_each` instead

## Next Steps

- Explore the `for_each` example for more flexible resource creation
- Learn about the `depends_on` meta-argument for dependencies
- Study the `lifecycle` meta-argument for resource behavior control
