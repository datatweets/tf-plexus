# Managing Environments with Remote State

A practical example demonstrating how to share data between infrastructure layers using `terraform_remote_state`. This approach enables layered architecture where different teams can manage different infrastructure components independently.

## 🎯 Learning Objectives

By completing this example, you will understand how to:

1. **Use terraform_remote_state** - Read outputs from other Terraform configurations
2. **Implement layered architecture** - Separate networking and compute layers
3. **Share data between layers** - Pass VPC/subnet info to compute layer
4. **Deploy layers independently** - Different teams, different lifecycles
5. **Maintain layer dependencies** - Ensure proper deployment order

## 🏗️ Architecture

### Layer Structure

```
remote-state/
├── modules/
│   ├── vpc/           # VPC module
│   └── server/        # Server module
└── layers/
    ├── 01-networking/ # Layer 1: VPC, subnets, firewall
    │   ├── dev/
    │   └── prod/
    └── 02-compute/    # Layer 2: Compute instances
        ├── dev/
        └── prod/
```

### Deployment Flow

```
┌──────────────────┐
│ 1. Networking    │  Outputs: VPC, subnets, firewall rules
│    Layer         │  Team: Network admins
└────────┬─────────┘
         │ terraform_remote_state
         ▼
┌──────────────────┐
│ 2. Compute       │  Inputs: Subnet self-links from layer 1
│    Layer         │  Team: Application team
└──────────────────┘
```

## 🔑 Key Concept: terraform_remote_state

The `terraform_remote_state` data source allows one Terraform configuration to read outputs from another:

**Networking Layer** exports outputs:
```hcl
# layers/01-networking/dev/outputs.tf
output "public_subnet_self_link" {
  value = "projects/.../subnetworks/dev-public-subnet"
}
```

**Compute Layer** imports those outputs:
```hcl
# layers/02-compute/dev/main.tf
data "terraform_remote_state" "networking" {
  backend = "gcs"
  config = {
    bucket = "my-state-bucket"
    prefix = "lesson-05/remote-state/dev/networking"
  }
}

# Use the imported data
module "web_server" {
  subnetwork = data.terraform_remote_state.networking.outputs.public_subnet_self_link
}
```

## 🚀 Quick Start

### Step 1: Deploy Networking Layer (Dev)

```bash
# Navigate to dev networking layer
cd layers/01-networking/dev

# Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project ID

# Deploy
terraform init
terraform apply

# Verify outputs (these will be consumed by compute layer)
terraform output public_subnet_self_link
terraform output private_subnet_self_link
```

### Step 2: Deploy Compute Layer (Dev)

```bash
# Navigate to dev compute layer
cd ../../02-compute/dev

# Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project ID

# Update backend bucket name in main.tf (line 21 and 36)
# Must match the bucket used in networking layer

# Deploy
terraform init
terraform apply

# Verify it reads networking layer
terraform output network_name  # From networking layer
```

### Step 3: Repeat for Production

```bash
# Deploy prod networking
cd ../../01-networking/prod
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply

# Deploy prod compute
cd ../../02-compute/prod
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
```

## 🧪 Experiments

### Experiment 1: Observe Layer Dependencies

```bash
# Try deploying compute before networking (will fail)
cd layers/02-compute/dev
terraform init
terraform plan

# Error: Unable to read remote state
# This proves compute layer depends on networking layer
```

### Experiment 2: Update Networking, See Compute

```bash
# Add a new firewall rule in networking layer
cd layers/01-networking/dev
# Edit: Add a firewall rule to modules/vpc/main.tf

terraform apply

# Check if compute layer needs updates
cd ../../02-compute/dev
terraform plan

# Should show no changes (compute doesn't depend on firewall rules)
```

### Experiment 3: Change Subnet CIDR

```bash
# Update subnet CIDR in networking layer
cd layers/01-networking/dev
# Edit main.tf: Change public_subnet_cidr to "10.0.10.0/24"

terraform apply

# This will recreate the subnet
# Now check compute layer
cd ../../02-compute/dev
terraform plan

# Compute instances must be recreated (network_interface changed)
```

### Experiment 4: View Remote State Data

```bash
cd layers/02-compute/dev
terraform console

# Query remote state outputs
> data.terraform_remote_state.networking.outputs
> data.terraform_remote_state.networking.outputs.public_subnet_self_link
> data.terraform_remote_state.networking.outputs.network_name
```

## 💡 Advantages

1. **Team Independence** - Different teams manage different layers
2. **Blast Radius Reduction** - Changes to networking don't auto-affect compute
3. **Clear Interfaces** - Explicit data contracts via outputs
4. **Flexible Deployment** - Deploy layers on different schedules
5. **Security Boundaries** - Different IAM permissions per layer

## 📊 Layer Comparison

### Dev Environment

**Layer 1 (Networking):**
- 1 VPC: `dev-vpc`
- 2 Subnets: public (10.0.1.0/24), private (10.0.2.0/24)
- 3 Firewall rules
- Cost: ~$0/month

**Layer 2 (Compute):**
- 1 Web server (micro, public subnet)
- 1 App server (small, private subnet)
- Cost: ~$26/month

### Prod Environment

**Layer 1 (Networking):**
- 1 VPC: `prod-vpc`
- 2 Subnets: public (10.1.1.0/24), private (10.1.2.0/24)
- 3 Firewall rules (SSH restricted)
- Cost: ~$0/month

**Layer 2 (Compute):**
- 2 Web servers (medium, public subnet)
- 2 App servers (large, private subnet)
- Cost: ~$220/month

## 🎓 What You've Learned

1. ✅ **terraform_remote_state** - Read outputs from other configurations
2. ✅ **Layered architecture** - Separate infrastructure by lifecycle
3. ✅ **Data sharing** - Pass data between independent Terraform runs
4. ✅ **Deployment order** - Understand layer dependencies
5. ✅ **Team collaboration** - Multiple teams, shared infrastructure

## 🧹 Cleanup

**Important:** Destroy in reverse order (dependencies!)

```bash
# 1. Destroy compute layers first
cd layers/02-compute/prod
terraform destroy

cd ../dev
terraform destroy

# 2. Then destroy networking layers
cd ../../01-networking/prod
terraform destroy

cd ../dev
terraform destroy
```

## 📚 Best Practices

1. **Deploy layers in order** - Networking → Compute
2. **Destroy in reverse order** - Compute → Networking
3. **Document dependencies** - Clear README per layer
4. **Version outputs** - Don't remove outputs that downstream layers use
5. **Use same backend** - All layers should use same state storage
6. **Test independently** - Each layer should have its own tests

## 🔄 Workflow

### Daily Operations

```bash
# Networking team updates firewall rules
cd layers/01-networking/prod
terraform apply

# App team deploys new servers
cd ../../02-compute/prod
terraform apply
```

### Adding New Layers

You can extend this pattern:

```
03-data/        # Database layer (depends on networking)
04-storage/     # Storage layer (independent)
05-monitoring/  # Monitoring layer (depends on compute)
```

Each layer uses `terraform_remote_state` to read from layers it depends on.

## 🎯 When to Use Remote State

**Good for:**
- Large organizations with multiple teams
- Infrastructure with different lifecycles
- Shared foundational infrastructure (VPCs, IAM)
- Reducing blast radius of changes

**Not needed for:**
- Small projects with one team
- Infrastructure deployed together
- Simple environments

## 🚀 Next Steps

- Explore [complete](../complete/) for multi-layer production architecture
- Compare with [directory-structure](../directory-structure/) approach
- Review [workspaces](../workspaces/) for simpler environments

---

**Time to Complete:** 2-3 hours

**Difficulty:** Advanced

**Best For:** Large teams managing shared infrastructure
