# Complete Production Environment Example

A comprehensive example demonstrating production-grade multi-layer Terraform architecture. This combines all concepts from previous examples: directory structure, modules, remote state, and layered deployment.

## 🎯 What This Demonstrates

This is the **most complete example** in Lesson 5, showing:

1. **4-Layer Architecture** - Networking → Data → Compute → Storage
2. **terraform_remote_state** - Layers communicate via remote state
3. **Module Reuse** - Shared modules across environments
4. **Environment Isolation** - Separate dev and prod
5. **Production Patterns** - Database, storage buckets, multi-tier servers

## 🏗️ Architecture

### Layer Structure

```
complete/
├── modules/
│   ├── vpc/              # VPC with subnets
│   ├── database/         # Cloud SQL (MySQL)
│   ├── server/           # Compute instances
│   └── storage/          # Cloud Storage buckets
└── layers/
    ├── 01-networking/    # VPC, subnets, firewall
    │   ├── dev/
    │   └── prod/
    ├── 02-data/          # Cloud SQL database
    │   ├── dev/
    │   └── prod/
    ├── 03-compute/       # Web + app servers
    │   ├── dev/
    │   └── prod/
    └── 04-storage/       # Storage buckets
        ├── dev/
        └── prod/
```

### Deployment Flow

```
Layer 1: Networking
   ↓ (outputs: VPC, subnets)
Layer 2: Data
   ↓ (outputs: DB connection info)
Layer 3: Compute
   ↓ (outputs: Server IPs)
Layer 4: Storage
   ✓ (uses networking for bucket)
```

## 📊 Environment Comparison

### Dev Environment

| Layer | Resources | Cost/Month |
|-------|-----------|------------|
| Networking | 1 VPC, 2 subnets, firewall | $0 |
| Data | 1 db-f1-micro MySQL | $10 |
| Compute | 1 web (micro), 1 app (small) | $26 |
| Storage | 1 bucket (10GB) | $0.26 |
| **Total** | **7 resources** | **~$36** |

### Production Environment

| Layer | Resources | Cost/Month |
|-------|-----------|------------|
| Networking | 1 VPC, 2 subnets, firewall | $0 |
| Data | 1 db-n1-standard-1 MySQL (HA) | $70 |
| Compute | 2 web (medium), 2 app (large) | $220 |
| Storage | 3 buckets (app, static, backups) | $5 |
| **Total** | **12 resources** | **~$295** |

## 🚀 Quick Start (Dev Environment)

### Prerequisites

1. GCP project with billing enabled
2. GCS bucket for Terraform state
3. Enable required APIs:
```bash
gcloud services enable compute.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable storage.googleapis.com
```

### Deploy All Layers

```bash
# Layer 1: Networking
cd layers/01-networking/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
terraform init && terraform apply

# Layer 2: Data
cd ../../02-data/dev
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply

# Layer 3: Compute
cd ../../03-compute/dev
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply

# Layer 4: Storage
cd ../../04-storage/dev
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply

# View final deployment
terraform output deployment_summary
```

## 🔑 Key Features

### 1. Layer Dependencies

**Layer 2 (Data)** reads from **Layer 1 (Networking)**:
```hcl
data "terraform_remote_state" "networking" {
  backend = "gcs"
  config = {
    bucket = "my-state"
    prefix = "complete/dev/networking"
  }
}

# Use VPC from networking layer
network = data.terraform_remote_state.networking.outputs.network_self_link
```

**Layer 3 (Compute)** reads from both **Layer 1** and **Layer 2**:
```hcl
# Get subnets from networking
subnetwork = data.terraform_remote_state.networking.outputs.public_subnet_self_link

# Get database connection from data layer
database_host = data.terraform_remote_state.data.outputs.db_private_ip
```

### 2. Unique Database Names

Uses `random_string` to ensure globally unique database names:
```hcl
resource "random_string" "db_suffix" {
  length  = 6
  special = false
  lower   = true
}

resource "google_sql_database_instance" "main" {
  name = "${var.environment}-mysql-${random_string.db_suffix.result}"
  # ...
}
```

### 3. Environment-Specific Sizing

**Dev:**
- Database: db-f1-micro (cheapest)
- Web: e2-micro
- App: e2-small
- 1 storage bucket

**Prod:**
- Database: db-n1-standard-1 with HA
- Web: e2-medium (×2)
- App: e2-standard-2 (×2)
- 3 storage buckets (app, static, backups)

## 🧪 Experiments

### Experiment 1: Full Deployment

Deploy the complete stack and observe layer dependencies:

```bash
# Deploy all 4 layers (takes ~15 minutes)
./deploy-all.sh dev

# Observe outputs at each layer
cd layers/01-networking/dev && terraform output
cd ../../02-data/dev && terraform output
cd ../../03-compute/dev && terraform output
cd ../../04-storage/dev && terraform output
```

### Experiment 2: Change Propagation

Make a change in the networking layer and see downstream effects:

```bash
# Change subnet CIDR
cd layers/01-networking/dev
# Edit: Change public_subnet_cidr

terraform apply

# Check if data layer needs update
cd ../../02-data/dev
terraform plan  # Likely no changes

# Check if compute layer needs update
cd ../../03-compute/dev
terraform plan  # Will show network_interface changes
```

### Experiment 3: Database Connection

Verify compute instances can connect to database:

```bash
# Get database connection info
cd layers/02-data/dev
terraform output db_connection_name
terraform output db_private_ip

# SSH to web server and test connection
gcloud compute ssh dev-web-server --zone=us-central1-a
mysql -h <db_private_ip> -u admin -p
```

### Experiment 4: Add Staging Environment

Create a staging environment between dev and prod:

```bash
# Copy dev directories
mkdir -p layers/01-networking/staging
cp layers/01-networking/dev/* layers/01-networking/staging/

# Edit backend prefixes to use "staging"
# Edit environment variables
# Adjust resource sizes (between dev and prod)

terraform init && terraform apply
```

## 💡 Production Patterns

### 1. Layered Architecture

Separating infrastructure into layers provides:
- **Clear ownership** - Different teams manage different layers
- **Reduced blast radius** - Changes to one layer don't auto-affect others
- **Flexible deployment** - Deploy layers independently

### 2. Immutable Infrastructure

Servers use startup scripts for configuration:
- Consistent deployment
- Easy rollback (destroy and recreate)
- No configuration drift

### 3. Infrastructure as Code

Everything is codified:
- Version controlled
- Peer reviewed
- Reproducible

## 🧹 Cleanup

**Critical:** Destroy in reverse order!

```bash
# Layer 4: Storage
cd layers/04-storage/dev
terraform destroy

# Layer 3: Compute
cd ../../03-compute/dev
terraform destroy

# Layer 2: Data (takes ~5 minutes)
cd ../../02-data/dev
terraform destroy

# Layer 1: Networking
cd ../../01-networking/dev
terraform destroy
```

Or use the cleanup script:
```bash
./cleanup.sh dev
```

## 📚 What You've Learned

1. ✅ **Multi-layer architecture** - 4-layer production pattern
2. ✅ **Layer dependencies** - terraform_remote_state between layers
3. ✅ **Database integration** - Cloud SQL with Terraform
4. ✅ **Storage integration** - GCS buckets
5. ✅ **Production sizing** - Environment-specific configurations
6. ✅ **Random resources** - Ensuring unique names
7. ✅ **Complete workflow** - Full deployment and teardown

## 🎓 Comparison with Other Examples

| Example | Layers | Remote State | Complexity | Best For |
|---------|--------|--------------|------------|----------|
| **workspaces** | 1 | No | Low | Simple multi-env |
| **directory-structure** | 1 | No | Medium | Independent envs |
| **remote-state** | 2 | Yes | Medium | Shared infrastructure |
| **complete** | 4 | Yes | High | Production deployments |

## 🚀 Next Steps

- Review layer-specific READMEs in each layer directory
- Deploy production environment
- Customize for your organization
- Add monitoring layer (layer 05)
- Implement CI/CD pipeline

---

**Time to Complete:** 3-4 hours

**Difficulty:** Advanced

**Best For:** Understanding complete production Terraform architecture
