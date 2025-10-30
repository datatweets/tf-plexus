# Multi-Environment Pipeline

## 📋 Overview

This tutorial teaches you to build a **production-ready multi-environment CI/CD pipeline** for Terraform. You'll deploy the same infrastructure to Dev, Staging, and Production environments with appropriate controls and approvals.

**Duration**: 120 minutes  
**Difficulty**: Intermediate  
**Prerequisites**: Tutorial 1 (Basic Pipeline) completed

---

## 🎯 What You'll Build

A complete multi-environment deployment pipeline with:

```
┌─────────────────────────────────────────────────────────────┐
│                                                               │
│  Git Push (main branch)                                      │
│         │                                                     │
│         ▼                                                     │
│  ┌──────────────┐                                           │
│  │   Validate   │  terraform fmt, validate, plan            │
│  └──────┬───────┘                                           │
│         │                                                     │
│         ├─────────────────┬─────────────────┐               │
│         ▼                 ▼                 ▼               │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐      │
│  │     Dev     │   │   Staging   │   │ Production  │      │
│  │             │   │             │   │             │      │
│  │ Auto-deploy │   │ Auto-deploy │   │ 👤 Manual   │      │
│  │             │   │             │   │  Approval   │      │
│  └─────────────┘   └─────────────┘   └─────────────┘      │
│                                                               │
│  Each environment has:                                       │
│  • Separate GCP project                                      │
│  • Own Terraform state file                                  │
│  • Environment-specific variables                            │
│  • Isolated resources                                        │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 📚 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Part 1: Azure DevOps Environment Setup](#part-1-azure-devops-environment-setup)
3. [Part 2: GCP Multi-Project Setup](#part-2-gcp-multi-project-setup)
4. [Part 3: Terraform Code Structure](#part-3-terraform-code-structure)
5. [Part 4: Pipeline Configuration](#part-4-pipeline-configuration)
6. [Part 5: Deploy and Test](#part-5-deploy-and-test)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required

- ✅ **Tutorial 1 completed** - Basic pipeline working
- ✅ **Azure DevOps organization** with project created
- ✅ **GCP access** - Ability to create multiple projects (or use folders)
- ✅ **Billing account** - GCP billing enabled
- ✅ **Git repository** - Connected to Azure Pipelines

### Knowledge

- Basic Terraform (Lessons 1-5)
- YAML syntax basics
- Git operations (commit, push, branch)

---

## Part 1: Azure DevOps Environment Setup

Azure DevOps **Environments** provide deployment tracking, history, and approval gates.

### Step 1.1: Create Environments

1. **Navigate to Environments**:
   - In Azure DevOps, go to **Pipelines** → **Environments**
   - Click **+ New environment**

2. **Create Dev Environment**:
   - **Name**: `terraform-dev`
   - **Description**: `Development environment - auto-deploy`
   - **Resource**: None (we'll use this for deployment tracking only)
   - Click **Create**

3. **Create Staging Environment**:
   - Click **+ New environment**
   - **Name**: `terraform-staging`
   - **Description**: `Staging environment - auto-deploy`
   - Click **Create**

4. **Create Production Environment**:
   - Click **+ New environment**
   - **Name**: `terraform-prod`
   - **Description**: `Production environment - requires approval`
   - Click **Create**

### Step 1.2: Configure Production Approval

Production deployments should require manual approval.

1. **Open Production Environment**:
   - Click on `terraform-prod` environment
   - Click the **⋮** (more actions) menu
   - Select **Approvals and checks**

2. **Add Approval**:
   - Click **+ Add** → **Approvals**
   - **Approvers**: Add yourself (or your team)
   - **Instructions**: "Review Terraform plan before approving"
   - **Minimum number of approvers**: 1
   - **Timeout**: 30 days
   - **Approvers can approve their own runs**: ☐ (unchecked for safety)
   - Click **Create**

3. **Verify Configuration**:
   - You should see "Approvals" listed under Checks
   - Dev and Staging environments should have no checks

---

## Part 2: GCP Multi-Project Setup

For this tutorial, you have **two options**:

### Option A: Multiple GCP Projects (Recommended)

Create three separate GCP projects for complete isolation:

```bash
# Set variables
export ORG_ID="your-org-id"              # Optional
export BILLING_ACCOUNT="your-billing-id"
export BASE_NAME="terraform-demo"

# Create dev project
gcloud projects create ${BASE_NAME}-dev \
  --name="${BASE_NAME}-dev" \
  --set-as-default

gcloud beta billing projects link ${BASE_NAME}-dev \
  --billing-account=${BILLING_ACCOUNT}

# Enable APIs
gcloud services enable compute.googleapis.com --project=${BASE_NAME}-dev
gcloud services enable storage.googleapis.com --project=${BASE_NAME}-dev

# Create staging project
gcloud projects create ${BASE_NAME}-staging \
  --name="${BASE_NAME}-staging"

gcloud beta billing projects link ${BASE_NAME}-staging \
  --billing-account=${BILLING_ACCOUNT}

gcloud services enable compute.googleapis.com --project=${BASE_NAME}-staging
gcloud services enable storage.googleapis.com --project=${BASE_NAME}-staging

# Create production project
gcloud projects create ${BASE_NAME}-prod \
  --name="${BASE_NAME}-prod"

gcloud beta billing projects link ${BASE_NAME}-prod \
  --billing-account=${BILLING_ACCOUNT}

gcloud services enable compute.googleapis.com --project=${BASE_NAME}-prod
gcloud services enable storage.googleapis.com --project=${BASE_NAME}-prod

# List your projects
gcloud projects list --filter="name:${BASE_NAME}"
```

### Option B: Single Project with Labels (Simpler)

Use one project with labels to distinguish environments:

```bash
export PROJECT_ID="your-project-id"

gcloud services enable compute.googleapis.com --project=${PROJECT_ID}
gcloud services enable storage.googleapis.com --project=${PROJECT_ID}

# All resources will be in one project, differentiated by labels
```

**For this tutorial, we'll use Option A (multiple projects) for best practices.**

### Step 2.1: Create Service Account for Pipeline

Create a service account that can manage all three environments:

```bash
export SA_NAME="terraform-pipeline"
export PROJECT_ID="terraform-demo-dev"  # Use any project to create SA

# Create service account
gcloud iam service-accounts create ${SA_NAME} \
  --display-name="Terraform CI/CD Pipeline" \
  --description="Service account for Azure DevOps pipeline" \
  --project=${PROJECT_ID}

# Grant permissions on all three projects
for ENV in dev staging prod; do
  gcloud projects add-iam-policy-binding terraform-demo-${ENV} \
    --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/editor"
done

# Create and download key
gcloud iam service-accounts keys create ~/terraform-pipeline-key.json \
  --iam-account=${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com

echo "✅ Service account key saved to ~/terraform-pipeline-key.json"
```

### Step 2.2: Create State Buckets

Each environment needs its own state bucket:

```bash
# Create state buckets
for ENV in dev staging prod; do
  gsutil mb -p terraform-demo-${ENV} \
    -l us-central1 \
    gs://terraform-demo-${ENV}-tfstate
  
  # Enable versioning
  gsutil versioning set on gs://terraform-demo-${ENV}-tfstate
  
  echo "✅ Created bucket: terraform-demo-${ENV}-tfstate"
done

# Verify
gsutil ls | grep tfstate
```

---

## Part 3: Terraform Code Structure

Let's organize our code for multiple environments.

### Step 3.1: Directory Structure

Create this structure in your repository:

```bash
mkdir -p terraform/environments/{dev,staging,prod}
mkdir -p terraform/modules/compute
```

Final structure:

```
terraform/
├── modules/
│   └── compute/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    ├── dev/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── terraform.tfvars
    │   └── backend.tf
    ├── staging/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── terraform.tfvars
    │   └── backend.tf
    └── prod/
        ├── main.tf
        ├── variables.tf
        ├── terraform.tfvars
        └── backend.tf
```

### Step 3.2: Create Reusable Module

**File**: `terraform/modules/compute/main.tf`

```hcl
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

resource "google_compute_network" "vpc" {
  name                    = "${var.environment}-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.environment}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id
}

resource "google_compute_instance" "vm" {
  count        = var.instance_count
  name         = "${var.environment}-vm-${count.index + 1}"
  machine_type = var.machine_type
  zone         = "${var.region}-a"
  project      = var.project_id

  tags = [var.environment, "managed-by-terraform"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = var.disk_size_gb
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id
    
    access_config {
      # Ephemeral public IP
    }
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }

  metadata = {
    environment = var.environment
  }
}
```

**File**: `terraform/modules/compute/variables.tf`

```hcl
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "subnet_cidr" {
  description = "Subnet CIDR range"
  type        = string
}

variable "instance_count" {
  description = "Number of VM instances"
  type        = number
  default     = 1
}

variable "machine_type" {
  description = "GCE machine type"
  type        = string
  default     = "e2-micro"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 10
}
```

**File**: `terraform/modules/compute/outputs.tf`

```hcl
output "vpc_name" {
  description = "VPC name"
  value       = google_compute_network.vpc.name
}

output "subnet_name" {
  description = "Subnet name"
  value       = google_compute_subnetwork.subnet.name
}

output "instance_names" {
  description = "VM instance names"
  value       = google_compute_instance.vm[*].name
}

output "instance_ips" {
  description = "VM external IPs"
  value       = google_compute_instance.vm[*].network_interface[0].access_config[0].nat_ip
}
```

### Step 3.3: Create Dev Environment

**File**: `terraform/environments/dev/main.tf`

```hcl
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "infrastructure" {
  source = "../../modules/compute"

  project_id     = var.project_id
  environment    = var.environment
  region         = var.region
  subnet_cidr    = var.subnet_cidr
  instance_count = var.instance_count
  machine_type   = var.machine_type
  disk_size_gb   = var.disk_size_gb
}
```

**File**: `terraform/environments/dev/variables.tf`

```hcl
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "subnet_cidr" {
  description = "Subnet CIDR"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 1
}

variable "machine_type" {
  description = "Machine type"
  type        = string
  default     = "e2-micro"
}

variable "disk_size_gb" {
  description = "Disk size"
  type        = number
  default     = 10
}
```

**File**: `terraform/environments/dev/terraform.tfvars`

```hcl
project_id     = "terraform-demo-dev"
environment    = "dev"
region         = "us-central1"
subnet_cidr    = "10.0.1.0/24"
instance_count = 1
machine_type   = "e2-micro"
disk_size_gb   = 10
```

**File**: `terraform/environments/dev/backend.tf`

```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-demo-dev-tfstate"
    prefix = "terraform/state"
  }
}
```

**File**: `terraform/environments/dev/outputs.tf`

```hcl
output "vpc_name" {
  description = "VPC name"
  value       = module.infrastructure.vpc_name
}

output "instance_names" {
  description = "Instance names"
  value       = module.infrastructure.instance_names
}

output "instance_ips" {
  description = "Instance IPs"
  value       = module.infrastructure.instance_ips
}
```

### Step 3.4: Create Staging Environment

Copy dev files and modify:

```bash
# Copy dev to staging
cp -r terraform/environments/dev/* terraform/environments/staging/
```

**Edit**: `terraform/environments/staging/terraform.tfvars`

```hcl
project_id     = "terraform-demo-staging"
environment    = "staging"
region         = "us-central1"
subnet_cidr    = "10.1.1.0/24"  # Different CIDR
instance_count = 2              # More instances
machine_type   = "e2-small"     # Bigger machine
disk_size_gb   = 20
```

**Edit**: `terraform/environments/staging/backend.tf`

```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-demo-staging-tfstate"
    prefix = "terraform/state"
  }
}
```

**Edit**: `terraform/environments/staging/variables.tf` - Change defaults to match staging:

```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "subnet_cidr" {
  description = "Subnet CIDR"
  type        = string
  default     = "10.1.1.0/24"
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Machine type"
  type        = string
  default     = "e2-small"
}
```

### Step 3.5: Create Production Environment

Copy staging and modify for production:

```bash
# Copy staging to prod
cp -r terraform/environments/staging/* terraform/environments/prod/
```

**Edit**: `terraform/environments/prod/terraform.tfvars`

```hcl
project_id     = "terraform-demo-prod"
environment    = "prod"
region         = "us-central1"
subnet_cidr    = "10.2.1.0/24"  # Different CIDR
instance_count = 3              # Even more instances
machine_type   = "e2-medium"    # Production machine
disk_size_gb   = 50
```

**Edit**: `terraform/environments/prod/backend.tf`

```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-demo-prod-tfstate"
    prefix = "terraform/state"
  }
}
```

**Edit**: `terraform/environments/prod/variables.tf` - Change defaults:

```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "subnet_cidr" {
  description = "Subnet CIDR"
  type        = string
  default     = "10.2.1.0/24"
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 3
}

variable "machine_type" {
  description = "Machine type"
  type        = string
  default     = "e2-medium"
}

variable "disk_size_gb" {
  description = "Disk size"
  type        = number
  default     = 50
}
```

---

## Part 4: Pipeline Configuration

Now let's create the multi-environment pipeline.

### Step 4.1: Upload Service Account Key

1. **Navigate to Library**:
   - Go to **Pipelines** → **Library** → **Secure files**
   - Click **+ Secure file**

2. **Upload Key**:
   - Select `terraform-pipeline-key.json`
   - Click **OK**

3. **Authorize**:
   - Click on the uploaded file
   - Click **Pipeline permissions**
   - Allow all pipelines (or specific one)

### Step 4.2: Create Pipeline YAML

**File**: `azure-pipelines.yml` (in repository root)

```yaml
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - terraform/**
      - azure-pipelines.yml

pool:
  vmImage: 'ubuntu-latest'

variables:
  terraformVersion: '1.9.0'
  gcpServiceAccountFile: 'terraform-pipeline-key.json'

stages:
  #############################################################################
  # STAGE 1: Validate
  #############################################################################
  - stage: Validate
    displayName: 'Validate Terraform'
    jobs:
      - job: ValidateAll
        displayName: 'Validate All Environments'
        steps:
          - task: TerraformInstaller@1
            displayName: 'Install Terraform'
            inputs:
              terraformVersion: '$(terraformVersion)'
          
          - task: DownloadSecureFile@1
            name: gcpKey
            displayName: 'Download GCP Key'
            inputs:
              secureFile: '$(gcpServiceAccountFile)'
          
          # Validate Dev
          - script: |
              export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
              cd terraform/environments/dev
              terraform init -backend=false
              terraform validate
              terraform fmt -check -recursive
            displayName: 'Validate Dev'
          
          # Validate Staging
          - script: |
              export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
              cd terraform/environments/staging
              terraform init -backend=false
              terraform validate
            displayName: 'Validate Staging'
          
          # Validate Prod
          - script: |
              export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
              cd terraform/environments/prod
              terraform init -backend=false
              terraform validate
            displayName: 'Validate Prod'

  #############################################################################
  # STAGE 2: Dev Environment
  #############################################################################
  - stage: Dev
    displayName: 'Deploy to Dev'
    dependsOn: Validate
    condition: succeeded()
    jobs:
      - deployment: DeployDev
        displayName: 'Deploy Dev Environment'
        environment: 'terraform-dev'
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self
                
                - task: TerraformInstaller@1
                  displayName: 'Install Terraform'
                  inputs:
                    terraformVersion: '$(terraformVersion)'
                
                - task: DownloadSecureFile@1
                  name: gcpKey
                  displayName: 'Download GCP Key'
                  inputs:
                    secureFile: '$(gcpServiceAccountFile)'
                
                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    cd terraform/environments/dev
                    terraform init
                    terraform plan -out=tfplan
                  displayName: 'Terraform Init & Plan'
                
                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    cd terraform/environments/dev
                    terraform apply -auto-approve tfplan
                  displayName: 'Terraform Apply'
                
                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    cd terraform/environments/dev
                    terraform output -json > $(Build.ArtifactStagingDirectory)/dev-outputs.json
                  displayName: 'Save Outputs'
                
                - task: PublishPipelineArtifact@1
                  displayName: 'Publish Dev Outputs'
                  inputs:
                    targetPath: '$(Build.ArtifactStagingDirectory)'
                    artifact: 'dev-outputs'

  #############################################################################
  # STAGE 3: Staging Environment
  #############################################################################
  - stage: Staging
    displayName: 'Deploy to Staging'
    dependsOn: Dev
    condition: succeeded()
    jobs:
      - deployment: DeployStaging
        displayName: 'Deploy Staging Environment'
        environment: 'terraform-staging'
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self
                
                - task: TerraformInstaller@1
                  displayName: 'Install Terraform'
                  inputs:
                    terraformVersion: '$(terraformVersion)'
                
                - task: DownloadSecureFile@1
                  name: gcpKey
                  displayName: 'Download GCP Key'
                  inputs:
                    secureFile: '$(gcpServiceAccountFile)'
                
                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    cd terraform/environments/staging
                    terraform init
                    terraform plan -out=tfplan
                  displayName: 'Terraform Init & Plan'
                
                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    cd terraform/environments/staging
                    terraform apply -auto-approve tfplan
                  displayName: 'Terraform Apply'
                
                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    cd terraform/environments/staging
                    terraform output -json > $(Build.ArtifactStagingDirectory)/staging-outputs.json
                  displayName: 'Save Outputs'
                
                - task: PublishPipelineArtifact@1
                  displayName: 'Publish Staging Outputs'
                  inputs:
                    targetPath: '$(Build.ArtifactStagingDirectory)'
                    artifact: 'staging-outputs'

  #############################################################################
  # STAGE 4: Production Environment (Manual Approval Required)
  #############################################################################
  - stage: Production
    displayName: 'Deploy to Production'
    dependsOn: Staging
    condition: succeeded()
    jobs:
      - deployment: DeployProduction
        displayName: 'Deploy Production Environment'
        environment: 'terraform-prod'  # This triggers approval gate
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self
                
                - task: TerraformInstaller@1
                  displayName: 'Install Terraform'
                  inputs:
                    terraformVersion: '$(terraformVersion)'
                
                - task: DownloadSecureFile@1
                  name: gcpKey
                  displayName: 'Download GCP Key'
                  inputs:
                    secureFile: '$(gcpServiceAccountFile)'
                
                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    cd terraform/environments/prod
                    terraform init
                    terraform plan -out=tfplan
                  displayName: 'Terraform Init & Plan'
                
                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    cd terraform/environments/prod
                    terraform show tfplan
                  displayName: 'Show Plan for Review'
                
                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    cd terraform/environments/prod
                    terraform apply -auto-approve tfplan
                  displayName: 'Terraform Apply'
                
                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    cd terraform/environments/prod
                    terraform output -json > $(Build.ArtifactStagingDirectory)/prod-outputs.json
                  displayName: 'Save Outputs'
                
                - task: PublishPipelineArtifact@1
                  displayName: 'Publish Prod Outputs'
                  inputs:
                    targetPath: '$(Build.ArtifactStagingDirectory)'
                    artifact: 'prod-outputs'
```

---

## Part 5: Deploy and Test

### Step 5.1: Commit and Push Code

```bash
# Add all files
git add terraform/ azure-pipelines.yml

# Commit
git commit -m "Add multi-environment Terraform pipeline"

# Push to trigger pipeline
git push origin main
```

### Step 5.2: Monitor Pipeline Execution

1. **Go to Pipelines**:
   - Navigate to **Pipelines** → **Pipelines**
   - You should see your pipeline running

2. **Watch Validate Stage**:
   - Click on the running pipeline
   - Watch the "Validate" stage complete
   - All three environments should validate successfully

3. **Dev Deployment** (Automatic):
   - After validation, Dev stage starts automatically
   - Watch it deploy to dev environment
   - Check the outputs

4. **Staging Deployment** (Automatic):
   - After Dev completes, Staging starts automatically
   - Verify staging deployment
   - Check outputs

5. **Production Approval** (Manual):
   - Production stage will show "Waiting for approval"
   - Click **Review** → **Approve**
   - Add comment: "Reviewed plan, approved for deployment"
   - Click **Approve**
   - Watch production deployment

### Step 5.3: Verify Resources in GCP

**Check Dev Environment**:

```bash
# List VMs in dev
gcloud compute instances list --project=terraform-demo-dev

# Should show 1 instance: dev-vm-1
```

**Check Staging Environment**:

```bash
# List VMs in staging
gcloud compute instances list --project=terraform-demo-staging

# Should show 2 instances: staging-vm-1, staging-vm-2
```

**Check Production Environment**:

```bash
# List VMs in prod
gcloud compute instances list --project=terraform-demo-prod

# Should show 3 instances: prod-vm-1, prod-vm-2, prod-vm-3
```

### Step 5.4: Review Deployment History

1. **Go to Environments**:
   - Navigate to **Pipelines** → **Environments**

2. **Check Each Environment**:
   - Click on `terraform-dev`
   - View deployment history
   - See who deployed, when, and from which pipeline run
   - Repeat for staging and prod

---

## Troubleshooting

### Issue: "Backend initialization required"

**Symptom**: Pipeline fails with backend error

**Solution**:
```bash
# Verify bucket exists
gsutil ls gs://terraform-demo-dev-tfstate

# Check permissions
gcloud projects get-iam-policy terraform-demo-dev \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:terraform-pipeline@*"
```

### Issue: "Permission denied" on GCP

**Symptom**: Cannot create resources

**Solution**:
```bash
# Grant Editor role explicitly
gcloud projects add-iam-policy-binding terraform-demo-dev \
  --member="serviceAccount:terraform-pipeline@PROJECT.iam.gserviceaccount.com" \
  --role="roles/editor"
```

### Issue: Approval not triggering

**Symptom**: Production deploys without approval

**Solution**:
1. Check environment configuration
2. Verify approval is added to `terraform-prod` environment
3. Ensure pipeline uses correct environment name: `environment: 'terraform-prod'`

### Issue: Different environments deploying same config

**Symptom**: All environments look identical

**Solution**:
1. Verify each environment has correct `terraform.tfvars`
2. Check backend.tf points to different buckets
3. Ensure project_id is different in each tfvars

---

## 🎓 What You Learned

### Technical Skills

✅ **Multi-environment strategy** - Dev, Staging, Prod isolation  
✅ **Approval gates** - Manual review for critical environments  
✅ **Environment-specific configs** - tfvars per environment  
✅ **State isolation** - Separate state files per environment  
✅ **Reusable modules** - DRY principle in Terraform  
✅ **Deployment tracking** - Azure DevOps Environments  

### Best Practices

✅ **Principle of least privilege** - Service account permissions  
✅ **Infrastructure as Code** - Everything in version control  
✅ **Immutable deployments** - Fresh apply each time  
✅ **Audit trail** - Git commits + pipeline logs  
✅ **Change control** - Approvals for production  

---

## 🚀 Next Steps

### Enhance Your Pipeline

1. **Add Testing**:
   - Run `terraform test` in validate stage
   - Add integration tests after deployment

2. **Notifications**:
   - Slack/email notifications for failures
   - Approval request notifications

3. **Drift Detection**:
   - Scheduled pipeline to check for drift
   - Alert on manual changes

4. **Destroy Workflow**:
   - Create separate pipeline for teardown
   - Add extra approvals for destruction

### Production Enhancements

- **Branch Protection**: Require PR reviews before merging to main
- **CODEOWNERS**: Assign teams to approve infrastructure changes
- **Compliance Scanning**: Add tfsec or checkov
- **Cost Estimation**: Add Infracost integration
- **Change Management**: Link to JIRA/ServiceNow tickets

---

## 📚 Resources

- [Azure DevOps Environments](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/environments)
- [Terraform Backends](https://www.terraform.io/language/settings/backends/configuration)
- [GCP Service Accounts](https://cloud.google.com/iam/docs/service-accounts)
- [Terraform Workspaces](https://www.terraform.io/language/state/workspaces)

---

## 🔗 Navigation

- **Back**: [Lesson 07 README](../../README.md)
- **Basic Pipeline**: [Example 01](../01-basic-pipeline/README.md)
- **Course Home**: [← Main README](../../../README.md)

---

**Congratulations!** 🎉 You now have a production-ready multi-environment CI/CD pipeline!
