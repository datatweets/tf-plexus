# Parameterizing Terraform: A Comprehensive Step-by-Step Tutorial

This tutorial will guide you through creating a parameterized Terraform configuration that deploys a web server on Google Cloud Platform.

## What You Will Build

By the end of this tutorial, you will have:
- A parameterized Terraform configuration using variables
- An automated web server running Apache
- A publicly accessible "Hello World" webpage
- Understanding of how to manage and override Terraform variables

## Prerequisites

- Completed GCP authentication setup (from the previous tutorial)
- Active GCP project with billing enabled
- Terminal access with gcloud and Terraform installed

## Project Structure

You will create the following files in your project directory:

```
~/terraform_projects/tf-plexus/tf-hello-world/
├── main.tf
├── outputs.tf
├── provider.tf
├── startup.sh
├── terraform.tfvars
└── variables.tf
```

## Step 1: Create Your Project Directory

Navigate to or create your Terraform project directory:

```bash
cd ~/terraform_projects/tf-plexus/tf-hello-world/
```

## Step 2: Create the Variables File

Create a file named `variables.tf` to declare all variables used in your configuration.

**File: variables.tf**

```hcl
variable "project_id" {
  type        = string
  description = "ID of the Google Project"
}

variable "region" {
  type        = string
  description = "Default Region"
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "Default Zone"
  default     = "us-central1-a"
}

variable "server_name" {
  type        = string
  description = "Name of server"
}

variable "machine_type" {
  type        = string
  description = "Machine Type"
  default     = "e2-micro"
}
```

**What This Does:**
- Declares five variables that will be used throughout your configuration
- Sets default values for region, zone, and machine_type
- Requires explicit values for project_id and server_name (no defaults)

## Step 3: Create the Provider Configuration

Create a file named `provider.tf` to configure the Google Cloud provider.

**File: provider.tf**

```hcl
provider "google" {
  project = var.project_id
  region  = var.region
}
```

**What This Does:**
- Configures Terraform to use the Google Cloud provider
- References the project_id and region variables using the `var.` prefix

## Step 4: Create the Main Configuration File

Create a file named `main.tf` that defines your compute instance resource.

**File: main.tf**

```hcl
resource "google_compute_instance" "this" {
  name         = var.server_name
  machine_type = var.machine_type
  zone         = var.zone
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  
  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }
  
  metadata_startup_script = file("startup.sh")
  tags                    = ["http-server"]
}
```

**What This Does:**
- Creates a Google Compute Engine instance
- Uses variables for name, machine type, and zone
- Configures a Debian 11 boot disk
- Assigns a public IP address through the `access_config` block
- Adds the `http-server` tag to allow HTTP traffic
- References a startup script that will run when the server boots

## Step 5: Create the Startup Script

Create a file named `startup.sh` that will configure the web server.

**File: startup.sh**

```bash
#! /bin/bash
apt update
apt -y install apache2
cat <<EOF > /var/www/html/index.html
<html><body><h1>Hello World!</h1></body></html>
EOF
```

**What This Does:**
- Updates package lists on the server
- Installs the Apache2 web server
- Creates a simple HTML page that displays "Hello World"

Make the script executable:

```bash
chmod +x startup.sh
```

## Step 6: Create the Outputs File

Create a file named `outputs.tf` to display useful information after deployment.

**File: outputs.tf**

```hcl
output "instance_ip_addr" {
  value = google_compute_instance.this.network_interface.0.access_config.0.nat_ip
}
```

**What This Does:**
- Extracts and displays the public IP address of the created instance
- This IP address will be shown after Terraform completes the deployment

## Step 7: Create the Variables Definition File

Create a file named `terraform.tfvars` to assign values to your variables.

**File: terraform.tfvars**

```hcl
project_id  = "terraform-prj-476214"
server_name = "hello-world-terraform"
```

**Important:** Replace `terraform-prj-476214` with your actual GCP project ID.

**What This Does:**
- Provides values for variables that don't have defaults
- Avoids the need to enter values interactively or via command-line flags

## Step 8: Ensure the HTTP Firewall Rule Exists

Before deploying, verify that the default HTTP firewall rule exists in your project.

### Check via gcloud:

```bash
gcloud compute firewall-rules list --filter="name=default-allow-http" --format=json
```

### If the rule doesn't exist, create it:

```bash
gcloud compute firewall-rules create default-allow-http \
  --allow tcp:80 \
  --source-ranges 0.0.0.0/0 \
  --target-tags http-server \
  --description "Allow HTTP traffic"
```

**What This Does:**
- Creates a firewall rule that allows incoming HTTP traffic on port 80
- Applies to instances with the `http-server` tag
- This is required for your web server to be accessible from the internet

## Step 9: Initialize Terraform

Initialize your Terraform working directory:

```bash
terraform init
```

**What This Does:**
- Downloads the Google Cloud provider plugin
- Prepares your directory for Terraform operations
- Creates a `.terraform` directory with necessary files

## Step 10: Review the Execution Plan

Preview what Terraform will create:

```bash
terraform plan
```

**What to Look For:**
- One resource to be created: `google_compute_instance.this`
- The values for all variables
- No errors in the configuration

## Step 11: Deploy the Infrastructure

Apply the Terraform configuration:

```bash
terraform apply
```

When prompted, type `yes` to confirm the deployment.

**What Happens:**
- Terraform creates the compute instance in your GCP project
- The startup script runs automatically, installing Apache
- After completion, Terraform displays the instance's public IP address

## Step 12: Test Your Web Server

After the deployment completes, you will see output similar to:

```
Outputs:

instance_ip_addr = "35.123.456.789"
```

Copy the IP address and paste it into your web browser:

```
http://35.123.456.789
```

**Note:** It may take 1-2 minutes for the startup script to complete. If you see a timeout error initially, wait a moment and refresh.

You should see the "Hello World!" message displayed in your browser.

## Step 13: Override Variables at Runtime

You can override any variable value using the `-var` flag without modifying your files.

### Deploy with a larger machine type:

First, destroy the existing instance:

```bash
terraform destroy
```

Type `yes` when prompted.

Then deploy with a different machine type:

```bash
terraform apply -var machine_type=e2-small
```

**What This Does:**
- Overrides the default `e2-micro` machine type
- Creates an instance with more resources (e2-small)
- All other variables remain unchanged

## Step 14: Verify Your Deployment in GCP Console

Visit the GCP Console to see your resources:

1. Navigate to https://console.cloud.google.com
2. Select your project (`terraform-prj-476214`)
3. Go to Compute Engine > VM instances
4. You should see your instance named `hello-world-terraform`

## Step 15: Clean Up Resources

To avoid incurring charges, destroy all created resources:

```bash
terraform destroy
```

Type `yes` when prompted.

**What This Does:**
- Removes all resources created by Terraform
- Deletes the compute instance and associated resources
- Your code remains intact for future use

Verify cleanup in the GCP Console:

1. Go to Compute Engine > VM instances
2. Confirm that your instance no longer appears

## Understanding Variable Assignment Methods

Terraform offers multiple ways to assign variable values, in order of precedence:

1. **Command-line flags**: `-var machine_type=e2-small` (highest precedence)
2. **terraform.tfvars file**: Automatic loading of variable values
3. **Environment variables**: `TF_VAR_machine_type=e2-small`
4. **Default values**: Specified in the variable declaration (lowest precedence)
5. **Interactive input**: Terraform prompts if no value is provided

## Key Concepts Explained

### Variables

Variables make your code reusable and flexible. Instead of hardcoding values, you declare variables and reference them using `var.variable_name`.

### Variable Types

The `type` argument specifies what kind of value the variable accepts:
- `string`: Text values like "us-central1"
- `number`: Numeric values like 3 or 100
- `bool`: True or false values
- `list`: Collections of values
- `map`: Key-value pairs

### Default Values

Variables with defaults are optional when running Terraform. Variables without defaults must be provided either in terraform.tfvars, via command-line flags, or interactively.

### Startup Scripts

The `metadata_startup_script` allows you to run commands when the instance first boots. This is useful for basic configuration tasks like installing software or configuring services.

### Network Tags

Tags like `http-server` are used by firewall rules to determine which instances receive specific network access permissions.

### Outputs

Output blocks display important information after Terraform completes. This is useful for retrieving IP addresses, database connection strings, or other values needed to use your infrastructure.

## Common Issues and Solutions

**Issue: Timeout when accessing the web server**
- Solution: Wait 1-2 minutes for the startup script to complete, then refresh your browser

**Issue: Connection refused**
- Solution: Verify the default-allow-http firewall rule exists using Step 8

**Issue: Variable not defined error**
- Solution: Ensure all required variables are defined in terraform.tfvars or provided via command line

**Issue: Authentication errors**
- Solution: Verify your Application Default Credentials are set correctly using `gcloud auth list`

## Best Practices

1. **Always use variables for values that might change** across environments or deployments
2. **Provide meaningful descriptions** for all variables to help other users understand their purpose
3. **Set sensible defaults** for variables that rarely change
4. **Use terraform.tfvars** for environment-specific values
5. **Run terraform destroy** when resources are no longer needed to avoid unnecessary costs
6. **Version control your code** but exclude terraform.tfvars if it contains sensitive information

## Recreating Resources

One of the benefits of Infrastructure as Code is reproducibility. If you need the server again:

```bash
terraform apply
```

Terraform will recreate the exact same infrastructure based on your configuration files.

## Summary

You have successfully:
- Created a parameterized Terraform configuration
- Deployed a web server to Google Cloud Platform
- Used variables to make your code flexible and reusable
- Automated server configuration with a startup script
- Retrieved outputs to access your deployed resources
- Learned how to override variables at runtime
- Cleaned up resources to avoid costs

This foundation prepares you for more complex Terraform configurations and infrastructure management tasks.