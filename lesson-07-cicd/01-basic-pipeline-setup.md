# Section 01: Setup and Configuration

## Introduction

This section guides you through setting up Azure DevOps for Terraform automation with a strong focus on credential security. You'll learn how to configure everything safely so you never face credential issues in your pipelines.

**Time to Complete**: 60 minutes  
**Prerequisites**: Azure account, GCP account with billing enabled

---

## Learning Objectives

After completing this section, you will:

- Set up an Azure DevOps organization and project
- Create and configure a GCP service account with least privilege
- Securely store credentials using Azure DevOps Secure Files
- Configure remote state storage in GCS
- Connect your Git repository
- Understand the complete authentication flow

---

## Security-First Approach

### CRITICAL: Never Commit Credentials

Before we start, understand these rules:

❌ **NEVER DO THIS**:

```bash
# DON'T commit service account keys
git add terraform-ci-key.json

# DON'T put secrets in code
variable "gcp_credentials" {
  default = "{ actual json key }"  # NEVER!
}

# DON'T store keys in terraform.tfvars
gcp_key_path = "/Users/you/keys/service-account.json"  # NO!
```

✅ **DO THIS INSTEAD**:

```bash
# Store credentials in Azure DevOps Secure Files
# Download at runtime in pipeline
# Use environment variables
# Delete .gitignore service account keys
```

---

## Step-by-Step Setup

### Step 1: Create Azure DevOps Organization (5 minutes)

#### 1.1: Sign Up

1. Go to [dev.azure.com](https://dev.azure.com)
2. Click "Start free"
3. Sign in with Microsoft account (or create one)
4. Create new organization:
   - Organization name: `yourname-devops` (or company name)
   - Region: Choose closest to you
   - Captcha verification

#### 1.2: Create Project

1. Click "New project"
2. Project name: `terraform-gcp-cicd`
3. Visibility: **Private** (recommended)
4. Version control: **Git**
5. Work item process: **Basic**
6. Click "Create"

**Result**: You now have an Azure DevOps project!

---

### Step 2: Create GCP Service Account

Service accounts enable **secure, non-interactive authentication** for pipelines.

#### 2.1: Prerequisites

```bash
# Verify gcloud installed
gcloud version

# Authenticate
gcloud auth login

# Set project (or create new one)
export PROJECT_ID="your-terraform-project-id"
gcloud config set project $PROJECT_ID
```

#### 2.2: Create Service Account

```bash
# Create service account
gcloud iam service-accounts create terraform-ci \
  --display-name="Terraform CI/CD Pipeline" \
  --description="Service account for Azure DevOps Terraform pipelines" \
  --project=$PROJECT_ID

# Verify creation
gcloud iam service-accounts list --project=$PROJECT_ID
```

#### 2.3: Grant Permissions (Least Privilege)

**Option A: Editor Role** (simpler, good for learning):

```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:terraform-ci@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/editor"
```

**Option B: Specific Roles** (production-recommended):

```bash
# Compute Engine permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:terraform-ci@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

# Storage permissions (for state bucket)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:terraform-ci@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

# IAM permissions (to manage service accounts, if needed)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:terraform-ci@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"
```

**For this course**, use **Option A** (Editor role).

#### 2.4: Create and Download Key

```bash
# Create key and save to file
gcloud iam service-accounts keys create terraform-ci-key.json \
  --iam-account=terraform-ci@${PROJECT_ID}.iam.gserviceaccount.com \
  --project=$PROJECT_ID

# ⚠️ IMPORTANT: This file contains sensitive credentials!
```

**IMMEDIATELY after creation**:

1. **Move key to secure location**:

   ```bash
   # Create secure directory
   mkdir -p ~/.gcp-keys
   chmod 700 ~/.gcp-keys
   
   # Move key
   mv terraform-ci-key.json ~/.gcp-keys/
   chmod 600 ~/.gcp-keys/terraform-ci-key.json
   ```

2. **Add to .gitignore** (if not already):

   ```bash
   # Add to your project's .gitignore
   echo "*.json" >> .gitignore
   echo ".gcp-keys/" >> .gitignore
   echo "**/*-key.json" >> .gitignore
   ```

3. **Verify not tracked by Git**:

   ```bash
   git status  # Should NOT show .json files
   ```

---

### Step 3: Upload Credentials to Azure DevOps

This is the most important step for avoiding credential issues.

#### 3.1: Access Secure Files

1. In Azure DevOps, go to your project
2. Click **Pipelines** → **Library**
3. Click **Secure files** tab
4. Click **+ Secure file**

#### 3.2: Upload Service Account Key

1. Click **Browse**
2. Select `terraform-ci-key.json` from `~/.gcp-keys/`
3. Click **OK**

**Important**: The file will be renamed. Note the exact name (usually `terraform-ci-key.json`).

#### 3.3: Set Permissions

1. Click on the uploaded file
2. Click **Pipeline permissions**
3. Click **+** to authorize specific pipelines (or authorize all)
4. Optionally: Click **Approvers** to add approval requirement

#### 3.4: Verify Upload

You should see:

- File name: `terraform-ci-key.json`
- Size: ~2-3 KB
- Status: Active
- Authorized: Yes (or specific pipelines)

---

### Step 4: Create State Bucket

Terraform needs remote state storage for team collaboration.

#### 4.1: Create Bucket

```bash
# Set bucket name (must be globally unique)
export BUCKET_NAME="${PROJECT_ID}-tfstate"

# Create bucket
gsutil mb -p $PROJECT_ID -l us-central1 gs://$BUCKET_NAME

# Verify creation
gsutil ls gs://$BUCKET_NAME
```

#### 4.2: Enable Versioning (Critical for Safety!)

```bash
# Enable versioning (allows state rollback)
gsutil versioning set on gs://$BUCKET_NAME

# Verify
gsutil versioning get gs://$BUCKET_NAME
# Should output: gs://BUCKET_NAME: Enabled
```

#### 4.3: Set Lifecycle Policy (Optional but Recommended)

Keep last 10 versions, delete older ones:

```bash
# Create lifecycle policy file
cat > lifecycle-policy.json <<EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {
          "type": "Delete"
        },
        "condition": {
          "numNewerVersions": 10
        }
      }
    ]
  }
}
EOF

# Apply policy
gsutil lifecycle set lifecycle-policy.json gs://$BUCKET_NAME

# Verify
gsutil lifecycle get gs://$BUCKET_NAME

# Clean up
rm lifecycle-policy.json
```

#### 4.4: Set Permissions

```bash
# Grant service account access to state bucket
gsutil iam ch \
  serviceAccount:terraform-ci@${PROJECT_ID}.iam.gserviceaccount.com:roles/storage.objectAdmin \
  gs://$BUCKET_NAME
```

---

### Step 5: Configure Terraform Backend 

Create a backend configuration file for your Terraform project.

#### 5.1: Create Backend File

```hcl
# backend.tf
terraform {
  backend "gcs" {
    bucket = "YOUR_PROJECT_ID-tfstate"  # Replace with your bucket
    prefix = "terraform/state"           # Organizes state files
  }
}
```

**Important**: Don't commit sensitive values. Use variables or runtime config:

```hcl
# backend.tf (better approach)
terraform {
  backend "gcs" {
    # Bucket configured at init time:
    # terraform init -backend-config="bucket=YOUR_BUCKET"
  }
}
```

#### 5.2: Initialize Backend

```bash
# Test locally first
export GOOGLE_APPLICATION_CREDENTIALS=~/.gcp-keys/terraform-ci-key.json

# Initialize
terraform init -backend-config="bucket=${BUCKET_NAME}"

# Verify state location
terraform state list
```

---

### Step 6: Connect Git Repository 

#### 6.1: Initialize Git (if not already)

```bash
cd your-terraform-project

# Initialize Git
git init

# Create .gitignore
cat > .gitignore <<EOF
# Terraform
.terraform/
*.tfstate
*.tfstate.*
.terraform.lock.hcl

# Credentials (CRITICAL!)
*.json
**/*-key.json
.gcp-keys/
terraform-ci-key.json

# Variable files (may contain secrets)
*.tfvars
*.tfvars.json

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db
EOF

# Initial commit
git add .
git commit -m "Initial Terraform configuration"
```

#### 6.2: Push to Azure Repos

**Option A: Azure Repos** (integrated):

1. In Azure DevOps project, go to **Repos**
2. Copy the clone URL
3. Push your code:

```bash
# Add Azure Repos as remote
git remote add origin https://dev.azure.com/YOUR_ORG/terraform-gcp-cicd/_git/terraform-gcp-cicd

# Push
git push -u origin main
```

**Option B: GitHub** (external):

```bash
# Create repo on GitHub first
git remote add origin https://github.com/YOUR_USERNAME/terraform-gcp-cicd.git
git push -u origin main

# Connect to Azure DevOps:
# 1. In Azure DevOps: Pipelines → Create Pipeline
# 2. Select "GitHub"
# 3. Authorize Azure Pipelines
# 4. Select repository
```

---

### Step 7: Create Variable Group 

Store non-sensitive configuration variables.

#### 7.1: Create Variable Group

1. In Azure DevOps: **Pipelines** → **Library**
2. Click **+ Variable group**
3. Name: `terraform-variables`
4. Add variables:

| Variable Name     | Value                  | Secret? |
| ----------------- | ---------------------- | ------- |
| `TF_VERSION`      | `1.9.5`                | No      |
| `TF_STATE_BUCKET` | `your-project-tfstate` | No      |
| `GCP_PROJECT_ID`  | `your-project-id`      | No      |
| `GCP_REGION`      | `us-central1`          | No      |

5. Click **Save**

#### 7.2: Link to Pipelines

1. Click **Pipeline permissions**
2. Click **+** to authorize pipelines

---

## Authentication Flow

### How Credentials Work in Pipelines

```text
1. Pipeline starts
   ↓
2. DownloadSecureFile task retrieves key from Secure Files
   ↓
3. Key saved to temporary location (e.g., /tmp/secure-file-xyz)
   ↓
4. Environment variable GOOGLE_APPLICATION_CREDENTIALS set
   ↓
5. Terraform commands use this credential
   ↓
6. Pipeline ends → temporary file automatically deleted
```

### Pipeline YAML Example

```yaml
steps:
  # Download credential from Secure Files
  - task: DownloadSecureFile@1
    name: gcpKey
    displayName: 'Download GCP Service Account Key'
    inputs:
      secureFile: 'terraform-ci-key.json'  # Must match uploaded file name EXACTLY
  
  # Use credential
  - script: |
      # Set environment variable
      export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
      
      # Run Terraform
      terraform init -backend-config="bucket=$(TF_STATE_BUCKET)"
      terraform plan
    displayName: 'Terraform Plan'
    env:
      GOOGLE_APPLICATION_CREDENTIALS: $(gcpKey.secureFilePath)
```

---

## Verification Checklist

Before moving to the next section, verify:

### Azure DevOps Setup

- Organization created
- Project created
- Secure file uploaded (`terraform-ci-key.json`)
- Secure file authorized for pipelines
- Variable group created with 4 variables
- Variable group authorized for pipelines

### GCP Setup

- Service account created (`terraform-ci@PROJECT_ID.iam.gserviceaccount.com`)
- Service account has Editor role (or specific roles)
- Service account key downloaded
- Key moved to secure location (`~/.gcp-keys/`)
- Key NOT committed to Git

### State Storage

- GCS bucket created (`PROJECT_ID-tfstate`)
- Versioning enabled on bucket
- Lifecycle policy set (optional)
- Service account has bucket permissions

### Git Repository

- `.gitignore` configured correctly
- No credentials committed
- Code pushed to Azure Repos or GitHub
- Repository connected to Azure DevOps

### Local Testing

- `terraform init` works locally
- Can authenticate with service account key
- State stored in GCS bucket

---

## Troubleshooting

### Issue: "Could not download secure file"

**Symptoms**:

```text
##[error]Could not find file 'terraform-ci-key.json'
```

**Solutions**:

1. Verify file name EXACTLY matches in Secure Files
2. Check pipeline authorized to use secure file
3. Verify file uploaded successfully (check size ~2-3 KB)

**How to fix**:

```yaml
# Make sure name matches exactly
- task: DownloadSecureFile@1
  inputs:
    secureFile: 'terraform-ci-key.json'  # Check this name in Library
```

### Issue: "Permission denied" on state bucket

**Symptoms**:

```
Error: Failed to get existing workspaces: querying Cloud Storage failed:
storage: Permission denied
```

**Solutions**:

1. Verify service account has `roles/storage.admin` or `roles/storage.objectAdmin`
2. Check bucket name correct
3. Verify service account key is valid

**How to fix**:

```bash
# Grant storage permissions
gsutil iam ch \
  serviceAccount:terraform-ci@PROJECT_ID.iam.gserviceaccount.com:roles/storage.objectAdmin \
  gs://YOUR_BUCKET
```

### Issue: "Application Default Credentials not found"

**Symptoms**:

```
Error: google: could not find default credentials
```

**Solutions**:

1. Verify `GOOGLE_APPLICATION_CREDENTIALS` environment variable set
2. Check file path is correct
3. Ensure `$(gcpKey.secureFilePath)` used correctly

**How to fix**:

```yaml
- script: |
    # Debug: Print the path (without exposing content)
    echo "Credentials path: $(gcpKey.secureFilePath)"
    
    # Verify file exists
    ls -l $(gcpKey.secureFilePath)
    
    # Set environment variable
    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
    
    # Test authentication
    gcloud auth activate-service-account --key-file=$(gcpKey.secureFilePath)
```

### Issue: "Bucket does not exist"

**Symptoms**:

```
Error: Failed to get existing workspaces: storage.googleapis.com/storage/v1/b/BUCKET_NAME:
404 Not Found
```

**Solutions**:

1. Verify bucket created: `gsutil ls | grep tfstate`
2. Check bucket name in backend config
3. Ensure using correct GCP project

**How to fix**:

```bash
# Create bucket
gsutil mb -p PROJECT_ID -l us-central1 gs://PROJECT_ID-tfstate

# Verify
gsutil ls gs://PROJECT_ID-tfstate
```

### Issue: Service account key expired

**Symptoms**:

```
Error: failed to refresh cached credentials, error: invalid_grant
```

**Solutions**:

1. Keys don't expire by default, but can be revoked
2. Create new key and re-upload to Secure Files

**How to fix**:

```bash
# Create new key
gcloud iam service-accounts keys create new-terraform-ci-key.json \
  --iam-account=terraform-ci@PROJECT_ID.iam.gserviceaccount.com

# Upload to Azure DevOps Secure Files
# Delete old key from GCP (for security)
```

---

## Best Practices Summary

### Security Best Practices

1. **Never commit credentials**
   - Use `.gitignore`
   - Regular audits: `git log --all --full-history -- "*.json"`

2. **Use Secure Files**
   - Upload to Azure DevOps Library
   - Download at runtime
   - Automatic cleanup after pipeline

3. **Least Privilege**
   - Grant minimal required permissions
   - Separate service accounts for dev/prod

4. **Rotate Credentials**
   - Create new keys periodically (every 90 days)
   - Delete old keys

5. **Monitor Access**
   - Enable GCP audit logging
   - Review service account usage

### Operational Best Practices

1. **Use Remote State**
   - Always use GCS backend
   - Enable versioning
   - Set lifecycle policies

2. **Variable Groups**
   - Store configuration (not secrets)
   - Organize by environment
   - Document variables

3. **Naming Conventions**
   - Consistent service account names
   - Descriptive bucket names
   - Clear variable names

---

## Key Takeaways

### What You Learned

- Azure DevOps project setup
- GCP service account creation with proper permissions
- Secure credential storage and usage
- Remote state configuration
- Git repository integration
- Variable management

### Critical Security Points

- Never commit service account keys
- Use Azure DevOps Secure Files
- Set environment variables at runtime
- Enable state versioning
- Follow least privilege principle

### Next Steps

1. **Verify all checklist items** above
2. **Test authentication locally** with service account
3. **Continue to** [Section 02: Basic Pipeline](./section-02-basic-pipeline.md)

---

## Related Resources

- [Azure DevOps Secure Files Documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/secure-files)
- [GCP Service Accounts Best Practices](https://cloud.google.com/iam/docs/best-practices-service-accounts)
- [Terraform GCS Backend](https://developer.hashicorp.com/terraform/language/settings/backends/gcs)
- [Next: Section 02 - Basic Pipeline](./section-02-basic-pipeline.md)

---

**Setup complete? Continue to [Section 02: Basic Pipeline](./section-02-basic-pipeline.md) to create your first automated Terraform pipeline!**
