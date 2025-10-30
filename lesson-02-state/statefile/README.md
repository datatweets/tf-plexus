# State Management Example

This example demonstrates Terraform state management concepts from Section 1 of Lesson 2.

## What You'll Learn

- How Terraform state works
- Inspecting state with commands
- Destructive vs non-destructive changes
- State file structure and importance

## Prerequisites

- Terraform installed (>= 1.9)
- Google Cloud project with billing enabled
- `gcloud` CLI authenticated

## Setup Instructions

### Step 1: Configure Your Project

Copy the example tfvars file and add your project ID:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and replace `your-project-id-here` with your actual GCP project ID.

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

### Step 5: Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted.

## Exploring State

After applying, try these commands to explore the state:

### List all managed resources

```bash
terraform state list
```

### Show detailed information about the instance

```bash
terraform state show google_compute_instance.this
```

### Interactive exploration with console

```bash
terraform console
```

Then try:
```
> google_compute_instance.this.name
> google_compute_instance.this.network_interface[0].access_config[0].nat_ip
> google_compute_instance.this.machine_type
```

Type `exit` to quit the console.

## Testing Idempotency

Run apply again to see idempotency in action:

```bash
terraform apply
```

Notice: "No changes. Your infrastructure matches the configuration."

## Testing Changes

### Non-Destructive Change

Add a label using the GCP Console, then run:

```bash
terraform plan
```

```bash
google_compute_instance.this: Refreshing state... [id=projects/terraform-prj-476214/zones/us-central1-a/instances/state-file]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found
no differences, so no changes are needed.
```

### Destructive Change

Remove the startup script in the GCP Console, then run:

```bash
terraform plan
```

You'll see Terraform wants to replace the instance (marked with `-/+` and "forces replacement").

## Clean Up

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted.

## Important Notes

- **Never edit the state file manually!** Use Terraform commands.
- State files contain sensitive information - never commit to Git.
- The `.gitignore` file is already configured to exclude state files.
- Always run `terraform plan` before `apply` to review changes.
