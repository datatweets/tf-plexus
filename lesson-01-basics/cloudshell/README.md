# Terraform in GCP Cloud Shell - Quick Start

Deploy a GCP VM directly from Cloud Shell - no local setup required!

## What This Creates

```
┌──────────────────────────────┐
│   GCP Compute Instance       │
│   • Name: cloudshell         │
│   • Type: e2-small           │
│   • OS: Debian 11            │
│   • Network: default         │
│   • Zone: us-central1-a      │
└──────────────────────────────┘
```

**Perfect for:** Learning Terraform without local installation

**Cost:** ~$12/month (or $0.016/hour) - Remember to destroy after testing!

---

## Quick Start (5 Steps)

### 1. Open Cloud Shell

Go to [Google Cloud Console](https://console.cloud.google.com) and click the **Cloud Shell** icon (top right)

### 2. Clone or Navigate to This Folder

```bash
# If cloning the repo
git clone <repo-url>
cd lesson-01-basics/cloudshell

# Or upload these files directly to Cloud Shell
```

### 3. Enable Compute API

```bash
gcloud services enable compute.googleapis.com
```

### 4. Set Your Project ID

```bash
# Get your project ID
PROJECT_ID=$(gcloud config get-value project)

# Create terraform.tfvars
echo "project_id = \"$PROJECT_ID\"" > terraform.tfvars

# Verify
cat terraform.tfvars
```

### 5. Deploy with Terraform

```bash
# Initialize Terraform (downloads GCP provider)
terraform init

# Preview what will be created
terraform plan

# Create the VM
terraform apply
# Type 'yes' when prompted

# Verify VM is running
gcloud compute instances list
```

---

## Clean Up (IMPORTANT!)

**Don't forget to destroy resources to avoid charges:**

```bash
terraform destroy
# Type 'yes' when prompted
```

Verify deletion:
```bash
gcloud compute instances list
```

---

## Why Cloud Shell?

| Advantage | Description |
|-----------|-------------|
| **Pre-authenticated** | No need to configure `gcloud auth` |
| **Terraform pre-installed** | Cloud Shell includes Terraform |
| **No local setup** | Work from any browser |
| **5GB persistent storage** | Your files survive sessions |
| **Free to use** | Cloud Shell itself is free |

---

## Understanding the Code

### main.tf Structure

```hcl
provider "google" {
  project = var.project_id     # Your GCP project
  region  = "us-central1"      # Default region
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string         # Value from terraform.tfvars
}

resource "google_compute_instance" "this" {
  name         = "cloudshell"  # VM name
  machine_type = "e2-small"    # 2 vCPU, 2GB RAM
  zone         = "us-central1-a"
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  
  network_interface {
    network = "default"        # Uses default VPC
  }
}
```

---

## Useful Commands

```bash
# Check Terraform version
terraform version

# Format code
terraform fmt

# Validate configuration
terraform validate

# Show current state
terraform show

# List resources in state
terraform state list

# SSH into the VM
gcloud compute ssh cloudshell --zone=us-central1-a
```

---

## Troubleshooting

**Error: "API has not been enabled"**
```bash
gcloud services enable compute.googleapis.com
```

**Error: "project_id is required"**
```bash
# Ensure terraform.tfvars exists and contains your project ID
cat terraform.tfvars
```

**Cloud Shell session expired**
```bash
# Your files are preserved. Just reconnect and continue
cd lesson-01-basics/cloudshell
terraform plan
```

---

## What You'll Learn

- ✅ Running Terraform without local installation
- ✅ Using Cloud Shell as a development environment
- ✅ Creating compute instances with Terraform
- ✅ Managing state files in Cloud Shell
- ✅ Terraform workflow: init → plan → apply → destroy

---

## Next Steps

- Try changing `machine_type` to `e2-micro` (cheaper)
- Add an `output` block to display the VM's internal IP
- Modify to create multiple VMs using `count`
- Add tags and labels to organize resources

**Continue to:** [tf-hello-world](../tf-hello-world/) for a more complete example with web server
