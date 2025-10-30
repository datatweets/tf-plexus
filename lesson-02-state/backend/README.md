# Remote Backend State Example

This example demonstrates how to configure remote backend state for team collaboration using Google Cloud Storage.

## What You'll Learn

- Setting up remote state in Google Cloud Storage
- State locking for team collaboration
- Migrating from local to remote state
- Backend configuration best practices

## Prerequisites

- Terraform installed (>= 1.9)
- Google Cloud project with billing enabled
- `gcloud` CLI authenticated
- Permissions to create Cloud Storage buckets

## Setup Instructions

### Step 1: Create a Cloud Storage Bucket for State

The bucket name must be globally unique. Choose a name like `yourcompany-terraform-state-prod`.

```bash
# Replace YOUR-PROJECT-ID and YOUR-UNIQUE-BUCKET-NAME
export PROJECT_ID="your-project-id"
export BUCKET_NAME="your-unique-bucket-name-terraform-state"

# Create the bucket
gsutil mb -p $PROJECT_ID -l us-central1 gs://$BUCKET_NAME/

# Enable versioning (recommended for state history)
gsutil versioning set on gs://$BUCKET_NAME/
```

**Important:** Keep your bucket name - you'll need it in the next step!

### Step 2: Configure Backend in Terraform

Edit `main.tf` and replace the backend configuration:

```hcl
backend "gcs" {
  bucket = "YOUR-ACTUAL-BUCKET-NAME"  # Replace this!
  prefix = "terraform/state"
}
```

Replace `YOUR-ACTUAL-BUCKET-NAME` with the bucket name you just created.

### Step 3: Configure Your Project ID

Copy the example tfvars file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set your project ID.

### Step 4: Enable Required APIs

```bash
gcloud services enable compute.googleapis.com
```

### Step 5: Initialize with Backend

```bash
terraform init
```

You'll see confirmation that the backend was successfully configured.

### Step 6: Apply the Configuration

```bash
terraform plan
terraform apply
```

Type `yes` when prompted.

### Step 7: Verify Remote State

Check that the state file is now in Cloud Storage:

```bash
gsutil ls gs://$BUCKET_NAME/terraform/state/
```

You should see: `gs://your-bucket-name/terraform/state/default.tfstate`

## Testing Team Collaboration

### Simulate Multiple Team Members

**Terminal 1 (Developer Sarah):**
```bash
cd lesson-02/backend
terraform init
terraform plan
# State is fetched from Cloud Storage
```

**Terminal 2 (Developer Tom):**
```bash
cd lesson-02/backend
terraform init
terraform plan
# Sees the same infrastructure Sarah created!
```

Both developers are now working with the same state file.

### Testing State Locking

**Terminal 1:**
```bash
terraform apply
# Don't confirm yet, leave it waiting
```

**Terminal 2:**
```bash
terraform apply
# Try this while Terminal 1 is still running
# You'll see a state lock error!
```

This prevents simultaneous modifications that could corrupt state.

## Migrating Existing Local State

If you already have local state and want to migrate to remote backend:

1. Configure the backend in `main.tf`
2. Run `terraform init`
3. Terraform will ask: "Do you want to copy existing state to the new backend?"
4. Type `yes`
5. Your local state is now migrated to Cloud Storage!

## Backend State Best Practices

✅ **Always use remote backend** - Even for solo projects
✅ **Enable versioning** - Provides state history and recovery
✅ **Restrict access** - Only Terraform admins should access the bucket
✅ **Separate backends per environment** - Different buckets for dev/staging/prod
✅ **Never commit state files** - The `.gitignore` is configured correctly

## Viewing State History (with versioning enabled)

```bash
# List all versions of the state file
gsutil ls -a gs://$BUCKET_NAME/terraform/state/default.tfstate

# Restore a previous version if needed
gsutil cp gs://$BUCKET_NAME/terraform/state/default.tfstate#VERSION_NUMBER \
           gs://$BUCKET_NAME/terraform/state/default.tfstate
```

## Clean Up

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted.

**Optional:** Delete the state bucket (only if you're done with all examples):

```bash
gsutil rm -r gs://$BUCKET_NAME/
```

## Troubleshooting

### State Lock Issues

If a lock is stuck (someone's process crashed):

1. Get the Lock ID from the error message
2. Force unlock (use with caution!):

```bash
terraform force-unlock LOCK-ID
```

### Backend Configuration Changes

If you change the backend configuration, run:

```bash
terraform init -reconfigure
```

## Important Notes

- **State locking** is automatic with GCS backend
- State files contain **sensitive information** - restrict access!
- **Never edit state files manually** - always use Terraform commands
- Use **separate buckets** for production vs non-production environments
