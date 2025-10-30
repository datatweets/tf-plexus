# Terraform Hello World - GCP Compute Instance

Quick example deploying a simple web server on Google Cloud Platform.

## What This Creates

```
┌─────────────────────────────┐
│   GCP Compute Instance      │
│   ┌─────────────────────┐   │
│   │   Apache Web Server │   │
│   │   "Hello World!"    │   │
│   └─────────────────────┘   │
│   • Debian 11               │
│   • e2-micro (Free tier)    │
│   • Public IP               │
└─────────────────────────────┘
```

**Resources:**
- 1x Compute Instance (VM)
- 1x Public IP address
- Apache web server serving "Hello World!"

**Cost:** ~$0 (fits in GCP free tier with e2-micro)

---

## Quick Start

### 1. Configure Variables

```bash
# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Required:**
```hcl
project_id  = "your-gcp-project-id"    # Your GCP project
server_name = "my-hello-world-vm"      # Name for the VM
```

**Optional (has defaults):**
```hcl
region       = "us-central1"           # Default: us-central1
zone         = "us-central1-a"         # Default: us-central1-a
machine_type = "e2-micro"              # Default: e2-micro (free tier)
```

### 2. Deploy

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy infrastructure
terraform apply
```

### 3. Access Your Server

After deployment completes, Terraform will output the public IP:

```bash
Outputs:
instance_ip_addr = "34.123.45.67"
```

Open in browser: `http://34.123.45.67`

You should see: **Hello World!**

### 4. Clean Up

```bash
# Destroy all resources
terraform destroy
```

---

## File Structure

| File | Purpose |
|------|---------|
| `main.tf` | Compute instance resource definition |
| `variables.tf` | Input variable declarations |
| `outputs.tf` | Output values (IP address) |
| `provider.tf` | GCP provider configuration |
| `startup.sh` | VM startup script (installs Apache) |
| `terraform.tfvars` | Your variable values (gitignored) |

---

## What You'll Learn

- ✅ Basic Terraform workflow (`init` → `plan` → `apply` → `destroy`)
- ✅ Creating GCP compute instances
- ✅ Using variables for configuration
- ✅ Using startup scripts for VM initialization
- ✅ Retrieving outputs (IP addresses)

---

## Troubleshooting

**Error: "project_id is required"**
```bash
# Ensure terraform.tfvars has your project_id
cat terraform.tfvars
```

**Error: "quota exceeded" or "insufficient permissions"**
```bash
# Verify you're authenticated and have necessary permissions
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

**Can't access web page**
```bash
# Wait 2-3 minutes for Apache to install
# Check VM is running in GCP Console
# Verify firewall allows HTTP (tag: http-server)
```

---

## Next Steps

- Try changing `machine_type` to see different VM sizes
- Modify `startup.sh` to customize the web page
- Experiment with `terraform plan` to preview changes
- Learn about state files (`terraform.tfstate`)

**Continue to:** [Complete Example](../complete-example/) for more advanced patterns
