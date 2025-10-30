# Hands-On Lab: Multi-Environment CI/CD Pipeline with Azure DevOps and Terraform

---

## What You'll Learn

- Build a production-ready CI/CD pipeline from scratch using Azure Pipelines
- Deploy Terraform infrastructure to Google Cloud Platform
- Implement multi-environment deployment strategy (Dev → Staging → Prod)
- Configure manual approval gates for production deployments
- Use Terraform modules for reusable infrastructure code
- Manage environment-specific configurations with tfvars files
- Secure credentials using Azure DevOps Secure Files
- Track deployment history with Azure DevOps Environments

---

## Why This Matters

**CI/CD (Continuous Integration/Continuous Deployment):** Automates the process of building, testing, and deploying infrastructure. Instead of manually running `terraform apply`, the pipeline automatically validates, plans, and deploys your infrastructure on every git push.

**Multi-Environment Strategy:** Real-world applications require separate Dev, Staging, and Production environments. Each environment has different configurations (smaller VMs in dev, larger in prod) and different deployment policies (auto-deploy to dev, manual approval for prod).

**Infrastructure as Code:** Managing infrastructure through version-controlled files enables collaboration, code review, automated testing, and audit trails. Combined with CI/CD, it becomes a powerful DevOps practice.

**Azure DevOps + GCP:** This is a **hybrid cloud approach** - using Azure DevOps for CI/CD orchestration while deploying to GCP infrastructure. This pattern is common in enterprises that use different cloud providers for different purposes.

---

## Architecture Overview

```
Your Local Machine (VS Code)
    ↓ git push
Azure DevOps (Pipeline Orchestration)
    ↓ triggers
Microsoft-Hosted Agent (Ubuntu VM)
    ↓ executes Terraform
Google Cloud Platform
    ├── Dev Environment (1 VM, e2-micro, auto-deploy)
    ├── Staging Environment (2 VMs, e2-small, auto-deploy)
    └── Production Environment (3 VMs, e2-medium, manual approval required)
```

**What gets created:**
- 3 VPC networks (one per environment)
- 3 subnets with firewall rules
- 6 VM instances total (1 + 2 + 3)
- 3 GCS buckets for Terraform state
- Deployment tracking and approval workflows

---

## Table of Contents

1. [Section 1: Prerequisites and Setup](#section-1-prerequisites-and-setup)
2. [Section 2: Azure DevOps Configuration](#section-2-azure-devops-configuration)
3. [Section 3: GCP Setup](#section-3-gcp-setup)
4. [Section 4: Create Basic Validation Pipeline](#section-4-create-basic-validation-pipeline)
5. [Section 5: Build Terraform Modules](#section-5-build-terraform-modules)
6. [Section 6: Configure Environments](#section-6-configure-environments)
7. [Section 7: Complete Multi-Stage Pipeline](#section-7-complete-multi-stage-pipeline)
8. [Section 8: Deploy and Verify](#section-8-deploy-and-verify)
9. [Section 9: Test and Iterate](#section-9-test-and-iterate)
10. [Section 10: Cleanup](#section-10-cleanup)
11. [Discussion Questions](#discussion-questions)
12. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### You Need

- **Azure DevOps account** (free tier works: https://dev.azure.com)
- **Google Cloud account** with billing enabled
- **VS Code** installed (or any code editor)
- **Git** installed
- **gcloud CLI** installed and authenticated
- **Basic Terraform knowledge** (completed Lessons 1-5)

### Check Your Setup

```bash
# Verify Git
git --version

# Verify gcloud
gcloud --version
gcloud auth list

# Verify you have a GCP project
gcloud config get-value project
```

**If gcloud shows no project:**
```bash
# List available projects
gcloud projects list

# Set your project
gcloud config set project PROJECT_ID
```

---

## Section 1: Prerequisites and Setup

### Step 1.1: Verify Prerequisites

**Check your installations:**

```bash
# Verify Git
git --version
# Should show: git version 2.x.x

# Verify gcloud
gcloud --version
# Should show: Google Cloud SDK, gcloud CLI

# Check authentication
gcloud auth list
# Should show your email address with an asterisk (*)

# Check current project
gcloud config get-value project
# Should show: terraform-prj-476214 (or your project ID)
```

**If you need to set your project:**

```bash
# List available projects
gcloud projects list

# Set your project
gcloud config set project terraform-prj-476214
```

### Step 1.2: Create Azure DevOps Account (if needed)

1. Go to <https://dev.azure.com>
2. Sign in with Microsoft account (or create one)
3. **Free tier includes:**
   - 1,800 pipeline minutes/month
   - Unlimited private Git repos
   - 5 free users

---

## Section 2: Azure DevOps Configuration 

### Step 2.1: Create New Project

**In Azure DevOps:**

1. Click **+ New project** (top-right)
2. **Project name:** `terraform-gcp-cicd`
3. **Visibility:** Private
4. **Version control:** Git
5. Click **Create**

**Wait for project creation (5-10 seconds)**

### Step 2.2: Initialize Git Repository

**In Azure DevOps:**

1. Go to **Repos** → **Files**
2. If you see "Import" options, click **Initialize** at bottom
3. Check ☑️ **Add a README**
4. Click **Initialize**

### Step 2.3: Clone Repository to Local Machine

**Open your terminal and run:**

```bash
# Navigate to your projects folder
cd ~/terraform_projects

# Clone the repository (replace YOUR-ORG with your Azure DevOps org name)
git clone https://dev.azure.com/YOUR-ORG/terraform-gcp-cicd/_git/terraform-gcp-cicd

# Navigate into the repository
cd terraform-gcp-cicd

# Verify you're in the right place
git remote -v
# Should show Azure DevOps URLs
```

**To find YOUR-ORG:**

- Look at the URL in your browser: `https://dev.azure.com/YOUR-ORG/terraform-gcp-cicd`
- Or click your profile icon → "My profile" → Check the URL

### Step 2.4: Open in VS Code

```bash
# Open VS Code in this directory
code .
```

**Verify in VS Code:**

- You should see `README.md` in the file explorer
- Bottom-left corner shows `main` branch
- Source control icon shows your repo name

---

## Section 3: GCP Setup 

### Step 3.1: Enable Required APIs

```bash
# Set your project ID
export PROJECT_ID="terraform-prj-476214"

# Enable APIs
gcloud services enable compute.googleapis.com \
  storage-api.googleapis.com \
  cloudresourcemanager.googleapis.com \
  --project=$PROJECT_ID
```

**Wait for APIs to enable (30-60 seconds)**

### Step 3.2: Create GCS Buckets for Terraform State

```bash
# Create bucket for dev environment
gcloud storage buckets create gs://$PROJECT_ID-tfstate-dev \
  --location=us-central1 \
  --uniform-bucket-level-access

# Create bucket for staging environment
gcloud storage buckets create gs://$PROJECT_ID-tfstate-staging \
  --location=us-central1 \
  --uniform-bucket-level-access

# Create bucket for production environment
gcloud storage buckets create gs://$PROJECT_ID-tfstate-prod \
  --location=us-central1 \
  --uniform-bucket-level-access

# Verify buckets created
gcloud storage buckets list | grep tfstate
```

**Expected output:**

```text
gs://terraform-prj-476214-tfstate-dev/
gs://terraform-prj-476214-tfstate-staging/
gs://terraform-prj-476214-tfstate-prod/
```

### Step 3.3: Create Service Account for Azure Pipelines

```bash
# Create service account
gcloud iam service-accounts create azure-pipelines \
  --display-name="Azure Pipelines Terraform" \
  --project=$PROJECT_ID

# Grant permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:azure-pipelines@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:azure-pipelines@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

# Create and download key
gcloud iam service-accounts keys create ~/gcp-key.json \
  --iam-account=azure-pipelines@${PROJECT_ID}.iam.gserviceaccount.com

# Verify key file created
ls -lh ~/gcp-key.json
```

**Expected output:**

```text
-rw-------  1 user  staff   2.3K Dec 15 10:30 /Users/user/gcp-key.json
```

**⚠️ SECURITY WARNING:** This key file grants admin access to your GCP project. Never commit it to Git!

---

## Section 4: Create Basic Validation Pipeline 

Let's start with a simple pipeline that validates Terraform syntax.

### Step 4.1: Create Terraform Test Files

**In VS Code, create folder structure:**

1. Right-click in Explorer → **New Folder** → Name it `terraform`
2. Click the `terraform` folder

**Create File 1: main.tf**

In VS Code: Right-click `terraform` folder → **New File** → Name it `main.tf`

Copy-paste this content:

```hcl
# Simple test configuration to validate pipeline
terraform {
  required_version = ">= 1.9.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Simple VPC for testing
resource "google_compute_network" "test_vpc" {
  name                    = "test-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "test_subnet" {
  name          = "test-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.test_vpc.id
}
```

**Create File 2: variables.tf**

In VS Code: Right-click `terraform` folder → **New File** → Name it `variables.tf`

Copy-paste this content:

```hcl
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}
```

**Create File 3: outputs.tf**

In VS Code: Right-click `terraform` folder → **New File** → Name it `outputs.tf`

Copy-paste this content:

```hcl
output "vpc_id" {
  description = "VPC Network ID"
  value       = google_compute_network.test_vpc.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = google_compute_subnetwork.test_subnet.id
}
```

**Verify files created:**

In VS Code, your structure should look like:

```text
terraform-gcp-cicd/
├── README.md
└── terraform/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

### Step 4.2: Create Basic Pipeline File

**In VS Code, at the root of your project:**

Right-click in Explorer → **New File** → Name it `azure-pipelines-basic.yml`

Copy-paste this content:

```yaml
# Basic validation pipeline
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  TF_VERSION: '1.9.0'
  WORKING_DIR: '$(System.DefaultWorkingDirectory)/terraform'

stages:
  - stage: Validate
    displayName: 'Terraform Validation'
    jobs:
      - job: ValidateCode
        displayName: 'Validate Terraform Code'
        steps:
          - task: TerraformInstaller@1
            displayName: 'Install Terraform'
            inputs:
              terraformVersion: $(TF_VERSION)

          - script: |
              terraform fmt -check -recursive
            displayName: 'Check Formatting'
            workingDirectory: $(WORKING_DIR)

          - script: |
              terraform init -backend=false
            displayName: 'Initialize Terraform'
            workingDirectory: $(WORKING_DIR)

          - script: |
              terraform validate
            displayName: 'Validate Configuration'
            workingDirectory: $(WORKING_DIR)
```

**What this pipeline does:**

- **Trigger:** Runs on every push to `main` branch
- **Pool:** Uses Microsoft-hosted Ubuntu VM (free)
- **Validation steps:**
  1. Installs Terraform
  2. Checks code formatting
  3. Initializes Terraform (without backend)
  4. Validates configuration syntax

**Verify files created:**

Your structure should now look like:

```text
terraform-gcp-cicd/
├── README.md
├── azure-pipelines-basic.yml
└── terraform/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

### Step 4.3: Commit and Push

**In VS Code terminal:**

```bash
# Check status
git status

# Add all files
git add .

# Commit
git commit -m "Add basic validation pipeline"

# Push to Azure DevOps
git push origin main
```

**Verify push:**

```bash
git log --oneline -1
# Should show your commit
```

### Step 4.4: Create Pipeline in Azure DevOps

**In Azure DevOps:**

1. Go to **Pipelines** → **Pipelines**
2. Click **Create Pipeline** or **New pipeline**
3. **Where is your code?** → Select **Azure Repos Git**
4. **Select a repository** → Choose `terraform-gcp-cicd`
5. **Configure your pipeline** → Select **Existing Azure Pipelines YAML file**
6. **Path:** `/azure-pipelines-basic.yml`
7. Click **Continue**
8. Review the YAML, then click **Run**

**Watch the pipeline run:**

- Stage: Validate
  - Job: ValidateCode
    - ✅ Install Terraform
    - ✅ Check Formatting
    - ✅ Initialize Terraform
    - ✅ Validate Configuration

**Expected result:** Pipeline should succeed in 1-2 minutes

### Step 4.5: Verify Pipeline Success

**In Azure DevOps, check:**

1. Pipeline shows green checkmark ✅
2. All 4 steps completed successfully
3. Click on **Validate Configuration** step
4. Look for: "Success! The configuration is valid."

**If formatting check fails:**

```bash
# In VS Code terminal, format all Terraform files
terraform -chdir=terraform fmt -recursive

# Commit and push
git add .
git commit -m "Format Terraform files"
git push
```

☕ **Take a 2-minute break!** Your first pipeline is running automatically!

---

## Section 5: Build Terraform Modules 

Now let's create reusable Terraform modules for multi-environment deployments.

### Step 5.1: Create Module Structure

**In VS Code:**

1. Create folder: `terraform/modules`
2. Create folder: `terraform/modules/compute`

**Or using terminal:**

```bash
mkdir -p terraform/modules/compute
```

### Step 5.2: Create Compute Module Files

**File 1: modules/compute/main.tf**

In VS Code: Create file `terraform/modules/compute/main.tf`

Copy-paste this content:

```hcl
# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "${var.environment}-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.environment}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id

  private_ip_google_access = true
}

# Firewall rule - Allow SSH from IAP
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${var.environment}-allow-iap-ssh"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["${var.environment}-vm"]
}

# Firewall rule - Allow internal traffic
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.environment}-allow-internal"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["${var.environment}-vm"]
}

# VM Instances
resource "google_compute_instance" "vm" {
  count        = var.instance_count
  name         = "${var.environment}-vm-${count.index + 1}"
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id

  tags = ["${var.environment}-vm"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = var.disk_size
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id

    # Conditional external IP based on variable
    dynamic "access_config" {
      for_each = var.enable_external_ip ? [1] : []
      content {}
    }
  }

  metadata = {
    environment = var.environment
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}
```

**File 2: modules/compute/variables.tf**

In VS Code: Create file `terraform/modules/compute/variables.tf`

Copy-paste this content:

```hcl
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "zone" {
  description = "GCP Zone"
  type        = string
}

variable "subnet_cidr" {
  description = "Subnet CIDR range"
  type        = string
}

variable "instance_count" {
  description = "Number of VM instances"
  type        = number
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "machine_type" {
  description = "VM machine type"
  type        = string
  default     = "e2-micro"
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 10
}

variable "enable_external_ip" {
  description = "Enable external IP for VMs"
  type        = bool
  default     = false
}
```

**File 3: modules/compute/outputs.tf**

In VS Code: Create file `terraform/modules/compute/outputs.tf`

Copy-paste this content:

```hcl
output "vpc_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "vpc_id" {
  description = "VPC network ID"
  value       = google_compute_network.vpc.id
}

output "subnet_name" {
  description = "Subnet name"
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_cidr" {
  description = "Subnet CIDR range"
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}

output "vm_names" {
  description = "List of VM instance names"
  value       = google_compute_instance.vm[*].name
}

output "vm_internal_ips" {
  description = "List of VM internal IPs"
  value       = google_compute_instance.vm[*].network_interface[0].network_ip
}

output "vm_external_ips" {
  description = "List of VM external IPs (if enabled)"
  value       = [
    for vm in google_compute_instance.vm :
    length(vm.network_interface[0].access_config) > 0 ? vm.network_interface[0].access_config[0].nat_ip : "N/A"
  ]
}
```

**Verify module structure:**

```text
terraform-gcp-cicd/
├── README.md
├── azure-pipelines-basic.yml
└── terraform/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── modules/
        └── compute/
            ├── main.tf
            ├── variables.tf
            └── outputs.tf
```

---

## Section 6: Configure Environments

Let's create separate configurations for Dev, Staging, and Production.

### Step 6.1: Create Environment Structure

**In VS Code terminal:**

```bash
mkdir -p terraform/environments/{dev,staging,prod}
```

**Verify folders created:**

```bash
ls -la terraform/environments/
# Should show: dev, staging, prod folders
```

### Step 6.2: Dev Environment Configuration

**File 1: environments/dev/main.tf**

In VS Code: Create file `terraform/environments/dev/main.tf`

Copy-paste this content:

```hcl
module "dev_infrastructure" {
  source = "../../modules/compute"

  project_id         = var.project_id
  environment        = "dev"
  region             = var.region
  zone               = var.zone
  subnet_cidr        = "10.0.1.0/24"
  instance_count     = 1
  machine_type       = "e2-micro"
  disk_size          = 10
  enable_external_ip = true
}
```

**File 2: environments/dev/variables.tf**

In VS Code: Create file `terraform/environments/dev/variables.tf`

Copy-paste this content:

```hcl
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}
```

**File 3: environments/dev/terraform.tfvars**

In VS Code: Create file `terraform/environments/dev/terraform.tfvars`

Copy-paste this content (update PROJECT_ID):

```hcl
project_id = "terraform-prj-476214"
region     = "us-central1"
zone       = "us-central1-a"
```

**File 4: environments/dev/backend.tf**

In VS Code: Create file `terraform/environments/dev/backend.tf`

Copy-paste this content (update PROJECT_ID):

```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-prj-476214-tfstate-dev"
    prefix = "terraform/state"
  }
}
```

**File 5: environments/dev/outputs.tf**

In VS Code: Create file `terraform/environments/dev/outputs.tf`

Copy-paste this content:

```hcl
output "vpc_name" {
  description = "Dev VPC name"
  value       = module.dev_infrastructure.vpc_name
}

output "vm_names" {
  description = "Dev VM names"
  value       = module.dev_infrastructure.vm_names
}

output "vm_internal_ips" {
  description = "Dev VM internal IPs"
  value       = module.dev_infrastructure.vm_internal_ips
}
```

### Step 6.3: Staging Environment Configuration

**File 1: environments/staging/main.tf**

In VS Code: Create file `terraform/environments/staging/main.tf`

Copy-paste this content:

```hcl
module "staging_infrastructure" {
  source = "../../modules/compute"

  project_id         = var.project_id
  environment        = "staging"
  region             = var.region
  zone               = var.zone
  subnet_cidr        = "10.1.1.0/24"
  instance_count     = 2
  machine_type       = "e2-small"
  disk_size          = 20
  enable_external_ip = false
}
```

**File 2: environments/staging/variables.tf**

In VS Code: Create file `terraform/environments/staging/variables.tf`

Copy-paste this content:

```hcl
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-b"
}
```

**File 3: environments/staging/terraform.tfvars**

In VS Code: Create file `terraform/environments/staging/terraform.tfvars`

Copy-paste this content (update PROJECT_ID):

```hcl
project_id = "terraform-prj-476214"
region     = "us-central1"
zone       = "us-central1-b"
```

**File 4: environments/staging/backend.tf**

In VS Code: Create file `terraform/environments/staging/backend.tf`

Copy-paste this content (update PROJECT_ID):

```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-prj-476214-tfstate-staging"
    prefix = "terraform/state"
  }
}
```

**File 5: environments/staging/outputs.tf**

In VS Code: Create file `terraform/environments/staging/outputs.tf`

Copy-paste this content:

```hcl
output "vpc_name" {
  description = "Staging VPC name"
  value       = module.staging_infrastructure.vpc_name
}

output "vm_names" {
  description = "Staging VM names"
  value       = module.staging_infrastructure.vm_names
}

output "vm_internal_ips" {
  description = "Staging VM internal IPs"
  value       = module.staging_infrastructure.vm_internal_ips
}
```

### Step 6.4: Production Environment Configuration

**File 1: environments/prod/main.tf**

In VS Code: Create file `terraform/environments/prod/main.tf`

Copy-paste this content:

```hcl
module "prod_infrastructure" {
  source = "../../modules/compute"

  project_id         = var.project_id
  environment        = "prod"
  region             = var.region
  zone               = var.zone
  subnet_cidr        = "10.2.1.0/24"
  instance_count     = 3
  machine_type       = "e2-medium"
  disk_size          = 30
  enable_external_ip = false
}
```

**File 2: environments/prod/variables.tf**

In VS Code: Create file `terraform/environments/prod/variables.tf`

Copy-paste this content:

```hcl
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-c"
}
```

**File 3: environments/prod/terraform.tfvars**

In VS Code: Create file `terraform/environments/prod/terraform.tfvars`

Copy-paste this content (update PROJECT_ID):

```hcl
project_id = "terraform-prj-476214"
region     = "us-central1"
zone       = "us-central1-c"
```

**File 4: environments/prod/backend.tf**

In VS Code: Create file `terraform/environments/prod/backend.tf`

Copy-paste this content (update PROJECT_ID):

```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-prj-476214-tfstate-prod"
    prefix = "terraform/state"
  }
}
```

**File 5: environments/prod/outputs.tf**

In VS Code: Create file `terraform/environments/prod/outputs.tf`

Copy-paste this content:

```hcl
output "vpc_name" {
  description = "Production VPC name"
  value       = module.prod_infrastructure.vpc_name
}

output "vm_names" {
  description = "Production VM names"
  value       = module.prod_infrastructure.vm_names
}

output "vm_internal_ips" {
  description = "Production VM internal IPs"
  value       = module.prod_infrastructure.vm_internal_ips
}
```

### Step 6.5: Add .gitignore

**In VS Code, at project root:**

Create file `.gitignore`

Copy-paste this content:

```gitignore
# Terraform
**/.terraform/
**/.terraform.lock.hcl
**/*.tfstate
**/*.tfstate.backup
**/*.tfplan
**/*.tfvars.backup
**/crash.log
**/override.tf
**/override.tf.json

# GCP Credentials
gcp-key.json
**/service-account-*.json

# IDE
.vscode/
.idea/
*.swp
*.swo
```

### Step 6.6: Verify Complete Structure

**In VS Code, your final structure should be:**

```text
terraform-gcp-cicd/
├── .gitignore
├── README.md
├── azure-pipelines-basic.yml
└── terraform/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── modules/
    │   └── compute/
    │       ├── main.tf
    │       ├── variables.tf
    │       └── outputs.tf
    └── environments/
        ├── dev/
        │   ├── backend.tf
        │   ├── main.tf
        │   ├── outputs.tf
        │   ├── terraform.tfvars
        │   └── variables.tf
        ├── staging/
        │   ├── backend.tf
        │   ├── main.tf
        │   ├── outputs.tf
        │   ├── terraform.tfvars
        │   └── variables.tf
        └── prod/
            ├── backend.tf
            ├── main.tf
            ├── outputs.tf
            ├── terraform.tfvars
            └── variables.tf
```

**Check file count:**

```bash
find terraform -name "*.tf" -o -name "*.tfvars" | wc -l
# Should show: 24 files
```

☕ **Take a 3-minute break!** You've created a complete multi-environment Terraform structure!

---

## Section 7: Complete Multi-Stage Pipeline

Now let's create the full pipeline that deploys to all three environments with approval gates.

### Step 7.1: Configure Azure DevOps Secure Files

**Upload your GCP service account key:**

1. In Azure DevOps, go to **Pipelines** → **Library**
2. Click **Secure files** tab
3. Click **+ Secure file**
4. Upload `~/gcp-key.json` (the file you created in Section 3.3)
5. After upload, click on the file name
6. Check ☑️ **Authorize for use in all pipelines**
7. Click **Save**

**Verify:**

- File shows: `gcp-key.json`
- Status: Authorized for all pipelines

### Step 7.2: Create Variable Group

**In Azure DevOps:**

1. Go to **Pipelines** → **Library**
2. Click **+ Variable group**
3. **Variable group name:** `terraform-variables`
4. Click **+ Add** and add these variables:

| Variable Name | Value | Description |
|--------------|-------|-------------|
| `GCP_PROJECT_ID` | `terraform-prj-476214` | Your GCP project ID |
| `GCP_REGION` | `us-central1` | Default region |
| `TF_VERSION` | `1.9.0` | Terraform version |

5. Click **Save**

### Step 7.3: Create Azure DevOps Environments

**Create three environments for deployment tracking:**

1. Go to **Pipelines** → **Environments**
2. Click **Create environment** or **New environment**

**Environment 1: Dev**

- **Name:** `terraform-dev`
- **Description:** `Development environment - auto-deploy`
- **Resource:** None
- Click **Create**

**Environment 2: Staging**

- **Name:** `terraform-staging`
- **Description:** `Staging environment - auto-deploy`
- **Resource:** None
- Click **Create**

**Environment 3: Production (with approval gate)**

- **Name:** `terraform-prod`
- **Description:** `Production environment - requires approval`
- **Resource:** None
- Click **Create**
- After creation, click on `terraform-prod`
- Click **⋮** (three dots) → **Approvals and checks**
- Click **+ Add** → **Approvals**
- **Approvers:** Add yourself (click search and select your name)
- **Instructions for approvers:** `Review Terraform plan output before approving production deployment`
- **Minimum number of approvers:** `1`
- **Timeout:** `60` minutes
- Click **Create**

**Verify all three environments created:**

- `terraform-dev` (no checks)
- `terraform-staging` (no checks)
- `terraform-prod` (1 approval required)

### Step 7.4: Create Complete Pipeline File

**In VS Code, at project root:**

Create file `azure-pipelines.yml`

Copy-paste this complete pipeline:

```yaml
# Multi-Environment CI/CD Pipeline for Terraform on GCP
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: terraform-variables
  TF_IN_AUTOMATION: 'true'
  TF_INPUT: 'false'

stages:
  # Stage 1: Validate Terraform code
  - stage: Validate
    displayName: 'Validate Terraform'
    jobs:
      - job: ValidateCode
        displayName: 'Validate All Configurations'
        steps:
          - task: TerraformInstaller@1
            displayName: 'Install Terraform'
            inputs:
              terraformVersion: $(TF_VERSION)

          - task: DownloadSecureFile@1
            name: gcpKey
            displayName: 'Download GCP Key'
            inputs:
              secureFile: 'gcp-key.json'

          - script: |
              echo "Validating module structure..."
              terraform -chdir=terraform/modules/compute init -backend=false
              terraform -chdir=terraform/modules/compute validate
              terraform -chdir=terraform/modules/compute fmt -check
            displayName: 'Validate Compute Module'

          - script: |
              for env in dev staging prod; do
                echo "Validating $env environment..."
                terraform -chdir=terraform/environments/$env init -backend=false
                terraform -chdir=terraform/environments/$env validate
                terraform -chdir=terraform/environments/$env fmt -check
              done
            displayName: 'Validate All Environments'

  # Stage 2: Deploy to Dev
  - stage: DeployDev
    displayName: 'Deploy to Development'
    dependsOn: Validate
    jobs:
      - deployment: DeployDevInfra
        displayName: 'Deploy Dev Infrastructure'
        environment: 'terraform-dev'
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self

                - task: TerraformInstaller@1
                  displayName: 'Install Terraform'
                  inputs:
                    terraformVersion: $(TF_VERSION)

                - task: DownloadSecureFile@1
                  name: gcpKey
                  displayName: 'Download GCP Key'
                  inputs:
                    secureFile: 'gcp-key.json'

                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    terraform -chdir=terraform/environments/dev init \
                      -backend-config="bucket=$(GCP_PROJECT_ID)-tfstate-dev"
                  displayName: 'Terraform Init (Dev)'

                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    terraform -chdir=terraform/environments/dev plan \
                      -var="project_id=$(GCP_PROJECT_ID)" \
                      -out=tfplan
                  displayName: 'Terraform Plan (Dev)'

                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    terraform -chdir=terraform/environments/dev apply \
                      -auto-approve tfplan
                  displayName: 'Terraform Apply (Dev)'

                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    terraform -chdir=terraform/environments/dev output -json
                  displayName: 'Show Outputs (Dev)'

  # Stage 3: Deploy to Staging
  - stage: DeployStaging
    displayName: 'Deploy to Staging'
    dependsOn: DeployDev
    jobs:
      - deployment: DeployStagingInfra
        displayName: 'Deploy Staging Infrastructure'
        environment: 'terraform-staging'
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self

                - task: TerraformInstaller@1
                  displayName: 'Install Terraform'
                  inputs:
                    terraformVersion: $(TF_VERSION)

                - task: DownloadSecureFile@1
                  name: gcpKey
                  displayName: 'Download GCP Key'
                  inputs:
                    secureFile: 'gcp-key.json'

                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    terraform -chdir=terraform/environments/staging init \
                      -backend-config="bucket=$(GCP_PROJECT_ID)-tfstate-staging"
                  displayName: 'Terraform Init (Staging)'

                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    terraform -chdir=terraform/environments/staging plan \
                      -var="project_id=$(GCP_PROJECT_ID)" \
                      -out=tfplan
                  displayName: 'Terraform Plan (Staging)'

                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    terraform -chdir=terraform/environments/staging apply \
                      -auto-approve tfplan
                  displayName: 'Terraform Apply (Staging)'

                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    terraform -chdir=terraform/environments/staging output -json
                  displayName: 'Show Outputs (Staging)'

  # Stage 4: Deploy to Production (requires manual approval)
  - stage: DeployProd
    displayName: 'Deploy to Production'
    dependsOn: DeployStaging
    jobs:
      - deployment: DeployProdInfra
        displayName: 'Deploy Production Infrastructure'
        environment: 'terraform-prod'  # Approval configured in Azure DevOps
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self

                - task: TerraformInstaller@1
                  displayName: 'Install Terraform'
                  inputs:
                    terraformVersion: $(TF_VERSION)

                - task: DownloadSecureFile@1
                  name: gcpKey
                  displayName: 'Download GCP Key'
                  inputs:
                    secureFile: 'gcp-key.json'

                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    terraform -chdir=terraform/environments/prod init \
                      -backend-config="bucket=$(GCP_PROJECT_ID)-tfstate-prod"
                  displayName: 'Terraform Init (Prod)'

                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    terraform -chdir=terraform/environments/prod plan \
                      -var="project_id=$(GCP_PROJECT_ID)" \
                      -out=tfplan
                  displayName: 'Terraform Plan (Prod)'

                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    terraform -chdir=terraform/environments/prod apply \
                      -auto-approve tfplan
                  displayName: 'Terraform Apply (Prod)'

                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    terraform -chdir=terraform/environments/prod output -json
                  displayName: 'Show Outputs (Prod)'
```

**What this pipeline does:**

**Stage 1: Validate (2-3 min)**

- Installs Terraform
- Downloads GCP credentials
- Validates module syntax
- Validates all environment configurations
- Checks code formatting

**Stage 2: Deploy Dev (3-4 min)**

- Runs automatically after validation
- Initializes Terraform with Dev backend
- Creates plan
- Auto-applies changes
- Shows outputs (VPC, VMs created)

**Stage 3: Deploy Staging (4-5 min)**

- Runs automatically after Dev succeeds
- Initializes Terraform with Staging backend
- Creates plan
- Auto-applies changes
- Shows outputs

**Stage 4: Deploy Production (5-6 min)**

- **Waits for manual approval** (you must approve in Azure DevOps)
- After approval, initializes Terraform with Prod backend
- Creates plan
- Auto-applies changes
- Shows outputs

### Step 7.5: Commit and Push

**In VS Code terminal:**

```bash
# Check what we're committing
git status

# Should show:
# - .gitignore (new)
# - azure-pipelines.yml (new)
# - terraform/modules/compute/* (new files)
# - terraform/environments/dev/* (new files)
# - terraform/environments/staging/* (new files)
# - terraform/environments/prod/* (new files)

# Add all files
git add .

# Commit
git commit -m "Add complete multi-environment pipeline and infrastructure"

# Push to Azure DevOps
git push origin main
```

**Wait for push to complete:**

```bash
# Verify commit pushed
git log --oneline -1
# Should show your commit message
```

---

## Section 8: Deploy and Verify

Let's run the complete pipeline and deploy all three environments!

### Step 8.1: Create and Run Pipeline

**In Azure DevOps:**

1. Go to **Pipelines** → **Pipelines**
2. Click **New pipeline** (or **Create Pipeline**)
3. **Where is your code?** → **Azure Repos Git**
4. **Select a repository:** `terraform-gcp-cicd`
5. **Configure your pipeline:** **Existing Azure Pipelines YAML file**
6. **Path:** `/azure-pipelines.yml`
7. Click **Continue**
8. **Review the pipeline YAML**
9. Click **Run**

**Alternate: If pipeline already exists from Section 4:**

1. Go to **Pipelines** → **Pipelines**
2. Find your existing pipeline
3. Click **⋮** (three dots) → **Edit**
4. Click **⋮** (top-right) → **Triggers**
5. Ensure trigger is set to `main` branch
6. Click **Run** → **Run**

### Step 8.2: Monitor Stage 1 - Validate 

**Watch the pipeline run:**

**Stage: Validate**

- Job: ValidateCode
  - ✅ Install Terraform
  - ✅ Download GCP Key
  - ✅ Validate Compute Module
  - ✅ Validate All Environments

**What it's checking:**

- Terraform syntax is correct
- All variables are defined
- Module references are valid
- Code is properly formatted

**If this stage fails:**

- Click on the failed step
- Read the error message
- Common issues:
  - Missing variable definitions
  - Typo in file names
  - Incorrect module path
  - Formatting issues (run `terraform fmt -recursive terraform/`)

### Step 8.3: Monitor Stage 2 - Deploy Dev 

**After Validate succeeds, Stage 2 starts automatically:**

**Stage: Deploy to Development**

- **Environment:** terraform-dev (auto-approved)
- Job: DeployDevInfra
  - ✅ Install Terraform
  - ✅ Download GCP Key
  - ✅ Terraform Init (Dev) - Initializes GCS backend
  - ✅ Terraform Plan (Dev) - Shows what will be created
  - ✅ Terraform Apply (Dev) - **Creates resources!**
  - ✅ Show Outputs (Dev) - Displays VPC name, VM names, IPs

**Click on "Terraform Plan (Dev)" to see:**

```text
Terraform will perform the following actions:

  # module.dev_infrastructure.google_compute_firewall.allow_iap_ssh will be created
  + resource "google_compute_firewall" "allow_iap_ssh" {
      + name    = "dev-allow-iap-ssh"
      + network = "dev-vpc"
      ...
    }

  # module.dev_infrastructure.google_compute_network.vpc will be created
  + resource "google_compute_network" "vpc" {
      + name = "dev-vpc"
      ...
    }

  # module.dev_infrastructure.google_compute_instance.vm[0] will be created
  + resource "google_compute_instance" "vm" {
      + name         = "dev-vm-1"
      + machine_type = "e2-micro"
      ...
    }

Plan: 5 to add, 0 to change, 0 to destroy.
```

**Click on "Show Outputs (Dev)" to see:**

```json
{
  "vm_internal_ips": {
    "value": ["10.0.1.2"]
  },
  "vm_names": {
    "value": ["dev-vm-1"]
  },
  "vpc_name": {
    "value": "dev-vpc"
  }
}
```

**Verify in GCP Console:**

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. **VPC networks** → Should see `dev-vpc`
3. **Compute Engine** → **VM instances** → Should see `dev-vm-1`

### Step 8.4: Monitor Stage 3 - Deploy Staging 

**After Dev succeeds, Staging starts automatically:**

**Stage: Deploy to Staging**

- **Environment:** terraform-staging (auto-approved)
- Similar steps as Dev
- **Creates:** 2 VMs (e2-small), staging-vpc

**Key differences from Dev:**

- 2 VM instances instead of 1
- e2-small machine type (vs e2-micro)
- 20 GB disk (vs 10 GB)
- No external IPs
- Different subnet: 10.1.1.0/24
- Different zone: us-central1-b

**Check outputs:**

```json
{
  "vm_internal_ips": {
    "value": ["10.1.1.2", "10.1.1.3"]
  },
  "vm_names": {
    "value": ["staging-vm-1", "staging-vm-2"]
  },
  "vpc_name": {
    "value": "staging-vpc"
  }
}
```

### Step 8.5: Manual Approval for Production (⏸️ ACTION REQUIRED)

**After Staging succeeds, pipeline PAUSES:**

**Stage: Deploy to Production**

- Status: **Waiting for approval**
- Message: "Waiting for approval terraform-prod"

**Review before approving:**

1. Click **Review** button (appears in pipeline view)
2. **Or** go to **Pipelines** → **Environments** → **terraform-prod** → Click pending deployment
3. **Review checklist:**
   - ✅ Dev deployment successful
   - ✅ Staging deployment successful
   - ✅ No errors in previous stages
   - ✅ Ready to create 3 production VMs
4. Click **Review** → **Approve** → Add comment (optional): "Reviewed and approved"
5. Click **Approve**

**What will be created in Production:**

- 3 VM instances (largest deployment)
- e2-medium machine type (most resources)
- 30 GB disks per VM
- Production VPC network
- Production subnet: 10.2.1.0/24
- Firewall rules

### Step 8.6: Monitor Stage 4 - Deploy Production 

**After you approve, Production deployment starts:**

**Stage: Deploy to Production**

- **Environment:** terraform-prod (approved by you)
- Similar steps as Dev/Staging
- **Creates:** 3 VMs (e2-medium), prod-vpc

**Check outputs:**

```json
{
  "vm_internal_ips": {
    "value": ["10.2.1.2", "10.2.1.3", "10.2.1.4"]
  },
  "vm_names": {
    "value": ["prod-vm-1", "prod-vm-2", "prod-vm-3"]
  },
  "vpc_name": {
    "value": "prod-vpc"
  }
}
```

### Step 8.7: Complete Verification

**Pipeline Complete!** All stages should show green checkmarks ✅

**Summary view should show:**

- ✅ Validate (2-3 min)
- ✅ Deploy to Development (3-4 min)
- ✅ Deploy to Staging (4-5 min)
- ✅ Deploy to Production (5-6 min) - After approval

**Total time:** ~18-22 minutes (including approval wait)

**Verify in GCP Console:**

```bash
# List all VPCs
gcloud compute networks list

# Should show:
# dev-vpc
# staging-vpc
# prod-vpc

# List all VMs
gcloud compute instances list

# Should show 6 VMs total:
# dev-vm-1 (e2-micro, us-central1-a)
# staging-vm-1, staging-vm-2 (e2-small, us-central1-b)
# prod-vm-1, prod-vm-2, prod-vm-3 (e2-medium, us-central1-c)

# Check Terraform state in buckets
gsutil ls gs://terraform-prj-476214-tfstate-dev/terraform/state/
gsutil ls gs://terraform-prj-476214-tfstate-staging/terraform/state/
gsutil ls gs://terraform-prj-476214-tfstate-prod/terraform/state/

# Each should show: default.tfstate
```

**In Azure DevOps:**

1. Go to **Pipelines** → **Environments**
2. Each environment should show:
   - **terraform-dev:** 1 deployment
   - **terraform-staging:** 1 deployment
   - **terraform-prod:** 1 deployment (approved by you)
3. Click each environment to see deployment history

☕ **Congratulations!** Take a 5-minute break! You've deployed a complete multi-environment infrastructure!

---

## Section 9: Test and Iterate 

Let's make a change and watch the pipeline automatically deploy it!

### Step 9.1: Make an Infrastructure Change

**Let's add a VM to the Dev environment:**

**In VS Code:** Open `terraform/environments/dev/main.tf`

**Change this line:**

```hcl
  instance_count     = 1
```

**To this:**

```hcl
  instance_count     = 2  # Changed from 1 to 2
```

**Save the file** (Cmd+S or Ctrl+S)

### Step 9.2: Commit and Push Change

**In VS Code terminal:**

```bash
# Check what changed
git diff terraform/environments/dev/main.tf

# Should show:
# -  instance_count     = 1
# +  instance_count     = 2

# Add and commit
git add terraform/environments/dev/main.tf
git commit -m "Scale dev environment to 2 VMs"

# Push
git push origin main
```

### Step 9.3: Watch Automatic Pipeline Trigger

**Pipeline automatically starts!**

**In Azure DevOps:**

1. Go to **Pipelines** → **Pipelines**
2. See new pipeline run starting
3. **Trigger:** Commit (your commit message)

**What will happen:**

- ✅ **Validate:** Passes (code still valid)
- ✅ **Deploy Dev:** Creates 1 additional VM (dev-vm-2)
  - Plan shows: `Plan: 1 to add, 0 to change, 0 to destroy`
- ✅ **Deploy Staging:** No changes (still 2 VMs)
  - Plan shows: `No changes. Your infrastructure matches the configuration.`
- ⏸️ **Deploy Prod:** Waits for approval (you don't need to approve if no Prod changes)

**Monitor the Dev deployment:**

Click on **Terraform Plan (Dev)** step:

```text
Terraform will perform the following actions:

  # module.dev_infrastructure.google_compute_instance.vm[1] will be created
  + resource "google_compute_instance" "vm" {
      + name         = "dev-vm-2"
      + machine_type = "e2-micro"
      + zone         = "us-central1-a"
      ...
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

**After deployment, verify:**

```bash
# List Dev VMs
gcloud compute instances list --filter="name:dev-vm*"

# Should now show:
# dev-vm-1
# dev-vm-2
```

### Step 9.4: Test Rollback Scenario

**Let's introduce an error and see pipeline catch it:**

**In VS Code:** Open `terraform/environments/dev/main.tf`

**Add an invalid parameter:**

```hcl
module "dev_infrastructure" {
  source = "../../modules/compute"

  project_id         = var.project_id
  environment        = "dev"
  region             = var.region
  zone               = var.zone
  subnet_cidr        = "10.0.1.0/24"
  instance_count     = 2
  machine_type       = "e2-micro"
  disk_size          = 10
  enable_external_ip = true
  invalid_parameter  = "this_will_fail"  # Add this line
}
```

**Commit and push:**

```bash
git add terraform/environments/dev/main.tf
git commit -m "Test validation failure"
git push origin main
```

**Watch pipeline fail at Validate stage:**

- ❌ **Validate:** Fails
- Error message: "An argument named 'invalid_parameter' is not expected here."
- **Deploy Dev:** Doesn't run (prevented by failure)
- **Deploy Staging:** Doesn't run
- **Deploy Prod:** Doesn't run

**Fix the error:**

```bash
# Remove the invalid line
# In VS Code, delete: invalid_parameter  = "this_will_fail"

git add terraform/environments/dev/main.tf
git commit -m "Fix validation error"
git push origin main
```

**Pipeline runs again and succeeds!**

### Step 9.5: View Deployment History

**In Azure DevOps:**

**Pipelines view:**

1. Go to **Pipelines** → **Pipelines**
2. See all runs:
   - Run #1: Initial deployment ✅
   - Run #2: Scale dev to 2 VMs ✅
   - Run #3: Validation failure ❌
   - Run #4: Fix and redeploy ✅

**Environments view:**

1. Go to **Pipelines** → **Environments** → **terraform-dev**
2. See deployment history with:
   - Timestamp
   - Pipeline run number
   - Commit message
   - Status

**Terraform state:**

```bash
# View dev state history
gsutil ls -l gs://terraform-prj-476214-tfstate-dev/terraform/state/

# Shows versioned state files (versioning enabled in Section 3)
```

---

## Section 10: Cleanup 

Let's destroy all resources to avoid charges.

### Step 10.1: Manual Terraform Destroy (Recommended)

**Using gcloud CLI:**

```bash
# Authenticate
export GOOGLE_APPLICATION_CREDENTIALS=~/gcp-key.json

# Destroy Dev
cd ~/path/to/terraform-gcp-cicd
terraform -chdir=terraform/environments/dev init
terraform -chdir=terraform/environments/dev destroy -var="project_id=terraform-prj-476214" -auto-approve

# Destroy Staging
terraform -chdir=terraform/environments/staging init
terraform -chdir=terraform/environments/staging destroy -var="project_id=terraform-prj-476214" -auto-approve

# Destroy Prod
terraform -chdir=terraform/environments/prod init
terraform -chdir=terraform/environments/prod destroy -var="project_id=terraform-prj-476214" -auto-approve
```

**Verify all resources deleted:**

```bash
# Should show empty
gcloud compute instances list
gcloud compute networks list | grep -E "(dev|staging|prod)-vpc"
```

### Step 10.2: Delete State Buckets

```bash
# Delete buckets
gsutil -m rm -r gs://terraform-prj-476214-tfstate-dev
gsutil -m rm -r gs://terraform-prj-476214-tfstate-staging
gsutil -m rm -r gs://terraform-prj-476214-tfstate-prod

# Verify deleted
gcloud storage buckets list | grep tfstate
# Should show nothing
```

### Step 10.3: Delete Service Account

```bash
# Delete service account
gcloud iam service-accounts delete \
  azure-pipelines@terraform-prj-476214.iam.gserviceaccount.com \
  --project=terraform-prj-476214

# Delete local key file
rm ~/gcp-key.json
```

### Step 10.4: Optional - Delete Azure DevOps Project

**If you want to clean up Azure DevOps:**

1. Go to **Project settings** (bottom-left)
2. Scroll to **Overview**
3. Click **Delete**
4. Type project name to confirm
5. Click **Delete**

☕ **Cleanup complete!** Your GCP account is clean and won't incur charges.

---

## Discussion Questions

Test your understanding of the concepts covered:

**1. CI/CD Concepts**

- Q: What's the difference between Continuous Integration and Continuous Deployment?
- Q: Why do we use approval gates for production but not for dev?
- Q: What would happen if we push directly to `main` without a pull request?

**2. Pipeline Architecture**

- Q: Why do stages run sequentially instead of in parallel?
- Q: What's the purpose of the Validate stage?
- Q: How does Azure DevOps know which YAML file to use?

**3. Terraform Best Practices**

- Q: Why do we use separate state buckets for each environment?
- Q: What's the advantage of using modules vs. duplicating code?
- Q: What happens if two pipeline runs try to apply to the same environment simultaneously?

**4. Security**

- Q: Why do we use Secure Files instead of committing the GCP key to Git?
- Q: What IAM roles does the service account need?
- Q: How would you rotate the service account key?

**5. Multi-Environment Strategy**

- Q: Why does Dev have 1 VM but Production has 3?
- Q: What's the benefit of deploying to staging before production?
- Q: How would you add a QA environment between Staging and Production?

**6. Troubleshooting**

- Q: Pipeline fails at "Terraform Init" - what would you check?
- Q: Production approval is stuck for hours - what happens?
- Q: Two developers push changes at the same time - what happens?

---

## Troubleshooting

Common issues and solutions:

### Issue 1: Pipeline fails at "Download GCP Key"

**Error:** `Could not find secure file gcp-key.json`

**Solution:**

1. Go to **Pipelines** → **Library** → **Secure files**
2. Verify `gcp-key.json` exists
3. Click on the file
4. Check ☑️ **Authorize for use in all pipelines**
5. Click **Save**
6. Re-run pipeline

### Issue 2: Terraform Init fails with "Bucket not found"

**Error:** `Error: Failed to get existing workspaces: storage: bucket doesn't exist`

**Solution:**

```bash
# Verify bucket exists
gsutil ls | grep tfstate

# If missing, create it
gsutil mb -l us-central1 gs://terraform-prj-476214-tfstate-dev

# Enable versioning
gsutil versioning set on gs://terraform-prj-476214-tfstate-dev
```

### Issue 3: Terraform Plan fails with "Invalid project ID"

**Error:** `Error: google: could not find default credentials`

**Solution:**

1. Go to **Pipelines** → **Library** → **Variable groups**
2. Check `terraform-variables` group
3. Verify `GCP_PROJECT_ID` is set correctly
4. Update if needed
5. Re-run pipeline

### Issue 4: Production approval timeout

**Error:** `The job was cancelled because the  environment approval timed out`

**Solution:**

- Approval timeout is 60 minutes (default)
- To change: **Environments** → `terraform-prod` → **Approvals** → **Edit** → Change timeout
- Or approve faster next time!

### Issue 5: Concurrent pipeline runs fail

**Error:** `Error acquiring the state lock`

**Solution:**

- Only one pipeline can modify an environment at a time
- Wait for current run to finish
- Or manually unlock:

```bash
terraform -chdir=terraform/environments/dev force-unlock LOCK_ID
```

### Issue 6: Module not found

**Error:** `Module not installed`

**Solution:**

- Check module path in `source` parameter
- Verify directory structure
- Run `terraform init` to download modules

### Issue 7: Formatting check fails

**Error:** `terraform fmt -check failed`

**Solution:**

```bash
# Format all Terraform files
terraform -chdir=terraform fmt -recursive

# Commit and push
git add .
git commit -m "Format Terraform files"
git push
```

---

## What's Next?

**You've successfully:**

✅ Built a complete CI/CD pipeline with Azure DevOps  
✅ Deployed multi-environment infrastructure to GCP  
✅ Implemented approval gates for production  
✅ Used Terraform modules for reusable code  
✅ Managed state with GCS backends  
✅ Automated deployments with Git triggers  

**Next steps to consider:**

1. **Add pull request validation:** Run `terraform plan` on PRs before merging
2. **Implement drift detection:** Scheduled pipeline to check for manual changes
3. **Add automated testing:** Use Terratest or kitchen-terraform
4. **Enable cost estimation:** Integrate Infracost to estimate costs
5. **Add policy enforcement:** Use Sentinel or OPA for compliance checks
6. **Implement branch strategies:** Feature branches, hotfix procedures
7. **Add notifications:** Slack/Teams notifications for deployment status

**Congratulations!** You now have production-ready CI/CD skills!

---

## Summary

**What You Built:**

- **Pipeline:** 4-stage automated deployment (Validate → Dev → Staging → Prod)
- **Infrastructure:** 6 VMs across 3 environments with separate VPCs
- **Automation:** Git push triggers automatic validation and deployment
- **Security:** Service account authentication, approval gates, secure file storage
- **Best Practices:** Modules, separate state, environment isolation

**Key Takeaways:**

1. **CI/CD automates manual work** - No more manual `terraform apply`
2. **Pipelines as Code** - YAML defines repeatable deployments
3. **Environment isolation** - Separate state and configurations
4. **Approval gates protect production** - Human review before critical changes
5. **Modules enable reusability** - Write once, deploy many times

**Time Investment vs. Value:**

- **Setup time:** 3-4 hours (one-time)
- **Deployment time after setup:** < 1 minute (git push)
- **Value:** Repeatable, auditable, automated infrastructure deployments

This is **Infrastructure as Code** in action! 🚀
4. Click **Save**

**Step 3: Create Environments**

1. Go to **Pipelines** → **Environments**
2. Click **+ New environment**

Create these three environments:

| Name | Description | Approval Required |
|------|-------------|-------------------|
| `terraform-dev` | Development - auto-deploy | No |
| `terraform-staging` | Staging - auto-deploy | No |
| `terraform-prod` | Production - requires approval | **Yes** |

**Configure Production Approval:**

1. Click on `terraform-prod`
2. Click **⋮** → **Approvals and checks**
3. Click **+ Add** → **Approvals**
4. **Approvers**: Add yourself
5. **Instructions**: "Review Terraform plan before approving production deployment"
6. **Minimum approvers**: 1
7. Click **Create**

---

## Part 3: Building Your First Pipeline

Start with a simple validation pipeline to understand the basics.

### 3.1: Create Directory Structure

```bash
cd terraform-gcp-cicd

# Create basic structure
mkdir -p terraform
cd terraform

# Create a simple test configuration
cat > main.tf << 'EOF'
terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc" {
  name                    = "${var.environment}-test-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
}

output "vpc_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}
EOF

cat > variables.tf << 'EOF'
# Variables are defined in main.tf for now
EOF

cat > outputs.tf << 'EOF'
# Outputs are defined in main.tf for now
EOF
```

### 3.2: Create Basic Pipeline

```bash
cd ..  # Back to repo root

cat > azure-pipelines-basic.yml << 'EOF'
# Basic Validation Pipeline
# This pipeline validates Terraform code without deploying

trigger:
  branches:
    include:
      - main
  paths:
    include:
      - '/*.tf'
      - '/azure-pipelines.yml'

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: terraform-variables
  - name: working_directory
    value: '$(System.DefaultWorkingDirectory)/terraform'

stages:
  - stage: Validate
    displayName: 'Validate Terraform Code'
    jobs:
      - job: ValidateJob
        displayName: 'Run Terraform Validation'
        steps:
          # Step 1: Install Terraform
          - script: |
              wget -O terraform.zip https://releases.hashicorp.com/terraform/$(TF_VERSION)/terraform_$(TF_VERSION)_linux_amd64.zip
              unzip terraform.zip
              sudo mv terraform /usr/local/bin/
              terraform version
            displayName: 'Install Terraform $(TF_VERSION)'
          
          # Step 2: Download GCP Credentials
          - task: DownloadSecureFile@1
            name: gcpKey
            displayName: 'Download GCP Service Account Key'
            inputs:
              secureFile: 'terraform-pipeline-key.json'
          
          # Step 3: Terraform Format Check
          - script: |
              cd $(working_directory)
              terraform fmt -check -recursive
            displayName: 'Check Terraform Formatting'
            continueOnError: true  # Don't fail on format issues
          
          # Step 4: Terraform Init (without backend)
          - script: |
              export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
              cd $(working_directory)
              terraform init -backend=false
            displayName: 'Terraform Init (No Backend)'
          
          # Step 5: Terraform Validate
          - script: |
              export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
              cd $(working_directory)
              terraform validate
            displayName: 'Terraform Validate'
          
          # Step 6: Success Message
          - script: |
              echo "=========================================="
              echo "✅ Terraform validation successful!"
              echo "=========================================="
            displayName: 'Validation Complete'
EOF
```

### 3.3: Test Basic Pipeline

```bash
# Commit and push
git add terraform/ azure-pipelines-basic.yml
git commit -m "Add basic validation pipeline"
git push origin main
```

**Create Pipeline in Azure DevOps:**

1. Go to **Pipelines** → **Pipelines**
2. Click **New pipeline**
3. Select **Azure Repos Git**
4. Select your repository
5. Select **Existing Azure Pipelines YAML file**
6. Path: `/azure-pipelines-basic.yml`
7. Click **Continue**
8. Click **Run**

**Watch the Pipeline:**
- Monitor each step
- Verify all steps complete successfully
- Check the logs for any warnings

---

## Part 4: Understanding Advanced Patterns

Now that you have a basic pipeline, let's learn advanced patterns.

### 4.1: Plan and Save Artifact Pattern

This pattern creates a plan and saves it for later deployment.

**Why This Matters:**
- Review changes before applying
- Ensure consistency between plan and apply
- Enable approval workflows

**Example:**

```yaml
stages:
  - stage: Plan
    jobs:
      - job: CreatePlan
        steps:
          - script: |
              terraform init
              terraform plan -out=tfplan
            displayName: 'Create Plan'
          
          - task: PublishPipelineArtifact@1
            displayName: 'Save Plan Artifact'
            inputs:
              targetPath: 'tfplan'
              artifact: 'terraform-plan'
  
  - stage: Apply
    dependsOn: Plan
    jobs:
      - job: ApplyPlan
        steps:
          - task: DownloadPipelineArtifact@2
            displayName: 'Download Plan'
            inputs:
              artifact: 'terraform-plan'
          
          - script: terraform apply tfplan
            displayName: 'Apply Saved Plan'
```

### 4.2: Matrix Strategy Pattern

Deploy to multiple environments in parallel.

**Use Case:** Deploy to all non-prod environments simultaneously.

```yaml
strategy:
  matrix:
    dev:
      environment: 'dev'
      project_id: 'project-dev'
      state_bucket: 'dev-tfstate'
    staging:
      environment: 'staging'
      project_id: 'project-staging'
      state_bucket: 'staging-tfstate'

steps:
  - script: |
      terraform init -backend-config="bucket=$(state_bucket)"
      terraform apply -var="project_id=$(project_id)" -auto-approve
    displayName: 'Deploy to $(environment)'
```

### 4.3: PR Validation Pattern

Run validation on pull requests without deploying.

```yaml
trigger: none  # Don't run on push

pr:
  branches:
    include:
      - main

stages:
  - stage: ValidatePR
    jobs:
      - job: Validate
        steps:
          - script: terraform validate
          - script: terraform plan
```

### 4.4: Environment-Specific Configuration Pattern

Different configs for different environments.

```yaml
stages:
  - stage: DeployDev
    variables:
      environment: 'dev'
      machine_type: 'e2-micro'
      instance_count: 1
  
  - stage: DeployProd
    variables:
      environment: 'prod'
      machine_type: 'e2-medium'
      instance_count: 3
```

---

## Part 5: Multi-Environment Architecture

Design your multi-environment infrastructure.

### 5.1: Directory Structure

Create a well-organized structure:

```bash
cd terraform-gcp-cicd

# Create directory structure
mkdir -p terraform/{modules/compute,environments/{dev,staging,prod}}

# Structure should look like:
# terraform/
# ├── modules/
# │   └── compute/
# │       ├── main.tf
# │       ├── variables.tf
# │       └── outputs.tf
# └── environments/
#     ├── dev/
#     │   ├── main.tf
#     │   ├── variables.tf
#     │   ├── terraform.tfvars
#     │   └── backend.tf
#     ├── staging/
#     │   └── (same files)
#     └── prod/
#         └── (same files)
```

### 5.2: Create Reusable Module

**File:** `terraform/modules/compute/main.tf`

```bash
cat > terraform/modules/compute/main.tf << 'EOF'
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "${var.environment}-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.environment}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id
}

# Firewall - Allow SSH
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.environment}-allow-ssh"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

# VM Instances
resource "google_compute_instance" "vm" {
  count        = var.instance_count
  name         = "${var.environment}-vm-${count.index + 1}"
  machine_type = var.machine_type
  zone         = "${var.region}-a"
  project      = var.project_id

  tags = [var.environment, "managed-by-terraform", "ssh"]

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
    deployed_by = "azure-pipelines"
  }

  metadata = {
    environment = var.environment
    enable-oslogin = "TRUE"
  }

  lifecycle {
    create_before_destroy = true
  }
}
EOF
```

**File:** `terraform/modules/compute/variables.tf`

```bash
cat > terraform/modules/compute/variables.tf << 'EOF'
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
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
  description = "Number of VM instances to create"
  type        = number
  default     = 1
  
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "machine_type" {
  description = "GCE machine type"
  type        = string
  default     = "e2-micro"
  
  validation {
    condition     = can(regex("^e2-(micro|small|medium|standard)", var.machine_type))
    error_message = "Machine type must be a valid e2 instance type."
  }
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 10
  
  validation {
    condition     = var.disk_size_gb >= 10 && var.disk_size_gb <= 100
    error_message = "Disk size must be between 10 and 100 GB."
  }
}
EOF
```

**File:** `terraform/modules/compute/outputs.tf`

```bash
cat > terraform/modules/compute/outputs.tf << 'EOF'
output "vpc_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "vpc_id" {
  description = "VPC network ID"
  value       = google_compute_network.vpc.id
}

output "subnet_name" {
  description = "Subnet name"
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_cidr" {
  description = "Subnet CIDR range"
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}

output "instance_names" {
  description = "VM instance names"
  value       = google_compute_instance.vm[*].name
}

output "instance_ids" {
  description = "VM instance IDs"
  value       = google_compute_instance.vm[*].id
}

output "instance_ips" {
  description = "VM external IP addresses"
  value       = google_compute_instance.vm[*].network_interface[0].access_config[0].nat_ip
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}
EOF
```

### 5.3: Create Environment Configurations

**Dev Environment:**

```bash
# Main configuration
cat > terraform/environments/dev/main.tf << 'EOF'
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
EOF

# Variables
cat > terraform/environments/dev/variables.tf << 'EOF'
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
EOF

# Variable values
cat > terraform/environments/dev/terraform.tfvars << 'EOF'
project_id     = "terraform-prj-476214"
environment    = "dev"
region         = "us-central1"
subnet_cidr    = "10.0.1.0/24"
instance_count = 1
machine_type   = "e2-micro"
disk_size_gb   = 10
EOF

# Backend configuration
cat > terraform/environments/dev/backend.tf << 'EOF'
terraform {
  backend "gcs" {
    bucket = "terraform-prj-476214-dev-tfstate"
    prefix = "terraform/state"
  }
}
EOF

# Outputs
cat > terraform/environments/dev/outputs.tf << 'EOF'
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
EOF
```

**Staging Environment:**

```bash
# Copy dev files
cp terraform/environments/dev/*.tf terraform/environments/staging/

# Update tfvars for staging
cat > terraform/environments/staging/terraform.tfvars << 'EOF'
project_id     = "terraform-prj-476214"
environment    = "staging"
region         = "us-central1"
subnet_cidr    = "10.1.1.0/24"
instance_count = 2
machine_type   = "e2-small"
disk_size_gb   = 20
EOF

# Update backend
cat > terraform/environments/staging/backend.tf << 'EOF'
terraform {
  backend "gcs" {
    bucket = "terraform-prj-476214-staging-tfstate"
    prefix = "terraform/state"
  }
}
EOF

# Update variables default
sed -i '' 's/default     = "dev"/default     = "staging"/g' terraform/environments/staging/variables.tf
sed -i '' 's/default     = "10.0.1.0\/24"/default     = "10.1.1.0\/24"/g' terraform/environments/staging/variables.tf
sed -i '' 's/default     = 1/default     = 2/g' terraform/environments/staging/variables.tf
sed -i '' 's/default     = "e2-micro"/default     = "e2-small"/g' terraform/environments/staging/variables.tf
```

**Production Environment:**

```bash
# Copy staging files
cp terraform/environments/staging/*.tf terraform/environments/prod/

# Update tfvars for production
cat > terraform/environments/prod/terraform.tfvars << 'EOF'
project_id     = "terraform-prj-476214"
environment    = "prod"
region         = "us-central1"
subnet_cidr    = "10.2.1.0/24"
instance_count = 3
machine_type   = "e2-medium"
disk_size_gb   = 50
EOF

# Update backend
cat > terraform/environments/prod/backend.tf << 'EOF'
terraform {
  backend "gcs" {
    bucket = "terraform-prj-476214-prod-tfstate"
    prefix = "terraform/state"
  }
}
EOF

# Update variables default
sed -i '' 's/default     = "staging"/default     = "prod"/g' terraform/environments/prod/variables.tf
sed -i '' 's/default     = "10.1.1.0\/24"/default     = "10.2.1.0\/24"/g' terraform/environments/prod/variables.tf
sed -i '' 's/default     = 2/default     = 3/g' terraform/environments/prod/variables.tf
sed -i '' 's/default     = "e2-small"/default     = "e2-medium"/g' terraform/environments/prod/variables.tf
```

---

## Part 6: Complete Implementation

Build the full multi-environment pipeline.

### 6.1: Create Complete Pipeline

```bash
cat > azure-pipelines.yml << 'EOF'
# Multi-Environment Terraform Pipeline
# Deploys to Dev, Staging, and Production with approval gates

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
  - group: terraform-variables
  - name: gcpServiceAccountFile
    value: 'terraform-pipeline-key.json'

stages:
  #############################################################################
  # STAGE 1: Validate All Environments
  #############################################################################
  - stage: Validate
    displayName: 'Validate Terraform'
    jobs:
      - job: ValidateAll
        displayName: 'Validate All Environments'
        steps:
          # Install Terraform
          - script: |
              wget -O terraform.zip https://releases.hashicorp.com/terraform/$(TF_VERSION)/terraform_$(TF_VERSION)_linux_amd64.zip
              unzip terraform.zip
              sudo mv terraform /usr/local/bin/
              terraform version
            displayName: 'Install Terraform $(TF_VERSION)'
          
          # Download GCP Credentials
          - task: DownloadSecureFile@1
            name: gcpKey
            displayName: 'Download GCP Service Account Key'
            inputs:
              secureFile: '$(gcpServiceAccountFile)'
          
          # Validate Module
          - script: |
              export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
              cd terraform/modules/compute
              terraform init -backend=false
              terraform validate
              echo "✅ Module validated successfully"
            displayName: 'Validate Compute Module'
          
          # Validate Dev
          - script: |
              export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
              cd terraform/environments/dev
              terraform init -backend=false
              terraform validate
              echo "✅ Dev environment validated"
            displayName: 'Validate Dev Environment'
          
          # Validate Staging
          - script: |
              export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
              cd terraform/environments/staging
              terraform init -backend=false
              terraform validate
              echo "✅ Staging environment validated"
            displayName: 'Validate Staging Environment'
          
          # Validate Prod
          - script: |
              export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
              cd terraform/environments/prod
              terraform init -backend=false
              terraform validate
              echo "✅ Production environment validated"
            displayName: 'Validate Production Environment'

  #############################################################################
  # STAGE 2: Deploy to Development
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
                
                # Install Terraform
                - script: |
                    wget -O terraform.zip https://releases.hashicorp.com/terraform/$(TF_VERSION)/terraform_$(TF_VERSION)_linux_amd64.zip
                    unzip terraform.zip
                    sudo mv terraform /usr/local/bin/
                    terraform version
                  displayName: 'Install Terraform'
                
                # Download GCP Credentials
                - task: DownloadSecureFile@1
                  name: gcpKey
                  displayName: 'Download GCP Key'
                  inputs:
                    secureFile: '$(gcpServiceAccountFile)'
                
                # Terraform Init, Plan, and Apply
                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    cd terraform/environments/dev
                    
                    echo "Initializing Terraform..."
                    terraform init
                    
                    echo "Creating plan..."
                    terraform plan \
                      -var="project_id=$(GCP_PROJECT_ID)" \
                      -var="region=$(GCP_REGION)" \
                      -out=tfplan
                    
                    echo "Applying plan..."
                    terraform apply -auto-approve tfplan
                    
                    echo "✅ Dev deployment complete"
                  displayName: 'Terraform Deploy Dev'
                
                # Save Outputs
                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    cd terraform/environments/dev
                    terraform output -json > $(Build.ArtifactStagingDirectory)/dev-outputs.json
                    cat $(Build.ArtifactStagingDirectory)/dev-outputs.json
                  displayName: 'Save Dev Outputs'
                
                # Publish Outputs
                - task: PublishPipelineArtifact@1
                  displayName: 'Publish Dev Outputs'
                  inputs:
                    targetPath: '$(Build.ArtifactStagingDirectory)'
                    artifact: 'dev-outputs'

  #############################################################################
  # STAGE 3: Deploy to Staging
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
                
                # Install Terraform
                - script: |
                    wget -O terraform.zip https://releases.hashicorp.com/terraform/$(TF_VERSION)/terraform_$(TF_VERSION)_linux_amd64.zip
                    unzip terraform.zip
                    sudo mv terraform /usr/local/bin/
                  displayName: 'Install Terraform'
                
                # Download GCP Credentials
                - task: DownloadSecureFile@1
                  name: gcpKey
                  displayName: 'Download GCP Key'
                  inputs:
                    secureFile: '$(gcpServiceAccountFile)'
                
                # Terraform Deploy
                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    cd terraform/environments/staging
                    
                    terraform init
                    terraform plan \
                      -var="project_id=$(GCP_PROJECT_ID)" \
                      -var="region=$(GCP_REGION)" \
                      -out=tfplan
                    
                    terraform apply -auto-approve tfplan
                    echo "✅ Staging deployment complete"
                  displayName: 'Terraform Deploy Staging'
                
                # Save Outputs
                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    cd terraform/environments/staging
                    terraform output -json > $(Build.ArtifactStagingDirectory)/staging-outputs.json
                  displayName: 'Save Staging Outputs'
                
                # Publish Outputs
                - task: PublishPipelineArtifact@1
                  displayName: 'Publish Staging Outputs'
                  inputs:
                    targetPath: '$(Build.ArtifactStagingDirectory)'
                    artifact: 'staging-outputs'

  #############################################################################
  # STAGE 4: Deploy to Production (Manual Approval Required)
  #############################################################################
  - stage: Production
    displayName: 'Deploy to Production'
    dependsOn: Staging
    condition: succeeded()
    jobs:
      - deployment: DeployProduction
        displayName: 'Deploy Production Environment'
        environment: 'terraform-prod'  # This triggers manual approval
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self
                
                # Install Terraform
                - script: |
                    wget -O terraform.zip https://releases.hashicorp.com/terraform/$(TF_VERSION)/terraform_$(TF_VERSION)_linux_amd64.zip
                    unzip terraform.zip
                    sudo mv terraform /usr/local/bin/
                  displayName: 'Install Terraform'
                
                # Download GCP Credentials
                - task: DownloadSecureFile@1
                  name: gcpKey
                  displayName: 'Download GCP Key'
                  inputs:
                    secureFile: '$(gcpServiceAccountFile)'
                
                # Terraform Deploy
                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    cd terraform/environments/prod
                    
                    terraform init
                    terraform plan \
                      -var="project_id=$(GCP_PROJECT_ID)" \
                      -var="region=$(GCP_REGION)" \
                      -out=tfplan
                    
                    terraform apply -auto-approve tfplan
                    echo "✅ Production deployment complete"
                  displayName: 'Terraform Deploy Production'
                
                # Save Outputs
                - script: |
                    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
                    cd terraform/environments/prod
                    terraform output -json > $(Build.ArtifactStagingDirectory)/prod-outputs.json
                  displayName: 'Save Production Outputs'
                
                # Publish Outputs
                - task: PublishPipelineArtifact@1
                  displayName: 'Publish Production Outputs'
                  inputs:
                    targetPath: '$(Build.ArtifactStagingDirectory)'
                    artifact: 'prod-outputs'
                
                # Deployment Summary
                - script: |
                    echo "========================================"
                    echo "🎉 PRODUCTION DEPLOYMENT SUCCESSFUL 🎉"
                    echo "========================================"
                    echo ""
                    echo "Environment: Production"
                    echo "Project: $(GCP_PROJECT_ID)"
                    echo "Region: $(GCP_REGION)"
                    echo ""
                    echo "Resources deployed:"
                    echo "  - 1 VPC network"
                    echo "  - 1 Subnet"
                    echo "  - 3 VM instances (e2-medium)"
                    echo "  - Firewall rules"
                    echo ""
                    echo "Check outputs above for resource details"
                    echo "========================================"
                  displayName: 'Deployment Summary'
EOF
```

### 6.2: Create .gitignore

```bash
cat > .gitignore << 'EOF'
# Terraform files
**/.terraform/
**/.terraform.lock.hcl
**/terraform.tfstate
**/terraform.tfstate.backup
**/.terraform.tfstate.lock.info
**/tfplan
**/tfplan.json
**/*.tfvars  # Commented out - we're tracking tfvars for this tutorial
**/.terraformrc
**/terraform.rc

# Credentials
**/*.json
!**/terraform-pipeline-key.json
**/credentials/
**/*.pem
**/*.key

# OS files
.DS_Store
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# Build artifacts
*.zip
*.tar.gz
EOF
```

---

## Part 7: Testing and Verification

### 7.1: Commit and Deploy

```bash
# Review your changes
git status

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
git push origin main
```

### 7.2: Monitor Pipeline Execution

**In Azure DevOps:**

1. **Go to Pipelines**
2. **Click on running pipeline**
3. **Watch Validate stage** (should take ~2 minutes)
   - Module validation
   - Dev validation
   - Staging validation
   - Prod validation

4. **Watch Dev deployment** (automatic, ~3-4 minutes)
   - Terraform init
   - Terraform plan
   - Terraform apply
   - Save outputs

5. **Watch Staging deployment** (automatic, ~4-5 minutes)
   - Similar to Dev
   - Should create 2 VMs instead of 1

6. **Production approval** (manual)
   - Stage will show "Waiting for approval"
   - Click **Review**
   - Review the plan output from previous stages
   - Click **Approve** (or **Reject**)
   - Add comment: "Reviewed and approved for production"

7. **Watch Production deployment** (~5-6 minutes)
   - Should create 3 VMs
   - Review deployment summary

### 7.3: Verify Resources in GCP

**Check Dev Environment:**

```bash
# List all resources in dev
gcloud compute networks list --project=terraform-prj-476214 --filter="name:dev-*"
gcloud compute instances list --project=terraform-prj-476214 --filter="name:dev-*"

# Expected:
# - 1 VPC: dev-vpc
# - 1 Subnet: dev-subnet
# - 1 VM: dev-vm-1 (e2-micro)
```

**Check Staging Environment:**

```bash
# List staging resources
gcloud compute networks list --project=terraform-prj-476214 --filter="name:staging-*"
gcloud compute instances list --project=terraform-prj-476214 --filter="name:staging-*"

# Expected:
# - 1 VPC: staging-vpc
# - 1 Subnet: staging-subnet
# - 2 VMs: staging-vm-1, staging-vm-2 (e2-small)
```

**Check Production Environment:**

```bash
# List production resources
gcloud compute networks list --project=terraform-prj-476214 --filter="name:prod-*"
gcloud compute instances list --project=terraform-prj-476214 --filter="name:prod-*"

# Expected:
# - 1 VPC: prod-vpc
# - 1 Subnet: prod-subnet
# - 3 VMs: prod-vm-1, prod-vm-2, prod-vm-3 (e2-medium)
```

**Get Detailed Information:**

```bash
# Get VM external IPs
gcloud compute instances list \
  --project=terraform-prj-476214 \
  --filter="labels.managed_by=terraform" \
  --format="table(name,zone,machineType,networkInterfaces[0].accessConfigs[0].natIP,status)"

# Check state files
gsutil ls -l gs://terraform-prj-476214-dev-tfstate/terraform/state/
gsutil ls -l gs://terraform-prj-476214-staging-tfstate/terraform/state/
gsutil ls -l gs://terraform-prj-476214-prod-tfstate/terraform/state/
```

### 7.4: Review Deployment History

**In Azure DevOps:**

1. Go to **Pipelines** → **Environments**
2. Click on each environment (dev, staging, prod)
3. Review:
   - Deployment history
   - Who deployed
   - When it was deployed
   - Which pipeline run
   - Approval history (for prod)

### 7.5: Test Changes and Redeployment

Make a small change to test the pipeline:

```bash
# Update dev machine type
cat > terraform/environments/dev/terraform.tfvars << 'EOF'
project_id     = "terraform-prj-476214"
environment    = "dev"
region         = "us-central1"
subnet_cidr    = "10.0.1.0/24"
instance_count = 1
machine_type   = "e2-small"  # Changed from e2-micro
disk_size_gb   = 10
EOF

# Commit and push
git add terraform/environments/dev/terraform.tfvars
git commit -m "test: Upgrade dev VM to e2-small"
git push origin main
```

**Watch the pipeline:**
- Should automatically trigger
- Only Dev should show changes
- Staging and Prod should show "No changes"

---

## Troubleshooting Guide

### Common Issues and Solutions

#### Issue 1: "Permission denied" on GCP

**Symptoms:**
```
Error: Error creating Network: googleapi: Error 403: Required 'compute.networks.create' permission
```

**Solution:**
```bash
# Verify service account has Editor role
export PROJECT_ID="terraform-prj-476214"
export SA_NAME="terraform-pipeline"

gcloud projects get-iam-policy ${PROJECT_ID} \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:${SA_NAME}@*"

# If not present, add it
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/editor"
```

#### Issue 2: "Backend initialization required"

**Symptoms:**
```
Error: Backend initialization required: please run "terraform init"
```

**Solution:**
```bash
# Verify buckets exist
gsutil ls | grep tfstate

# If missing, create them
export PROJECT_ID="terraform-prj-476214"
export REGION="us-central1"

for ENV in dev staging prod; do
  gsutil mb -p ${PROJECT_ID} -l ${REGION} gs://${PROJECT_ID}-${ENV}-tfstate
  gsutil versioning set on gs://${PROJECT_ID}-${ENV}-tfstate
done
```

#### Issue 3: Secure file not found

**Symptoms:**
```
##[error]Secure file not found: terraform-pipeline-key.json
```

**Solution:**
1. Go to **Pipelines** → **Library** → **Secure files**
2. Verify `terraform-pipeline-key.json` exists
3. Click on it → **Pipeline permissions**
4. Click **+** and authorize your pipeline

#### Issue 4: Production not requiring approval

**Symptoms:**
Production deploys automatically without approval

**Solution:**
1. Go to **Pipelines** → **Environments**
2. Click on `terraform-prod`
3. Click **⋮** → **Approvals and checks**
4. Verify approval is configured
5. Ensure pipeline YAML uses: `environment: 'terraform-prod'`

#### Issue 5: "Resource already exists"

**Symptoms:**
```
Error: A resource with the ID "projects/.../global/networks/dev-vpc" already exists
```

**Solution:**
```bash
# Check if resource exists
gcloud compute networks list --project=terraform-prj-476214

# Option 1: Import existing resource
cd terraform/environments/dev
terraform import google_compute_network.vpc projects/terraform-prj-476214/global/networks/dev-vpc

# Option 2: Delete and recreate
gcloud compute networks delete dev-vpc --project=terraform-prj-476214
```

#### Issue 6: State lock error

**Symptoms:**
```
Error: Error acquiring the state lock
```

**Solution:**
```bash
# Check for lock file
gsutil ls gs://terraform-prj-476214-dev-tfstate/terraform/state/

# If stuck, force unlock (use with caution!)
cd terraform/environments/dev
export GOOGLE_APPLICATION_CREDENTIALS=~/terraform-pipeline-key.json
terraform force-unlock <LOCK_ID>
```

#### Issue 7: Quota exceeded

**Symptoms:**
```
Error: Quota 'CPUS' exceeded. Limit: 24.0 in region us-central1
```

**Solution:**
```bash
# Check current usage
gcloud compute project-info describe --project=terraform-prj-476214

# Request quota increase in GCP Console
# Or reduce instance count/size in terraform.tfvars
```

---

## Best Practices Summary

### Pipeline Best Practices

✅ **Pin Terraform version** - Always use specific versions, not "latest"
```yaml
variables:
  terraformVersion: '1.9.0'  # Not 'latest'
```

✅ **Use variable groups** - Store sensitive values securely
```yaml
variables:
  - group: terraform-variables
```

✅ **Separate stages** - Validate before deploying
```yaml
stages:
  - Validate
  - Deploy
```

✅ **Use approval gates** - Require manual approval for production
```yaml
environment: 'terraform-prod'  # Has approval configured
```

✅ **Save outputs as artifacts** - Track what was deployed
```yaml
- task: PublishPipelineArtifact@1
```

✅ **Add display names** - Make logs readable
```yaml
displayName: 'Terraform Init - Dev Environment'
```

### Terraform Best Practices

✅ **Use modules** - DRY principle, reusable code
```hcl
module "infrastructure" {
  source = "../../modules/compute"
}
```

✅ **Environment-specific configs** - Separate tfvars per environment
```
environments/
  dev/terraform.tfvars
  staging/terraform.tfvars
  prod/terraform.tfvars
```

✅ **State isolation** - Separate state buckets per environment
```hcl
backend "gcs" {
  bucket = "project-dev-tfstate"  # Different per env
}
```

✅ **Use validations** - Catch errors early
```hcl
validation {
  condition     = contains(["dev", "staging", "prod"], var.environment)
  error_message = "Invalid environment"
}
```

✅ **Enable state versioning** - Recover from mistakes
```bash
gsutil versioning set on gs://bucket-name
```

✅ **Use labels and tags** - Track resources
```hcl
labels = {
  environment = var.environment
  managed_by  = "terraform"
}
```

### Security Best Practices

✅ **Never commit credentials** - Use secure files
```yaml
- task: DownloadSecureFile@1
  inputs:
    secureFile: 'terraform-pipeline-key.json'
```

✅ **Use service accounts** - Not user credentials
```bash
gcloud iam service-accounts create terraform-pipeline
```

✅ **Principle of least privilege** - Grant only necessary permissions
```bash
--role="roles/editor"  # Or more restrictive
```

✅ **Protect state files** - Use bucket permissions
```bash
gsutil iam ch serviceAccount:sa@project.iam:roles/storage.objectAdmin gs://bucket
```

✅ **Audit changes** - Git commits + pipeline logs provide audit trail

### Operational Best Practices

✅ **Small, frequent deployments** - Easier to troubleshoot
✅ **Test in dev first** - Never test in production
✅ **Use descriptive commit messages** - Explain WHY, not just WHAT
✅ **Monitor pipeline failures** - Set up notifications
✅ **Regular state backups** - State versioning enabled
✅ **Document your pipeline** - Future you will thank you

---

## What You've Accomplished

### Technical Skills Gained

✅ **Azure Pipelines YAML** - Master syntax and structure
✅ **Multi-stage pipelines** - Validate → Dev → Staging → Prod
✅ **Terraform modules** - Reusable infrastructure code
✅ **State management** - GCS backends with versioning
✅ **Environment isolation** - Separate configs per environment
✅ **Approval gates** - Manual control for production
✅ **Artifact management** - Pass data between stages
✅ **Variables and secrets** - Secure configuration management
✅ **GCP integration** - Service accounts and permissions

### Production-Ready Pipeline Features

✅ Multi-environment deployment (Dev, Staging, Prod)
✅ Automatic validation on every commit
✅ Manual approval for production changes
✅ Environment-specific configurations
✅ Isolated state management
✅ Audit trail (Git + Pipeline logs)
✅ Reusable infrastructure modules
✅ Secure credential management
✅ Deployment history tracking

---

## Next Steps

### Enhancements to Consider

**1. Add Testing**
```yaml
- stage: Test
  dependsOn: Dev
  jobs:
    - job: IntegrationTests
      steps:
        - script: |
            # Run tests against dev environment
            pytest tests/
```

**2. Add Drift Detection**
```yaml
schedules:
  - cron: "0 0 * * *"  # Daily at midnight
    branches:
      include:
        - main
    always: true

stages:
  - stage: DriftCheck
    jobs:
      - job: CheckDrift
        steps:
          - script: terraform plan -detailed-exitcode
```

**3. Add Cost Estimation**
```yaml
- script: |
    # Install Infracost
    curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh
    
    # Generate cost estimate
    infracost breakdown --path terraform/environments/prod
  displayName: 'Estimate Costs'
```

**4. Add Security Scanning**
```yaml
- script: |
    # Install tfsec
    curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
    
    # Scan for security issues
    tfsec terraform/ --format json
  displayName: 'Security Scan'
```

**5. Add Notifications**
```yaml
- task: SlackNotification@1
  condition: failed()
  inputs:
    message: 'Pipeline failed in $(System.StageName) stage'
```

### Continue Learning

- **Lesson 08**: Advanced Terraform (if available)
- **Projects**: Build real-world applications
- **Terraform Registry**: Explore community modules
- **Azure DevOps**: Advanced pipeline features
- **GCP**: Additional services and integrations

---

## Cleanup (When Done)

To avoid ongoing GCP charges:

```bash
# Destroy all environments
for ENV in dev staging prod; do
  echo "Destroying $ENV environment..."
  cd terraform/environments/$ENV
  
  export GOOGLE_APPLICATION_CREDENTIALS=~/terraform-pipeline-key.json
  terraform init
  terraform destroy -var="project_id=terraform-prj-476214" -auto-approve
  
  cd ../../..
done

# Delete state buckets
for ENV in dev staging prod; do
  gsutil -m rm -r gs://terraform-prj-476214-${ENV}-tfstate
done

# Delete service account
gcloud iam service-accounts delete \
  terraform-pipeline@terraform-prj-476214.iam.gserviceaccount.com \
  --project=terraform-prj-476214
```

---

## Congratulations! 🎉

You've successfully built a production-ready multi-environment CI/CD pipeline for Terraform!

You now have:
- A working understanding of Azure Pipelines
- Hands-on experience with multi-environment deployments
- A complete, deployable infrastructure pipeline
- Production-ready best practices

**This is a significant achievement!** You can use this as a foundation for real-world projects and as a portfolio piece to demonstrate your DevOps and Infrastructure as Code skills.

---

**Course Navigation:**
- [← Back to Lesson 07](./README.md)
- [← Main Course](../README.md)
