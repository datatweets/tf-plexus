# Hands-On Lab: Deploy Dev & Prod GKE Clusters with Terraform

## Complete Lab with Workspaces | 40-50 Minutes

---

## What You'll Learn

- Use public Terraform modules to accelerate infrastructure creation
- Build custom VPCs with secondary IP ranges for Kubernetes
- Deploy two GKE environments (Dev and Prod) from a single codebase
- Separate environments using Terraform workspaces
- Understand zonal vs regional clusters
- Verify deployments with kubectl
- Clean up resources properly

**Time Estimate:** 40-50 minutes (cluster provisioning is the longest step)

---

## Why This Matters

**Kubernetes (K8s):** Automates container deployment, scaling, and management. Instead of manually managing hundreds of servers, you describe your desired state and Kubernetes makes it happen.

**GKE (Google Kubernetes Engine):** Google manages the control plane (master nodes, API server, scheduler) for you. You only manage worker nodes. Benefits include automatic upgrades, built-in monitoring, and integrated security.

**Terraform Public Modules:** Pre-built, production-ready infrastructure patterns maintained by Google and the community. Using modules reduces 200+ lines of configuration to ~50 lines while including security and operational best practices.

**Why Two Environments?**
- **Dev:** Zonal cluster with spot VMs (60-70% cheaper) for experimentation
- **Prod:** Regional cluster with standard VMs across 3 zones for high availability (99.95% SLA)

---

## Architecture Overview

```
Single Terraform Codebase
├── Dev Environment (Workspace)
│   ├── VPC: dev-gke-network
│   ├── GKE: dev-gke-cluster (zonal, 1 zone)
│   └── Nodes: 2 spot VMs (e2-small)
│
└── Prod Environment (Workspace)
    ├── VPC: prod-gke-network
    ├── GKE: prod-gke-cluster (regional, 3 zones)
    └── Nodes: 3 standard VMs (e2-medium, 1 per zone)
```

---

## Prerequisites

**You need:** A Google Cloud account with billing enabled

**You DO NOT need to install anything!** This lab uses **Google Cloud Shell** which comes with everything pre-installed:
- ✅ `gcloud` CLI (already authenticated)
- ✅ `terraform` (latest version)
- ✅ `kubectl` (Kubernetes command-line tool)

**To open Cloud Shell:**
1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Click the terminal icon (top-right) `>_` or Open Editor button `✎`
3. Wait for the shell to load (5-10 seconds)

**Optional - Cloud Shell Editor (VS Code):**
- Click `Open Editor` button to get a full VS Code interface
- File tree on left, terminal at bottom
- Better for viewing multiple files

---

## Section 1: Project Setup (2 minutes)

### Step 1.1: Set Up Working Directory

```bash
# Set your project
export PROJECT_ID=$(gcloud config get-value project)
echo "Project ID: $PROJECT_ID"

# Create working directory
mkdir ~/gke-lab && cd ~/gke-lab

# Enable required APIs
gcloud services enable compute.googleapis.com container.googleapis.com
```

**Wait for APIs to enable (30-60 seconds)**

---

## Section 2: Create Terraform Configuration (5 minutes)

Copy-paste each block to create all configuration files.

### File 1: versions.tf

```bash
cat > versions.tf << 'EOF'
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.51, < 7.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.11"
    }
  }
}
EOF
```

### File 2: providers.tf

```bash
cat > providers.tf << 'EOF'
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
EOF
```

### File 3: variables.tf

```bash
cat > variables.tf << 'EOF'
variable "project_id" { type = string }
variable "region"     { type = string }
variable "zone"       { type = string }

variable "network" {
  type = object({
    name                = string
    subnetwork_name     = string
    nodes_cidr_range    = optional(string, "10.128.0.0/20")
    pods_cidr_range     = optional(string, "10.4.0.0/14")
    services_cidr_range = optional(string, "10.8.0.0/20")
  })
}

variable "gke" {
  type = object({
    name     = string
    regional = bool
    zones    = list(string)
  })
}

variable "node_pool" {
  type = object({
    name               = string
    machine_type       = optional(string, "e2-small")
    spot               = bool
    initial_node_count = optional(number, 2)
    max_count          = optional(number, 4)
    disk_size_gb       = optional(number, 10)
  })
}

variable "service_account" {
  type = object({
    name  = string
    roles = list(string)
  })
  default = {
    name  = "gke-nodes-sa"
    roles = []
  }
}
EOF
```

### File 4: main.tf

```bash
cat > main.tf << 'EOF'
resource "google_project_service" "this" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com"
  ])
  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

resource "google_service_account" "this" {
  account_id   = var.service_account.name
  display_name = "GKE Nodes Service Account"
  project      = var.project_id
}

resource "google_project_iam_member" "sa_roles" {
  for_each = toset(var.service_account.roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.this.email}"
}
EOF
```

### File 5: vpc.tf

```bash
cat > vpc.tf << 'EOF'
module "vpc" {
  source      = "terraform-google-modules/network/google"
  version     = "~> 9.0"
  depends_on  = [google_project_service.this]

  project_id   = var.project_id
  network_name = var.network.name

  subnets = [
    {
      subnet_name           = var.network.subnetwork_name
      subnet_ip             = var.network.nodes_cidr_range
      subnet_region         = var.region
      subnet_private_access = "true"
    },
  ]

  secondary_ranges = {
    (var.network.subnetwork_name) = [
      {
        range_name    = "${var.network.subnetwork_name}-pods"
        ip_cidr_range = var.network.pods_cidr_range
      },
      {
        range_name    = "${var.network.subnetwork_name}-services"
        ip_cidr_range = var.network.services_cidr_range
      },
    ]
  }

  firewall_rules = [
    {
      name      = "${var.network.name}-allow-iap-ssh-ingress"
      direction = "INGRESS"
      ranges    = ["35.235.240.0/20"]
      allow     = [{ protocol = "tcp", ports = ["22"] }]
    },
  ]
}
EOF
```

### File 6: gke.tf

```bash
cat > gke.tf << 'EOF'
data "google_client_config" "default" {}

locals {
  subnetwork_name = module.vpc.subnets_names[0]
}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "~> 31.0"

  project_id = var.project_id
  region     = var.region

  name     = var.gke.name
  regional = var.gke.regional
  zones    = var.gke.zones

  network            = module.vpc.network_name
  subnetwork         = local.subnetwork_name
  ip_range_pods      = "${local.subnetwork_name}-pods"
  ip_range_services  = "${local.subnetwork_name}-services"

  service_account = google_service_account.this.email

  node_pools = [
    {
      name               = var.node_pool.name
      machine_type       = var.node_pool.machine_type
      disk_size_gb       = var.node_pool.disk_size_gb
      spot               = var.node_pool.spot
      initial_node_count = var.node_pool.initial_node_count
      min_count          = 1
      max_count          = var.node_pool.max_count
      disk_type          = "pd-ssd"
    },
  ]

  network_policy             = true
  horizontal_pod_autoscaling = true
  http_load_balancing        = true

  create_service_account   = false
  initial_node_count       = 1
  remove_default_node_pool = true
}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}
EOF
```

**Verify all files created:**
```bash
ls -la *.tf
# Should show: gke.tf, main.tf, providers.tf, variables.tf, versions.tf, vpc.tf
```

---

## Section 3: Create Environment Files (2 minutes)

### Dev Environment Configuration

```bash
cat > dev.tfvars << EOF
project_id = "$PROJECT_ID"
region     = "us-west1"
zone       = "us-west1-a"

network = {
  name            = "dev-gke-network"
  subnetwork_name = "us-west1"
}

gke = {
  name     = "dev-gke-cluster"
  regional = false
  zones    = ["us-west1-a"]
}

node_pool = {
  name = "dev-node-pool"
  spot = true
}

service_account = {
  name  = "dev-sa"
  roles = []
}
EOF
```

### Prod Environment Configuration

```bash
cat > prod.tfvars << EOF
project_id = "$PROJECT_ID"
region     = "us-west1"
zone       = "us-west1-a"

network = {
  name            = "prod-gke-network"
  subnetwork_name = "us-west1"
}

gke = {
  name     = "prod-gke-cluster"
  regional = true
  zones    = ["us-west1-a", "us-west1-b", "us-west1-c"]
}

node_pool = {
  name               = "prod-node-pool"
  spot               = false
  machine_type       = "e2-medium"
  initial_node_count = 3
  max_count          = 6
  disk_size_gb       = 50
}

service_account = {
  name  = "prod-sa"
  roles = []
}
EOF
```

**Verify environment files:**
```bash
ls -la *.tfvars
cat dev.tfvars | grep project_id
cat prod.tfvars | grep project_id
# Both should show your actual PROJECT_ID
```

---

## Section 4: Initialize and Create Workspaces (2 minutes)

```bash
# Initialize Terraform (downloads modules and providers)
terraform init

# Create workspaces for Dev and Prod
terraform workspace new dev
terraform workspace new prod

# List workspaces
terraform workspace list
```

**Expected output:**
```
  default
* dev
  prod
```

**What are workspaces?**
- Each workspace has its own state file
- Same Terraform code, different environments
- Prevents accidental cross-environment changes

---

## Section 5: Deploy Dev Environment (15-20 minutes)

```bash
# Switch to Dev workspace
terraform workspace select dev

# Preview what will be created
terraform plan -var-file=dev.tfvars

# Deploy Dev cluster
terraform apply -var-file=dev.tfvars
```

**Type `yes` when prompted**

**What's being created:**
- VPC network: dev-gke-network
- Subnet with secondary ranges for pods and services
- Service account for GKE nodes
- GKE zonal cluster in us-west1-a
- Node pool with 2 spot VMs (e2-small)
- Firewall rules for IAP SSH access

**Deployment timeline:**
- 0-2 min: VPC and networking
- 2-15 min: GKE cluster creation
- 15-20 min: Node pool provisioning
- **Total: ~15-20 minutes**

☕ **Grab coffee while waiting!**

**Monitor progress in Cloud Console:**
```bash
echo "https://console.cloud.google.com/kubernetes/list?project=$PROJECT_ID"
```

---

## Section 6: Validate Dev Cluster (2 minutes)

```bash
# Get cluster credentials
gcloud container clusters get-credentials dev-gke-cluster \
  --zone us-west1-a --project $PROJECT_ID

# Check nodes
kubectl get nodes

# View cluster info
kubectl cluster-info

# Check system pods
kubectl get pods -n kube-system

# View node details
kubectl get nodes -o wide
```

**Expected output for nodes:**
```
NAME                                          STATUS   ROLES    AGE   VERSION
gke-dev-gke-cluster-dev-node-pool-xxxxx-xxx   Ready    <none>   5m    v1.28.x
gke-dev-gke-cluster-dev-node-pool-xxxxx-xxx   Ready    <none>   5m    v1.28.x
```

**Key observations:**
- STATUS should be "Ready"
- 2 nodes (spot VMs)
- EXTERNAL-IP should be "<none>" (private nodes)

---

## Section 7: Deploy Prod Environment (20-25 minutes)

```bash
# Switch to Prod workspace
terraform workspace select prod

# Verify you're in Prod workspace
terraform workspace show

# Deploy Prod cluster
terraform apply -var-file=prod.tfvars
```

**Type `yes` when prompted**

**What's being created:**
- VPC network: prod-gke-network (separate from Dev)
- GKE regional cluster across 3 zones
- Node pool with 3 standard VMs (e2-medium, 1 per zone)
- Higher availability and capacity

**Deployment timeline:**
- 0-2 min: VPC and networking
- 2-18 min: Regional GKE cluster creation (slower than zonal)
- 18-25 min: Multi-zone node pool provisioning
- **Total: ~20-25 minutes**

☕ **More coffee time!**

---

## Section 8: Validate Prod Cluster (2 minutes)

```bash
# Get Prod cluster credentials
gcloud container clusters get-credentials prod-gke-cluster \
  --region us-west1 --project $PROJECT_ID

# Check nodes
kubectl get nodes

# Verify nodes are in different zones
kubectl get nodes -o custom-columns=NAME:.metadata.name,ZONE:.metadata.labels.'topology\.kubernetes\.io/zone'
```

**Expected output:**
```
NAME                                           ZONE
gke-prod-gke-cluster-prod-node-pool-xxxxx-xxx  us-west1-a
gke-prod-gke-cluster-prod-node-pool-xxxxx-xxx  us-west1-b
gke-prod-gke-cluster-prod-node-pool-xxxxx-xxx  us-west1-c
```

**Key observations:**
- 3 nodes (standard VMs, not spot)
- Distributed across 3 zones
- e2-medium (4 GB RAM vs 2 GB in Dev)

---

## Section 9: Compare Dev vs Prod (2 minutes)

### Switch Between Clusters

```bash
# List all kubectl contexts
kubectl config get-contexts

# Switch to Dev
kubectl config use-context gke_${PROJECT_ID}_us-west1-a_dev-gke-cluster
kubectl get nodes

# Switch to Prod
kubectl config use-context gke_${PROJECT_ID}_us-west1_prod-gke-cluster
kubectl get nodes
```

### Compare Node Capacity

```bash
# Dev nodes (e2-small: 2 vCPU, 2 GB RAM)
kubectl config use-context gke_${PROJECT_ID}_us-west1-a_dev-gke-cluster
kubectl describe node | grep -A 5 "Capacity:"

# Prod nodes (e2-medium: 2 vCPU, 4 GB RAM)
kubectl config use-context gke_${PROJECT_ID}_us-west1_prod-gke-cluster
kubectl describe node | grep -A 5 "Capacity:"
```

### View in Cloud Console

```bash
echo "Dev Cluster: https://console.cloud.google.com/kubernetes/clusters/details/us-west1-a/dev-gke-cluster/details?project=$PROJECT_ID"
echo "Prod Cluster: https://console.cloud.google.com/kubernetes/clusters/details/us-west1/prod-gke-cluster/details?project=$PROJECT_ID"
```

---

## Section 10: Test Application Deployment (3 minutes)

Deploy a sample app to Dev:

```bash
# Switch to Dev cluster
kubectl config use-context gke_${PROJECT_ID}_us-west1-a_dev-gke-cluster

# Deploy nginx
kubectl create deployment hello-dev --image=nginx:latest --replicas=2

# Expose as LoadBalancer
kubectl expose deployment hello-dev --type=LoadBalancer --port=80

# Wait for external IP (takes ~60 seconds)
kubectl get service hello-dev --watch
```

**Press Ctrl+C when EXTERNAL-IP appears**

```bash
# Test the application
EXTERNAL_IP=$(kubectl get service hello-dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$EXTERNAL_IP
```

**Expected:** HTML response from nginx

---

## Section 11: Cleanup - IMPORTANT! (5-7 minutes)

**You MUST destroy both environments to avoid charges.**

### Clean Up Dev

```bash
# Delete test app first (if deployed)
kubectl config use-context gke_${PROJECT_ID}_us-west1-a_dev-gke-cluster
kubectl delete service hello-dev
kubectl delete deployment hello-dev

# Wait for LoadBalancer to be removed
sleep 60

# Switch to Dev workspace
terraform workspace select dev

# Destroy Dev infrastructure
terraform destroy -var-file=dev.tfvars
```

**Type `yes` when prompted**

**Dev destruction takes ~5-7 minutes**

### Clean Up Prod

```bash
# Switch to Prod workspace
terraform workspace select prod

# Destroy Prod infrastructure
terraform destroy -var-file=prod.tfvars
```

**Type `yes` when prompted**

**Prod destruction takes ~7-10 minutes**

### Verify Cleanup

```bash
# Check no clusters remain
gcloud container clusters list --project $PROJECT_ID

# Check no VMs remain
gcloud compute instances list --project $PROJECT_ID

# Check VPCs
gcloud compute networks list --project $PROJECT_ID | grep gke
```

All commands should return empty or no gke-related resources.

---

## Discussion Questions

Reflect on what you learned:

**1. Why is a regional control plane better for production?**
- Control plane replicated across 3 zones
- Survives zone failures (99.95% SLA vs 99.5% zonal)
- Zero-downtime upgrades
- Worth the extra cost for production reliability

**2. What are the risks of spot (preemptible) nodes?**
- Google can terminate with 30-second notice
- Maximum 24-hour lifetime
- Workload disruption when preempted
- Good for: Dev/test, stateless apps with replicas
- Bad for: Databases, stateful workloads, single-replica services

**3. How did Terraform modules save time?**
- VPC module: Automated CIDR calculation, secondary ranges, firewall rules
- GKE module: Handled node pools, IAM, networking integration
- ~50 lines of code vs 200+ without modules
- Best practices built-in (security, logging, monitoring)

**4. When to use workspaces vs separate directories?**

**Use workspaces when:**
- Same architecture, different sizes
- Single team manages all environments
- Want to ensure consistency

**Use separate directories when:**
- Very different architectures
- Different teams own environments
- Regulatory requirements for separation
- Need separate CI/CD pipelines

---

## Bonus Lab A: Autoscaling & Self-Healing (5 minutes)

**Objective:** Enable cluster autoscaling and automatic node repair.

### Update gke.tf

```bash
# Edit gke.tf
cat > gke.tf << 'EOF'
data "google_client_config" "default" {}

locals {
  subnetwork_name = module.vpc.subnets_names[0]
}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "~> 31.0"

  project_id = var.project_id
  region     = var.region

  name     = var.gke.name
  regional = var.gke.regional
  zones    = var.gke.zones

  network            = module.vpc.network_name
  subnetwork         = local.subnetwork_name
  ip_range_pods      = "${local.subnetwork_name}-pods"
  ip_range_services  = "${local.subnetwork_name}-services"

  service_account = google_service_account.this.email

  node_pools = [
    {
      name               = var.node_pool.name
      machine_type       = var.node_pool.machine_type
      disk_size_gb       = var.node_pool.disk_size_gb
      spot               = var.node_pool.spot
      
      # Autoscaling
      min_count          = 1
      max_count          = var.node_pool.max_count
      initial_node_count = var.node_pool.initial_node_count
      
      # Self-healing
      auto_repair        = true
      auto_upgrade       = true
      
      disk_type          = "pd-ssd"
    },
  ]

  network_policy             = true
  horizontal_pod_autoscaling = true
  http_load_balancing        = true

  create_service_account   = false
  initial_node_count       = 1
  remove_default_node_pool = true
}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}
EOF
```

### Apply Changes

```bash
# Apply to Dev
terraform workspace select dev
terraform apply -var-file=dev.tfvars

# Apply to Prod
terraform workspace select prod
terraform apply -var-file=prod.tfvars
```

**What changed:**
- `auto_repair = true`: GKE automatically replaces unhealthy nodes
- `auto_upgrade = true`: GKE automatically upgrades nodes during maintenance windows
- `min_count = 1, max_count = X`: Cluster autoscaler adds/removes nodes based on pod demand

### Test Autoscaling (Optional)

```bash
# Create deployment that needs more resources
kubectl create deployment autoscale-test --image=nginx --replicas=20

# Watch nodes scale up
kubectl get nodes --watch

# Clean up
kubectl delete deployment autoscale-test
```

---

## Bonus Lab B: Private GKE Cluster (10 minutes)

**Objective:** Secure your cluster with private nodes and restricted API access.

### Add Cloud NAT for Private Nodes

```bash
cat > nat.tf << 'EOF'
resource "google_compute_router" "this" {
  name    = "${var.network.name}-router"
  region  = var.region
  network = module.vpc.network_name
}

resource "google_compute_router_nat" "this" {
  name   = "${var.network.name}-nat"
  router = google_compute_router.this.name
  region = var.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
EOF
```

### Update gke.tf for Private Cluster

Replace the `module "gke"` block in gke.tf:

```bash
cat > gke.tf << 'EOF'
data "google_client_config" "default" {}

locals {
  subnetwork_name = module.vpc.subnets_names[0]
}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "~> 31.0"

  project_id = var.project_id
  region     = var.region

  name     = var.gke.name
  regional = var.gke.regional
  zones    = var.gke.zones

  network            = module.vpc.network_name
  subnetwork         = local.subnetwork_name
  ip_range_pods      = "${local.subnetwork_name}-pods"
  ip_range_services  = "${local.subnetwork_name}-services"

  # Private cluster settings
  enable_private_nodes    = true
  enable_private_endpoint = false
  master_ipv4_cidr_block  = "172.16.0.16/28"

  master_authorized_networks = [
    {
      cidr_block   = "35.235.240.0/20"
      display_name = "Google Cloud IAP"
    },
  ]

  service_account = google_service_account.this.email

  node_pools = [
    {
      name               = var.node_pool.name
      machine_type       = var.node_pool.machine_type
      disk_size_gb       = var.node_pool.disk_size_gb
      spot               = var.node_pool.spot
      min_count          = 1
      max_count          = var.node_pool.max_count
      initial_node_count = var.node_pool.initial_node_count
      auto_repair        = true
      auto_upgrade       = true
      disk_type          = "pd-ssd"
    },
  ]

  network_policy             = true
  horizontal_pod_autoscaling = true
  http_load_balancing        = true

  create_service_account   = false
  initial_node_count       = 1
  remove_default_node_pool = true
}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}
EOF
```

### Apply Private Cluster Configuration

```bash
# Re-initialize to recognize nat.tf
terraform init

# Apply to Dev
terraform workspace select dev
terraform apply -var-file=dev.tfvars
```

**What changed:**
- `enable_private_nodes = true`: Nodes have no external IPs
- `enable_private_endpoint = false`: Control plane accessible from authorized networks
- `master_ipv4_cidr_block`: Private IP range for control plane
- `master_authorized_networks`: Only Cloud Shell (IAP range) can access API server
- Cloud NAT: Allows private nodes to pull images from internet

### Verify Private Configuration

```bash
# Check nodes have no external IPs
kubectl get nodes -o wide
# EXTERNAL-IP column should show <none>

# Test connectivity
kubectl get nodes
# Should work from Cloud Shell (authorized network)
```

---

## Troubleshooting

**Error: API not enabled**
```bash
gcloud services enable compute.googleapis.com container.googleapis.com
```

**Error: Quota exceeded**
- Check quotas in Console: IAM & Admin > Quotas
- Request increase or reduce node count in .tfvars

**Error: Terraform state locked**
```bash
terraform force-unlock <LOCK_ID>
```

**Nodes show "NotReady"**
- Wait 2-3 minutes for initialization
- Check with: `kubectl describe node <NODE_NAME>`

**kubectl connection refused**
- Verify you're in authorized network (Cloud Shell works)
- Check cluster is fully provisioned in Console

**Destroy hangs**
- Cancel with Ctrl+C
- Manually delete cluster in Console
- Retry: `terraform destroy -var-file=dev.tfvars`

---

## Summary

**What You Built:**
- 2 fully functional GKE clusters (Dev and Prod)
- Custom VPCs with proper Kubernetes networking
- Separate environments using Terraform workspaces
- Production-ready configuration with autoscaling and self-healing

**Key Takeaways:**
- Public Terraform modules dramatically reduce complexity
- Workspaces enable multi-environment management
- Regional clusters provide high availability for production
- Spot VMs reduce dev costs by 60-70%
- VPC-native GKE provides better performance and security

**Time Breakdown:**
- Setup: 2 min
- Configuration: 7 min
- Dev deployment: 15-20 min
- Prod deployment: 20-25 min
- Validation: 4 min
- Cleanup: 10-15 min
- **Total: 40-50 minutes**

**Next Steps:**
- Deploy real applications to your clusters
- Explore Helm for package management
- Set up CI/CD pipelines
- Implement monitoring and logging
- Learn about Workload Identity and service mesh

---

**Congratulations!** You've successfully deployed production-grade Kubernetes infrastructure using Terraform and Google Cloud best practices.