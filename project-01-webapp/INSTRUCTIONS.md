# Plexus Web Application - Step-by-Step Instructions
# Hands-On Project #1: Multi-Tier Infrastructure with Terraform

## 📋 Project Overview

**Scenario**: You're a DevOps engineer at **Plexus**, tasked with deploying a multi-tier web application on Google Cloud Platform. This project tests everything you've learned in Lessons 1-5.

**What You'll Build**:
- Custom VPC network with multiple subnets
- Load-balanced web servers (3 instances)
- PostgreSQL database with backups
- Cloud Storage buckets for assets and backups
- Separate dev and production environments

**Estimated Time**: 8-12 hours

## 🎯 Learning Objectives Checklist

By completing this project, you will demonstrate mastery of:

- [ ] **Lesson 1**: Resources, providers, variables, outputs, basic HCL syntax
- [ ] **Lesson 2**: Remote state management, count, for_each, depends_on, lifecycle
- [ ] **Lesson 3**: Complex data types, conditionals, functions, data sources, dynamic blocks
- [ ] **Lesson 4**: Custom module creation, module composition, input/output design
- [ ] **Lesson 5**: Environment management with directory structure

## 📁 Project Structure

```
student-version/
├── modules/              # Reusable infrastructure components
│   ├── networking/      # VPC, subnets, firewall rules
│   ├── compute/         # Web servers and load balancer
│   ├── database/        # Cloud SQL PostgreSQL
│   └── storage/         # Cloud Storage buckets
└── environments/        # Environment-specific configurations
    ├── dev/            # Development environment
    └── prod/           # Production environment
```

## 🚀 Prerequisites

Before starting, ensure you have:

1. **GCP Account** with billing enabled
2. **Project Created** in Google Cloud Console
3. **gcloud CLI** installed and authenticated
4. **Terraform** >= 1.0 installed
5. **APIs Enabled**:
   ```bash
   gcloud services enable compute.googleapis.com
   gcloud services enable sqladmin.googleapis.com
   gcloud services enable storage.googleapis.com
   ```
6. **Service Account** with appropriate permissions (or use your user account)

## 📝 Important Notes

⚠️ **Cost Warning**: This project will incur GCP charges (~$0.71 for 8 hours in dev)
💰 **Budget Tip**: Always destroy resources when not in use
🔒 **Security**: Never commit `terraform.tfvars` with real credentials to Git

---

# 🏗️ PHASE 1: BUILD THE NETWORKING MODULE (Lessons 1-3)

## Step 1: Understand the Networking Module Structure

**Time**: 15 minutes

**Objective**: Familiarize yourself with the networking module's purpose and structure.

**Tasks**:
1. Navigate to `student-version/modules/networking/`
2. Review `variables.tf` - understand the input variables
3. Read the TODO comments in `main.tf`
4. Note the three resources you'll create:
   - VPC network
   - Subnets (using for_each)
   - Firewall rules (using for_each + dynamic blocks)

**Validation**:
- [ ] Can you explain what each variable in `variables.tf` does?
- [ ] Do you understand the structure of the `subnets` map?
- [ ] Do you understand the structure of the `firewall_rules` map?

**Hints**:
- The subnets map has a structure like: `{ "subnet-name" = { cidr_range = "...", description = "..." } }`
- The firewall_rules map is more complex with nested `allow` blocks

---

## Step 2: Implement the VPC Network (TODO #1)

**Time**: 10 minutes

**Objective**: Create a custom VPC network resource.

**Concepts**: Basic resource blocks, variable referencing (Lesson 1)

**Implementation**:
1. Open `modules/networking/main.tf`
2. Find the `google_compute_network` resource block (TODO #1)
3. Implement the required attributes:
   ```hcl
   resource "google_compute_network" "vpc" {
     name                    = var.vpc_name
     project                 = var.project_id
     auto_create_subnetworks = false
   }
   ```

**Why auto_create_subnetworks = false?**
We want custom subnets with specific CIDR ranges, not Google's default subnets.

**Validation**:
```bash
# Initialize Terraform (we'll test later, but good to check syntax now)
cd student-version/modules/networking
terraform init
terraform validate
```

**Expected Output**: "Success! The configuration is valid."

**Common Errors**:
- Missing quotes around string values
- Typos in variable names
- Missing comma after attributes

---

## Step 3: Implement Subnets with for_each (TODO #2)

**Time**: 20 minutes

**Objective**: Create multiple subnets dynamically using the for_each meta-argument.

**Concepts**: for_each, each.key, each.value (Lesson 2)

**Implementation**:
1. Find the `google_compute_subnetwork` resource (TODO #2)
2. Implement the resource:
   ```hcl
   resource "google_compute_subnetwork" "subnets" {
     for_each = var.subnets
     
     name          = each.key
     ip_cidr_range = each.value.cidr_range
     region        = var.region
     network       = google_compute_network.vpc.id
     description   = each.value.description
     project       = var.project_id
   }
   ```

**Understanding for_each**:
- `for_each = var.subnets` iterates over the map
- `each.key` = the map key (e.g., "web-subnet", "data-subnet")
- `each.value` = the map value (an object with cidr_range and description)

**Why use for_each instead of count?**
- for_each preserves resource identity by key
- Removing one subnet won't recreate all others
- More maintainable for infrastructure collections

**Validation**:
```bash
terraform validate
```

**Test Your Understanding**:
1. What would happen if you added a third subnet to the `subnets` variable?
2. How would you reference a specific subnet in another resource?
3. What's the difference between `each.key` and `each.value.cidr_range`?

---

## Step 4: Implement Firewall Rules with Dynamic Blocks (TODO #3)

**Time**: 30 minutes

**Objective**: Create firewall rules using for_each and dynamic blocks.

**Concepts**: for_each, dynamic blocks (Lesson 3)

**Implementation**:
1. Find the `google_compute_firewall` resource (TODO #3)
2. Implement the resource:
   ```hcl
   resource "google_compute_firewall" "rules" {
     for_each = var.firewall_rules
     
     name          = "${var.vpc_name}-${each.key}"
     network       = google_compute_network.vpc.id
     project       = var.project_id
     description   = each.value.description
     priority      = each.value.priority
     direction     = each.value.direction
     source_ranges = each.value.source_ranges
     target_tags   = each.value.target_tags
     
     dynamic "allow" {
       for_each = each.value.allow
       content {
         protocol = allow.value.protocol
         ports    = allow.value.ports
       }
     }
   }
   ```

**Understanding Dynamic Blocks**:
- `dynamic "allow"` creates multiple `allow` blocks
- `for_each = each.value.allow` iterates over the allow list
- Inside `content`, use `allow.value` to access current item
- This handles rules with multiple protocols/port ranges

**Why use dynamic blocks?**
- Avoids repeating the same block structure
- Allows variable number of nested blocks
- Makes configuration more flexible

**Validation**:
```bash
terraform validate
terraform fmt  # Format your code
```

**Challenge Questions**:
1. How would you add HTTPS (port 443) to an existing rule?
2. Why do we prefix the firewall rule name with `${var.vpc_name}`?
3. What happens if priority values overlap?

---

## Step 5: Implement Networking Outputs (TODOs #4-6)

**Time**: 20 minutes

**Objective**: Export module information using outputs and for expressions.

**Concepts**: Output blocks, for expressions, functions (Lesson 1 & 3)

**Implementation**:

1. Open `modules/networking/outputs.tf`

2. Implement VPC outputs (TODO #4):
   ```hcl
   output "vpc_name" {
     description = "Name of the VPC network"
     value       = google_compute_network.vpc.name
   }
   
   output "vpc_id" {
     description = "ID of the VPC network"
     value       = google_compute_network.vpc.id
   }
   
   output "vpc_self_link" {
     description = "Self-link of the VPC network"
     value       = google_compute_network.vpc.self_link
   }
   ```

3. Implement subnet outputs with for expressions (TODO #5):
   ```hcl
   output "subnet_ids" {
     description = "Map of subnet names to subnet IDs"
     value = {
       for subnet_name, subnet in google_compute_subnetwork.subnets :
       subnet_name => subnet.id
     }
   }
   
   output "subnet_self_links" {
     description = "Map of subnet names to self-links"
     value = {
       for subnet_name, subnet in google_compute_subnetwork.subnets :
       subnet_name => subnet.self_link
     }
   }
   
   output "subnet_names" {
     description = "Map of subnet keys to names"
     value = {
       for subnet_name, subnet in google_compute_subnetwork.subnets :
       subnet_name => subnet.name
     }
   }
   ```

4. Implement summary output (TODO #6):
   ```hcl
   output "network_info" {
     description = "Summary of network configuration"
     value = {
       vpc_name      = google_compute_network.vpc.name
       vpc_id        = google_compute_network.vpc.id
       subnet_count  = length(google_compute_subnetwork.subnets)
       subnet_names  = keys(google_compute_subnetwork.subnets)
     }
   }
   ```

**Understanding For Expressions**:
- Syntax: `{ for key, value in collection : key => expression }`
- Transforms one collection into another
- Similar to map() in other languages

**Validation**:
```bash
terraform validate
```

---

## ✅ CHECKPOINT: Networking Module Complete!

Before proceeding, verify:
- [ ] All resources have required attributes
- [ ] `terraform validate` passes
- [ ] You understand for_each and dynamic blocks
- [ ] Outputs are properly defined

**Testing the Module Independently** (Optional but Recommended):
Create a test file outside your module to verify it works:

```hcl
# test/networking/main.tf
module "networking" {
  source = "../../modules/networking"
  
  project_id  = "your-project-id"
  region      = "us-central1"
  vpc_name    = "test-vpc"
  environment = "test"
  
  subnets = {
    "web" = {
      cidr_range  = "10.0.1.0/24"
      description = "Web tier subnet"
    }
  }
  
  firewall_rules = {
    "allow-ssh" = {
      priority      = 1000
      direction     = "INGRESS"
      description   = "Allow SSH"
      source_ranges = ["0.0.0.0/0"]
      target_tags   = ["web"]
      allow = [{
        protocol = "tcp"
        ports    = ["22"]
      }]
    }
  }
}

output "network_info" {
  value = module.networking.network_info
}
```

---

# 🖥️ PHASE 2: BUILD THE COMPUTE MODULE (Lessons 1-2)

## Step 6: Implement Web Server Instances with count (TODO #7)

**Time**: 30 minutes

**Objective**: Create multiple compute instances using the count meta-argument.

**Concepts**: count, count.index, lifecycle rules (Lesson 2)

**Implementation**:
1. Navigate to `student-version/modules/compute/main.tf`
2. Implement the `google_compute_instance` resource:
   ```hcl
   resource "google_compute_instance" "web_servers" {
     count = var.instance_count
     
     name         = "${var.instance_name_prefix}-${count.index + 1}"
     machine_type = var.machine_type
     zone         = var.zone
     project      = var.project_id
     tags         = var.network_tags
     
     boot_disk {
       initialize_params {
         image = "debian-cloud/debian-11"
       }
     }
     
     network_interface {
       subnetwork = var.subnet_id
       access_config {
         # Ephemeral public IP
       }
     }
     
     metadata_startup_script = file("${path.module}/startup.sh")
     
     lifecycle {
       create_before_destroy = true
       ignore_changes        = [metadata["ssh-keys"]]
     }
   }
   ```

**Understanding count**:
- `count = var.instance_count` creates N copies of the resource
- `count.index` is 0-based (0, 1, 2, ...)
- `count.index + 1` gives us nice names: web-server-1, web-server-2, etc.

**Understanding lifecycle**:
- `create_before_destroy`: Creates new instance before destroying old one (zero downtime)
- `ignore_changes`: Prevents Terraform from reverting manual SSH key additions

**Validation**:
```bash
terraform validate
```

**Understanding Questions**:
1. Why use `count.index + 1` instead of just `count.index`?
2. What does `file("${path.module}/startup.sh")` do?
3. Why ignore changes to SSH keys metadata?

---

## Step 7: Implement Load Balancer Components (TODOs #8-12)

**Time**: 45 minutes

**Objective**: Create a complete HTTP load balancer with health checks.

**Concepts**: Conditional resources, resource chaining (Lesson 2)

**Components Needed**:
1. Instance group
2. Health check
3. Backend service
4. URL map
5. HTTP proxy
6. Forwarding rule
7. Firewall rule for health checks

**Implementation**:

### 7a. Instance Group (TODO #8):
```hcl
resource "google_compute_instance_group" "web_group" {
  count = var.enable_load_balancer ? 1 : 0
  
  name    = "${var.instance_name_prefix}-group"
  zone    = var.zone
  project = var.project_id
  
  instances = google_compute_instance.web_servers[*].self_link
}
```

**Understanding conditionals**:
- `count = condition ? 1 : 0` creates resource only if condition is true
- `[*]` is the splat operator - gets self_link from all instances

### 7b. Health Check (TODO #9):
```hcl
resource "google_compute_health_check" "http" {
  count = var.enable_load_balancer ? 1 : 0
  
  name    = "${var.instance_name_prefix}-health-check"
  project = var.project_id
  
  http_health_check {
    port               = 80
    request_path       = "/health"
    check_interval_sec = 5
    timeout_sec        = 5
  }
  
  timeouts {
    create = "5m"
    delete = "5m"
  }
}
```

### 7c. Backend Service (TODO #10):
```hcl
resource "google_compute_backend_service" "web" {
  count = var.enable_load_balancer ? 1 : 0
  
  name          = "${var.instance_name_prefix}-backend"
  project       = var.project_id
  health_checks = [google_compute_health_check.http[0].id]
  
  backend {
    group           = google_compute_instance_group.web_group[0].id
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
  }
  
  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}
```

**Understanding balancing_mode**:
- UTILIZATION: Balances based on CPU usage
- max_utilization = 0.8: Start sending to new instances at 80% CPU

### 7d. URL Map (TODO #11):
```hcl
resource "google_compute_url_map" "web" {
  count = var.enable_load_balancer ? 1 : 0
  
  name            = "${var.instance_name_prefix}-url-map"
  project         = var.project_id
  default_service = google_compute_backend_service.web[0].id
}
```

### 7e. HTTP Proxy (TODO #11):
```hcl
resource "google_compute_target_http_proxy" "web" {
  count = var.enable_load_balancer ? 1 : 0
  
  name    = "${var.instance_name_prefix}-http-proxy"
  project = var.project_id
  url_map = google_compute_url_map.web[0].id
}
```

### 7f. Forwarding Rule (TODO #11):
```hcl
resource "google_compute_global_forwarding_rule" "web" {
  count = var.enable_load_balancer ? 1 : 0
  
  name       = "${var.instance_name_prefix}-forwarding-rule"
  project    = var.project_id
  target     = google_compute_target_http_proxy.web[0].id
  port_range = "80"
}
```

### 7g. Health Check Firewall Rule (TODO #12):
```hcl
resource "google_compute_firewall" "allow_health_check" {
  count = var.enable_load_balancer ? 1 : 0
  
  name    = "${var.instance_name_prefix}-allow-health-check"
  project = var.project_id
  network = "projects/${var.project_id}/global/networks/${var.instance_name_prefix}"
  
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = var.network_tags
}
```

**Understanding GCP health check IPs**:
- Google uses specific IP ranges for health checks
- Must allow these IPs to reach your instances
- `35.191.0.0/16` and `130.211.0.0/22` are Google's ranges

**Validation**:
```bash
terraform validate
```

---

## Step 8: Implement Compute Outputs (TODOs #13-15)

**Time**: 15 minutes

**Implementation**:

```hcl
# modules/compute/outputs.tf

output "instance_ids" {
  description = "List of instance IDs"
  value       = google_compute_instance.web_servers[*].id
}

output "instance_names" {
  description = "List of instance names"
  value       = google_compute_instance.web_servers[*].name
}

output "instance_public_ips" {
  description = "List of public IP addresses"
  value       = google_compute_instance.web_servers[*].network_interface[0].access_config[0].nat_ip
}

output "instance_private_ips" {
  description = "List of private IP addresses"
  value       = google_compute_instance.web_servers[*].network_interface[0].network_ip
}

output "load_balancer_ip" {
  description = "Load balancer public IP"
  value = var.enable_load_balancer ? (
    google_compute_global_forwarding_rule.web[0].ip_address
  ) : null
}

output "load_balancer_url" {
  description = "Load balancer URL"
  value = var.enable_load_balancer ? (
    "http://${google_compute_global_forwarding_rule.web[0].ip_address}"
  ) : null
}

output "compute_summary" {
  description = "Summary of compute resources"
  value = {
    instance_count = var.instance_count
    machine_type   = var.machine_type
    instances      = google_compute_instance.web_servers[*].name
    load_balancer  = var.enable_load_balancer
    lb_ip          = var.enable_load_balancer ? google_compute_global_forwarding_rule.web[0].ip_address : null
  }
}
```

---

## ✅ CHECKPOINT: Compute Module Complete!

---

# 🗄️ PHASE 3: BUILD DATABASE & STORAGE MODULES (Lesson 3)

## Step 9: Implement Database Module (TODOs #16-18)

**Time**: 30 minutes

**Objective**: Create Cloud SQL with conditional backups and dynamic authorized networks.

**Implementation**:

```hcl
# modules/database/main.tf

resource "google_sql_database_instance" "main" {
  name             = "${var.database_name}-${var.environment}"
  database_version = var.database_version
  region           = var.region
  project          = var.project_id
  
  deletion_protection = var.deletion_protection
  
  settings {
    tier      = var.database_tier
    disk_size = var.database_disk_size
    
    availability_type = var.environment == "prod" ? "REGIONAL" : "ZONAL"
    
    backup_configuration {
      enabled                        = var.enable_backups
      start_time                     = var.backup_start_time
      point_in_time_recovery_enabled = var.enable_backups
    }
    
    ip_configuration {
      ipv4_enabled = var.enable_public_IP
      
      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.value
        }
      }
    }
  }
  
  lifecycle {
    prevent_destroy = false  # Change to true for production
    ignore_changes  = [settings[0].disk_size]
  }
  
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

resource "google_sql_database" "database" {
  name     = var.database_name
  instance = google_sql_database_instance.main.name
  project  = var.project_id
}

resource "google_sql_user" "user" {
  name     = var.database_user
  instance = google_sql_database_instance.main.name
  password = var.database_password
  project  = var.project_id
}
```

**Implement Outputs**:
```hcl
# modules/database/outputs.tf

output "instance_name" {
  value = google_sql_database_instance.main.name
}

output "instance_connection_name" {
  value     = google_sql_database_instance.main.connection_name
  sensitive = true
}

output "public_ip_address" {
  value     = google_sql_database_instance.main.public_ip_address
  sensitive = true
}

output "database_version" {
  value = google_sql_database_instance.main.database_version
}

output "connection_command" {
  description = "gcloud command to connect to the database"
  value       = "gcloud sql connect ${google_sql_database_instance.main.name} --user=${var.database_user} --quiet"
  sensitive   = true
}

output "database_info" {
  description = "Formatted database information"
  value       = <<-EOT
    Database Instance: ${google_sql_database_instance.main.name}
    Version: ${google_sql_database_instance.main.database_version}
    Tier: ${var.database_tier}
    Connection: ${google_sql_database_instance.main.connection_name}
    
    Connect with: gcloud sql connect ${google_sql_database_instance.main.name} --user=${var.database_user}
  EOT
  sensitive = true
}
```

---

## Step 10: Implement Storage Module (TODO #19)

**Time**: 25 minutes

**Objective**: Create storage buckets with dynamic lifecycle rules.

**Implementation**:

```hcl
# modules/storage/main.tf

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "google_storage_bucket" "buckets" {
  for_each = var.buckets
  
  name          = "${each.key}-${var.environment}-${random_id.bucket_suffix.hex}"
  location      = each.value.location
  storage_class = each.value.storage_class
  project       = var.project_id
  force_destroy = var.force_destroy
  
  versioning {
    enabled = each.value.versioning
  }
  
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  
  dynamic "lifecycle_rule" {
    for_each = each.value.lifecycle_rules
    content {
      action {
        type = lifecycle_rule.value.action_type
      }
      condition {
        age                = lifecycle_rule.value.age
        num_newer_versions = lifecycle_rule.value.num_newer_versions
      }
    }
  }
  
  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}
```

**Implement Outputs**:
```hcl
# modules/storage/outputs.tf

output "bucket_names" {
  description = "Map of bucket keys to names"
  value = {
    for key, bucket in google_storage_bucket.buckets :
    key => bucket.name
  }
}

output "bucket_urls" {
  description = "Map of bucket keys to URLs"
  value = {
    for key, bucket in google_storage_bucket.buckets :
    key => bucket.url
  }
}

output "bucket_self_links" {
  description = "Map of bucket keys to self-links"
  value = {
    for key, bucket in google_storage_bucket.buckets :
    key => bucket.self_link
  }
}

output "storage_info" {
  description = "Detailed storage bucket information"
  value = {
    for key, bucket in google_storage_bucket.buckets :
    key => {
      name          = bucket.name
      url           = bucket.url
      location      = bucket.location
      storage_class = bucket.storage_class
    }
  }
}
```

---

# 🌍 PHASE 4: ENVIRONMENT CONFIGURATIONS (Lessons 4-5)

## Step 11: Deploy Development Environment

**Time**: 45 minutes

**Objective**: Use all modules together to create a complete dev environment.

**Steps**:

1. Navigate to `student-version/environments/dev/`

2. Review `variables.tf` (already complete)

3. Copy `terraform.tfvars.example` to `terraform.tfvars`:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

4. Edit `terraform.tfvars` with your project ID:
   ```hcl
   project_id = "your-gcp-project-id"
   region     = "us-central1"
   zone       = "us-central1-a"
   ```

5. Initialize Terraform:
   ```bash
   terraform init
   ```

6. Review the plan:
   ```bash
   terraform plan
   ```

7. Apply the configuration:
   ```bash
   terraform apply
   ```

8. Save outputs:
   ```bash
   terraform output -json > outputs.json
   terraform output quick_access
   ```

**Validation**:
- [ ] All resources created successfully
- [ ] Load balancer IP accessible
- [ ] Web servers responding
- [ ] Can see instance names in browser

**Testing**:
1. Get load balancer URL from outputs
2. Open in browser - should see Plexus welcome page
3. Refresh multiple times - instance name should change (load balancing)
4. Verify health check endpoint: `http://<ip>/health`

---

## Step 12: Set Up Remote State Management (Lesson 2)

**Time**: 20 minutes

**Objective**: Configure GCS backend for state management.

**Steps**:

1. Create GCS bucket for state:
   ```bash
   gsutil mb -p your-project-id -l us-central1 gs://plexus-terraform-state-dev
   gsutil versioning set on gs://plexus-terraform-state-dev
   ```

2. Uncomment backend configuration in `backend.tf`:
   ```hcl
   terraform {
     backend "gcs" {
       bucket = "plexus-terraform-state-dev"
       prefix = "terraform/state"
     }
   }
   ```

3. Migrate state:
   ```bash
   terraform init -migrate-state
   ```

4. Verify:
   ```bash
   gsutil ls gs://plexus-terraform-state-dev/terraform/state/
   ```

---

## Step 13: Test Environment Management (Lesson 5)

**Time**: 30 minutes

**Objective**: Demonstrate environment differences.

**Experiments**:

1. **Scale Web Servers**:
   ```hcl
   # In dev/terraform.tfvars
   web_server_count = 3
   ```
   ```bash
   terraform plan
   terraform apply
   ```

2. **Disable Database** (cost saving):
   ```hcl
   enable_database = false
   ```
   ```bash
   terraform apply
   ```

3. **Modify Firewall Rules**:
   Add HTTPS support to networking module configuration

4. **Test Lifecycle Management**:
   Change machine type and observe `create_before_destroy`

---

## Step 14: Deploy Production Environment

**Time**: 30 minutes

**Objective**: Deploy production with different configuration.

**Key Differences**:
- 3 instances (vs 2 in dev)
- Larger machine type (e2-medium vs e2-micro)
- Larger database (db-g1-small vs db-f1-micro)
- Backups enabled
- Deletion protection enabled

**Steps**:

1. Navigate to `student-version/environments/prod/`

2. Copy and edit `terraform.tfvars`:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit with production values
   ```

3. Create production state bucket:
   ```bash
   gsutil mb -p your-project-id -l us-central1 gs://plexus-terraform-state-prod
   gsutil versioning set on gs://plexus-terraform-state-prod
   ```

4. Initialize and apply:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

**⚠️ Production Warnings**:
- Higher costs (~$5.52/day)
- Deletion protection prevents accidental destruction
- Longer retention periods

---

# 🧪 PHASE 5: TESTING & VALIDATION

## Step 15: Comprehensive Testing

**Time**: 45 minutes

**Test Cases**:

### Test 1: Load Balancer Functionality
```bash
# Get load balancer IP
LB_IP=$(terraform output -raw load_balancer_ip)

# Test multiple times to verify load balancing
for i in {1..10}; do
  curl -s http://$LB_IP | grep "Instance:"
done
```

**Expected**: See different instance names

### Test 2: Database Connectivity
```bash
# Get connection command
terraform output -raw database_connection_command

# Execute the command
# Enter password when prompted
# Run a test query
\dt  # List tables
```

### Test 3: Storage Access
```bash
# List buckets
terraform output storage_bucket_names

# Upload test file
echo "Test content" > test.txt
gsutil cp test.txt gs://assets-dev-<suffix>/test.txt

# Verify
gsutil ls gs://assets-dev-<suffix>/
```

### Test 4: Firewall Rules
```bash
# Test SSH access
gcloud compute ssh web-server-1 --zone=us-central1-a

# Test HTTP access
curl http://<instance-public-ip>
```

### Test 5: Health Checks
```bash
# Check health endpoint
curl http://<lb-ip>/health
```

**Expected**: "OK"

---

## Step 16: State Management Verification

**Time**: 15 minutes

**Tests**:

1. **Remote State**:
   ```bash
   terraform state list
   gsutil cat gs://plexus-terraform-state-dev/terraform/state/default.tfstate | head -20
   ```

2. **State Locking** (requires backend locking):
   ```bash
   # In terminal 1
   terraform plan
   
   # In terminal 2 (while plan is running)
   terraform plan  # Should see lock error
   ```

3. **Workspace Isolation**:
   ```bash
   cd environments/dev
   terraform state list
   
   cd ../prod
   terraform state list
   ```

**Verify**: Dev and prod have completely separate states

---

## Step 17: Module Reusability Test

**Time**: 20 minutes

**Objective**: Verify modules work in different contexts.

**Create a test environment**:

```bash
mkdir -p environments/test
cd environments/test
```

```hcl
# main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "your-project-id"
  region  = "us-central1"
}

module "networking" {
  source = "../../modules/networking"
  
  project_id  = "your-project-id"
  region      = "us-central1"
  vpc_name    = "test-vpc"
  environment = "test"
  
  subnets = {
    "test" = {
      cidr_range  = "10.99.1.0/24"
      description = "Test subnet"
    }
  }
  
  firewall_rules = {}  # No firewall rules
}

output "vpc_id" {
  value = module.networking.vpc_id
}
```

```bash
terraform init
terraform plan
```

**Expected**: Plan shows only VPC and one subnet

---

# 🎓 PHASE 6: ADVANCED CHALLENGES

## Step 18: Implement Bonus Features (Optional)

**Time**: Variable

### Challenge 1: Add Monitoring
- Create a google_monitoring_alert_policy for CPU usage
- Configure uptime checks for the load balancer
- Send alerts to email

### Challenge 2: Implement Auto-Scaling
- Replace instance group with google_compute_instance_group_manager
- Add google_compute_autoscaler
- Configure scaling based on CPU or requests

### Challenge 3: Add CDN
- Enable Cloud CDN on the backend service
- Configure cache settings
- Test cache hit ratio

### Challenge 4: Implement Workspaces
- Convert directory structure to use Terraform workspaces
- Create `terraform workspace new dev`
- Refactor to use `terraform.workspace` variable

### Challenge 5: Add Secret Management
- Store database password in Secret Manager
- Use google_secret_manager_secret resource
- Reference secret in database module

### Challenge 6: Add CI/CD
- Create GitHub Actions workflow
- Automate terraform plan on PR
- Automate terraform apply on merge to main

---

# 🧹 PHASE 7: CLEANUP

## Step 19: Destroy Resources (IMPORTANT!)

**Time**: 20 minutes

**Objective**: Clean up to avoid charges.

### Dev Environment:
```bash
cd environments/dev
terraform destroy
```

### Production Environment:
```bash
cd environments/prod

# If deletion_protection is enabled, first disable it:
# Edit terraform.tfvars: deletion_protection = false
# terraform apply
terraform destroy
```

### Clean up state buckets:
```bash
gsutil -m rm -r gs://plexus-terraform-state-dev
gsutil -m rm -r gs://plexus-terraform-state-prod
```

**Verification**:
```bash
gcloud compute instances list
gcloud sql instances list
gsutil ls
```

All should be empty.

---

## Step 20: Document Your Learning

**Time**: 30 minutes

**Reflection Questions** (Answer these):

1. **Lesson 1 - Basics**:
   - What's the difference between a resource and a module?
   - How do outputs help with resource references?

2. **Lesson 2 - State & Meta-Arguments**:
   - Why is remote state important?
   - When would you use count vs for_each?
   - What's the purpose of lifecycle rules?

3. **Lesson 3 - Advanced HCL**:
   - How do dynamic blocks reduce code duplication?
   - When would you use a for expression vs a splat operator?
   - Give an example of when conditional expressions are useful.

4. **Lesson 4 - Modules**:
   - What are the benefits of creating custom modules?
   - How do you decide what should be a module?
   - How do modules improve maintainability?

5. **Lesson 5 - Environments**:
   - What's the difference between directory structure and workspaces?
   - How did you manage environment-specific variables?
   - What challenges did you face with multiple environments?

**Create Documentation**:
Write a README.md in your project root documenting:
- Architecture decisions
- How to deploy each environment
- Lessons learned
- Challenges faced and solutions

---

# ✅ FINAL ASSESSMENT CHECKLIST

## Technical Requirements

### Module Implementation:
- [ ] Networking module uses for_each for subnets and firewall rules
- [ ] Networking module uses dynamic blocks correctly
- [ ] Compute module uses count for instances
- [ ] Compute module implements conditional load balancer
- [ ] Database module uses conditional backups and dynamic authorized networks
- [ ] Storage module uses for_each and dynamic lifecycle rules
- [ ] All modules have proper variables and outputs

### Environment Management:
- [ ] Dev environment deployed successfully
- [ ] Production environment deployed successfully
- [ ] Different configurations per environment
- [ ] Remote state configured with GCS
- [ ] State is separate per environment

### Testing:
- [ ] Load balancer distributes traffic
- [ ] Database accessible
- [ ] Storage buckets functional
- [ ] All firewall rules working
- [ ] terraform validate passes for all modules
- [ ] terraform plan shows expected changes

### Cleanup:
- [ ] All resources destroyed
- [ ] No orphaned resources in GCP
- [ ] State buckets deleted
- [ ] No unexpected charges

## Concept Mastery:
- [ ] Can explain count vs for_each tradeoffs
- [ ] Understands dynamic blocks use cases
- [ ] Can explain module design decisions
- [ ] Understands state management importance
- [ ] Can articulate environment management strategy

---

# 🎯 Success Criteria

You have successfully completed this project if you can:

1. ✅ Deploy both dev and prod environments independently
2. ✅ Access the web application through the load balancer
3. ✅ Connect to the database
4. ✅ Upload/download files from storage buckets
5. ✅ Explain every line of Terraform code you wrote
6. ✅ Demonstrate count, for_each, and dynamic blocks
7. ✅ Show separate state management per environment
8. ✅ Successfully destroy all resources without errors

---

# 📚 Additional Resources

## Terraform Documentation:
- [Meta-Arguments](https://developer.hashicorp.com/terraform/language/meta-arguments/count)
- [Dynamic Blocks](https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks)
- [For Expressions](https://developer.hashicorp.com/terraform/language/expressions/for)
- [Functions](https://developer.hashicorp.com/terraform/language/functions)

## GCP Documentation:
- [Compute Engine](https://cloud.google.com/compute/docs)
- [Cloud SQL](https://cloud.google.com/sql/docs)
- [Cloud Storage](https://cloud.google.com/storage/docs)
- [Load Balancing](https://cloud.google.com/load-balancing/docs)

## Terraform GCP Provider:
- [Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

---

# 🆘 Troubleshooting Guide

## Common Issues:

### Issue: "API not enabled"
**Solution**:
```bash
gcloud services enable compute.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable storage.googleapis.com
```

### Issue: "Quota exceeded"
**Solution**: Check GCP quotas and request increases in Cloud Console

### Issue: "Resource already exists"
**Solution**: Import existing resource or use `terraform import`

### Issue: Load balancer takes long to provision
**Expected**: Can take 5-10 minutes for full provisioning

### Issue: State lock errors
**Solution**: Wait for previous operation to complete or manually unlock:
```bash
terraform force-unlock <lock-id>
```

---

# 🏆 Congratulations!

By completing this project, you've demonstrated comprehensive mastery of Terraform concepts from all 5 lessons. You've built production-ready infrastructure using industry best practices.

**Next Steps**:
1. Add this project to your portfolio
2. Explore the bonus challenges
3. Apply these concepts to real-world projects
4. Consider Terraform certification

**Feedback**: Document what you learned and share with your instructor!

---

**Project Created By**: Plexus DevOps Training Team  
**Version**: 1.0  
**Last Updated**: 2024
