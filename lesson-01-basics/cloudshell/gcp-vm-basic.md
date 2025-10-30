# Running Terraform in Google Cloud Shell

This example demonstrates how to provision a Google Compute Engine VM instance using Terraform in Google Cloud Shell.

## Prerequisites

- Access to Google Cloud Shell (authentication is pre-configured)
- A Google Cloud Project with billing enabled

## Setup Instructions

### Step 1: Enable the Compute API

If your project is new and you haven't provisioned a VM yet, run the following command to enable the Compute Engine API:

```bash
gcloud services enable compute.googleapis.com
```

### Step 2: Configure Your Project ID

Find your GCP project ID:

```bash
gcloud config get-value project
```

Or list all available projects:

```bash
gcloud projects list
```

Create a `terraform.tfvars` file with your project ID:

```bash
cat > terraform.tfvars << EOF
# Replace with your actual GCP project ID
project_id = "your-project-id-here"
EOF
```

Replace `your-project-id-here` with your actual project ID from the previous command.

### Step 3: Check Terraform Version

Verify that Terraform is installed and check its version:

```bash
terraform --version
```

### Step 4: Initialize Terraform

Initialize the Terraform working directory. This will download the necessary provider plugins:

```bash
terraform init
```

### Step 5: Plan the Configuration

Review what resources Terraform will create:

```bash
terraform plan
```

This command shows you the execution plan without making any actual changes.

### Step 6: Apply the Configuration

Review and apply the Terraform configuration to provision the VM:

```bash
terraform apply
```

When prompted, type `yes` to approve the changes.

## What Gets Created

This configuration provisions:

- **Resource Type**: Google Compute Engine VM Instance
- **Name**: cloudshell
- **Machine Type**: e2-small
- **Zone**: us-central1-a
- **Operating System**: Debian 11
- **Network**: default VPC network

## Verify the Resources

After applying the configuration, you can:

1. View the VM in the Google Cloud Console under **Compute Engine > VM instances**
2. Use the following gcloud command to list instances:

```bash
gcloud compute instances list
```

## Clean Up

To destroy the resources created by Terraform:

```bash
terraform destroy
```

When prompted, type `yes` to confirm the deletion.

## Configuration Details

The `main.tf` file contains:

1. **Provider Configuration**: Specifies the Google Cloud provider and project settings
   - `provider "google"`: Configures the Google Cloud provider
   - `project`: Set via the `project_id` variable from `terraform.tfvars`
   - `region`: Default region for resources

2. **Variable Declaration**: Defines the project_id variable
   - `variable "project_id"`: Accepts the GCP project ID as input

3. **Resource Block**: Defines the VM instance
   - **resource type**: `google_compute_instance` - Specifies a Compute Engine VM
   - **resource name**: `this` - Local name to reference this resource
   - **name**: The actual name of the VM in Google Cloud
   - **machine_type**: Defines the VM's CPU and memory configuration
   - **zone**: The Google Cloud zone where the VM will be created
   - **boot_disk**: Configuration for the VM's boot disk, including the OS image
   - **network_interface**: Network configuration for the VM

The `terraform.tfvars` file contains your specific project configuration:

- **project_id**: Your GCP project ID (not committed to version control for security)

## Notes

- The `.tf` extension is mandatory for Terraform configuration files
- Google Cloud Shell comes pre-installed with Terraform and pre-configured authentication
- HCL (HashiCorp Configuration Language) is human-readable and used across HashiCorp tools
