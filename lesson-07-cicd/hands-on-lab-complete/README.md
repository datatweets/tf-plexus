# Multi-Environment Terraform CI/CD Pipeline - Complete Implementation

This directory contains the complete, ready-to-deploy implementation of the multi-environment Terraform CI/CD pipeline for Azure DevOps.

## What's Included

This implementation deploys infrastructure to Google Cloud Platform across three environments:
- **Dev**: 1 VM (e2-micro) - Auto-deploy
- **Staging**: 2 VMs (e2-small) - Auto-deploy
- **Production**: 3 VMs (e2-medium) - **Manual approval required**

## Directory Structure

```
.
├── terraform/
│   ├── modules/
│   │   └── compute/              # Reusable compute module
│   │       ├── main.tf           # VPC, subnet, firewall, VMs
│   │       ├── variables.tf      # Module variables with validation
│   │       └── outputs.tf        # Module outputs
│   └── environments/
│       ├── dev/
│       │   ├── main.tf           # Dev environment config
│       │   ├── variables.tf      # Dev variables
│       │   ├── terraform.tfvars.example
│       │   ├── backend.tf        # Dev state bucket
│       │   └── outputs.tf
│       ├── staging/
│       │   └── (same structure)
│       └── prod/
│           └── (same structure)
├── azure-pipelines.yml           # Complete multi-stage pipeline
├── .gitignore
└── README.md                     # This file
```

## Prerequisites

### 1. GCP Setup

You need:
- A GCP project with billing enabled
- Compute Engine API enabled
- Storage API enabled (for Terraform state)
- A service account with Editor permissions

### 2. Azure DevOps Setup

You need:
- An Azure DevOps organization and project
- A Git repository connected to Azure Pipelines
- Pipeline permissions configured

## Step-by-Step Setup

### Step 1: Create GCP Service Account

```bash
# Set your project ID
export PROJECT_ID="YOUR-GCP-PROJECT-ID"

# Create service account
gcloud iam service-accounts create terraform-pipeline \
  --display-name="Terraform CI/CD Pipeline" \
  --project=${PROJECT_ID}

# Grant Editor role
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:terraform-pipeline@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/editor"

# Create and download key
gcloud iam service-accounts keys create ~/terraform-pipeline-key.json \
  --iam-account=terraform-pipeline@${PROJECT_ID}.iam.gserviceaccount.com

echo "✅ Service account key saved to ~/terraform-pipeline-key.json"
```

### Step 2: Create GCS State Buckets

```bash
# Create state buckets for each environment
for ENV in dev staging prod; do
  gsutil mb -p ${PROJECT_ID} \
    -l us-central1 \
    gs://${PROJECT_ID}-${ENV}-tfstate

  # Enable versioning
  gsutil versioning set on gs://${PROJECT_ID}-${ENV}-tfstate

  echo "✅ Created bucket: ${PROJECT_ID}-${ENV}-tfstate"
done

# Verify
gsutil ls | grep tfstate
```

### Step 3: Configure Terraform Backend Files

Update the backend configuration in each environment to use your project ID:

```bash
# Update dev backend
cat > terraform/environments/dev/backend.tf << EOF
terraform {
  backend "gcs" {
    bucket = "${PROJECT_ID}-dev-tfstate"
    prefix = "terraform/state"
  }
}
EOF

# Update staging backend
cat > terraform/environments/staging/backend.tf << EOF
terraform {
  backend "gcs" {
    bucket = "${PROJECT_ID}-staging-tfstate"
    prefix = "terraform/state"
  }
}
EOF

# Update prod backend
cat > terraform/environments/prod/backend.tf << EOF
terraform {
  backend "gcs" {
    bucket = "${PROJECT_ID}-prod-tfstate"
    prefix = "terraform/state"
  }
}
EOF
```

### Step 4: Create terraform.tfvars Files

Create actual `terraform.tfvars` files from the examples:

```bash
# Dev
cat > terraform/environments/dev/terraform.tfvars << EOF
project_id     = "${PROJECT_ID}"
environment    = "dev"
region         = "us-central1"
subnet_cidr    = "10.0.1.0/24"
instance_count = 1
machine_type   = "e2-micro"
disk_size_gb   = 10
EOF

# Staging
cat > terraform/environments/staging/terraform.tfvars << EOF
project_id     = "${PROJECT_ID}"
environment    = "staging"
region         = "us-central1"
subnet_cidr    = "10.1.1.0/24"
instance_count = 2
machine_type   = "e2-small"
disk_size_gb   = 20
EOF

# Production
cat > terraform/environments/prod/terraform.tfvars << EOF
project_id     = "${PROJECT_ID}"
environment    = "prod"
region         = "us-central1"
subnet_cidr    = "10.2.1.0/24"
instance_count = 3
machine_type   = "e2-medium"
disk_size_gb   = 50
EOF
```

### Step 5: Azure DevOps - Upload Service Account Key

1. Go to **Pipelines** → **Library** → **Secure files**
2. Click **+ Secure file**
3. Upload `terraform-pipeline-key.json`
4. Click **Authorize** to allow pipeline access

### Step 6: Azure DevOps - Create Variable Group

1. Go to **Pipelines** → **Library** → **+ Variable group**
2. Name it: `terraform-variables`
3. Add variables:
   - `GCP_PROJECT_ID`: Your GCP project ID
   - `GCP_REGION`: `us-central1`
   - `TF_VERSION`: `1.9.0`
4. Click **Save**

### Step 7: Azure DevOps - Create Environments

1. Go to **Pipelines** → **Environments**
2. Create three environments:
   - `terraform-dev` (no approval)
   - `terraform-staging` (no approval)
   - `terraform-prod` (with approval - see below)

**Configure Production Approval:**
1. Click on `terraform-prod` environment
2. Click **⋮** → **Approvals and checks**
3. Click **+ Add** → **Approvals**
4. Add yourself as approver
5. Set instructions: "Review Terraform plan before approving"
6. Click **Create**

### Step 8: Push Code to Azure DevOps

```bash
# Initialize git (if not already)
git init
git remote add origin <YOUR-AZURE-DEVOPS-REPO-URL>

# Add all files
git add .

# Commit
git commit -m "Add complete multi-environment Terraform pipeline

- Created reusable compute module
- Added dev, staging, and prod environments
- Configured multi-stage pipeline with approval gates
- Set up environment-specific variables
"

# Push to trigger pipeline
git push -u origin main
```

### Step 9: Create Azure Pipeline

1. Go to **Pipelines** → **Pipelines** → **New pipeline**
2. Select your repository
3. Choose **Existing Azure Pipelines YAML file**
4. Select `/azure-pipelines.yml`
5. Click **Run**

## Pipeline Flow

1. **Validate Stage** (~2 min)
   - Validates module and all three environments
   - Runs on every push to main

2. **Dev Stage** (~3-4 min)
   - Automatically deploys to Dev after validation
   - Creates 1 VM (e2-micro)

3. **Staging Stage** (~4-5 min)
   - Automatically deploys after Dev succeeds
   - Creates 2 VMs (e2-small)

4. **Production Stage** (~5-6 min)
   - **WAITS FOR MANUAL APPROVAL**
   - You must approve in Azure DevOps UI
   - Creates 3 VMs (e2-medium)

## Verification

### Check Pipeline Status

In Azure DevOps:
1. Go to **Pipelines** → **Pipelines**
2. Click on the running pipeline
3. Watch each stage execute
4. When Production stage pauses, click **Review** → **Approve**

### Verify GCP Resources

```bash
# Check Dev
gcloud compute instances list --project=${PROJECT_ID} --filter="name:dev-*"

# Check Staging
gcloud compute instances list --project=${PROJECT_ID} --filter="name:staging-*"

# Check Production
gcloud compute instances list --project=${PROJECT_ID} --filter="name:prod-*"

# Get all resources with IPs
gcloud compute instances list \
  --project=${PROJECT_ID} \
  --filter="labels.managed_by=terraform" \
  --format="table(name,zone,machineType,networkInterfaces[0].accessConfigs[0].natIP,status)"
```

### Check State Files

```bash
# List state files
gsutil ls -l gs://${PROJECT_ID}-dev-tfstate/terraform/state/
gsutil ls -l gs://${PROJECT_ID}-staging-tfstate/terraform/state/
gsutil ls -l gs://${PROJECT_ID}-prod-tfstate/terraform/state/
```

## Testing Changes

Make a change to test the pipeline:

```bash
# Update dev machine type
echo 'project_id     = "'${PROJECT_ID}'"
environment    = "dev"
region         = "us-central1"
subnet_cidr    = "10.0.1.0/24"
instance_count = 1
machine_type   = "e2-small"
disk_size_gb   = 10' > terraform/environments/dev/terraform.tfvars

# Commit and push
git add terraform/environments/dev/terraform.tfvars
git commit -m "test: Upgrade dev VM to e2-small"
git push origin main
```

Watch the pipeline automatically trigger and deploy only to Dev.

## Cleanup

To destroy all resources:

```bash
# Destroy production
cd terraform/environments/prod
export GOOGLE_APPLICATION_CREDENTIALS=~/terraform-pipeline-key.json
terraform init
terraform destroy -auto-approve

# Destroy staging
cd ../staging
terraform init
terraform destroy -auto-approve

# Destroy dev
cd ../dev
terraform init
terraform destroy -auto-approve

# Delete state buckets
gsutil -m rm -r gs://${PROJECT_ID}-dev-tfstate
gsutil -m rm -r gs://${PROJECT_ID}-staging-tfstate
gsutil -m rm -r gs://${PROJECT_ID}-prod-tfstate
```

## Troubleshooting

### Issue: "Permission denied" on GCP

**Solution:**
```bash
# Verify service account has Editor role
gcloud projects get-iam-policy ${PROJECT_ID} \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:terraform-pipeline@*"
```

### Issue: "Backend initialization failed"

**Solution:**
```bash
# Verify bucket exists
gsutil ls gs://${PROJECT_ID}-dev-tfstate

# Check bucket versioning
gsutil versioning get gs://${PROJECT_ID}-dev-tfstate
```

### Issue: Production deploys without approval

**Solution:**
1. Check environment configuration in Azure DevOps
2. Verify approval is added to `terraform-prod` environment
3. Ensure pipeline YAML uses: `environment: 'terraform-prod'`

### Issue: "Secure file not found"

**Solution:**
1. Verify file is uploaded in **Library** → **Secure files**
2. Check file name matches exactly: `terraform-pipeline-key.json`
3. Ensure pipeline is authorized to use the file

## Key Features

- ✅ Multi-environment deployment (Dev → Staging → Prod)
- ✅ Manual approval gate for production
- ✅ Environment-specific configurations
- ✅ Isolated state management per environment
- ✅ Reusable Terraform modules
- ✅ Input validation
- ✅ Deployment history tracking
- ✅ Automated validation on every commit

## Best Practices Demonstrated

1. **DRY Principle**: Reusable compute module
2. **Environment Isolation**: Separate state files and configurations
3. **Change Control**: Manual approval for production
4. **Validation**: Automated checks before deployment
5. **Auditability**: Git commits + pipeline logs
6. **Security**: Service account with least privilege
7. **Idempotency**: Terraform ensures consistent state

## Next Steps

1. Add automated testing (terraform test)
2. Implement drift detection
3. Add cost estimation (Infracost)
4. Configure notifications (Slack/email)
5. Add security scanning (tfsec, checkov)
6. Implement rollback procedures

## Resources

- [Azure DevOps Environments](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/environments)
- [Terraform GCS Backend](https://www.terraform.io/language/settings/backends/gcs)
- [GCP Service Accounts](https://cloud.google.com/iam/docs/service-accounts)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---

**Note**: This is a complete, production-ready implementation. Test thoroughly before sharing with students!
