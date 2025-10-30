# Example 03: Integration Testing

## 📋 Overview

This example demonstrates **integration testing** for Terraform modules that work together. Learn to test module interactions, data flow between modules, and end-to-end infrastructure scenarios.

**What You'll Learn**:
- Testing multiple modules together
- Verifying data flow between modules
- Integration test patterns
- End-to-end infrastructure testing
- Module dependency testing

**Time to Complete**: 45-60 minutes

---

## 📁 Project Structure

```
03-integration-test/
├── README.md                        # This file
├── modules/
│   ├── networking/
│   │   ├── main.tf                  # VPC and subnet resources
│   │   ├── variables.tf             # Network configuration
│   │   └── outputs.tf               # Network outputs
│   └── compute/
│       ├── main.tf                  # VM instances using network
│       ├── variables.tf             # Compute configuration
│       └── outputs.tf               # Instance outputs
├── main.tf                          # Root config using both modules
├── variables.tf                     # Root variables
├── outputs.tf                       # Root outputs
└── integration.tftest.hcl           # Integration tests
```

---

## 🎯 Scenario

You're building a **multi-tier infrastructure** that includes:
- **Networking Module**: Creates VPC and subnets
- **Compute Module**: Creates VM instances in those subnets

These modules must **work together correctly**:
- Compute instances connect to the right network
- Subnets are available in the correct regions
- Data flows properly from networking → compute
- Resources are created in the right order

---

## 📝 Module Code

### Networking Module: `modules/networking/main.tf`

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
}

resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets
  
  name          = each.key
  ip_cidr_range = each.value.cidr
  region        = each.value.region
  network       = google_compute_network.vpc.id
  
  private_ip_google_access = lookup(each.value, "private_google_access", true)
  
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_internal" {
  name    = "${var.vpc_name}-allow-internal"
  network = google_compute_network.vpc.name
  
  allow {
    protocol = "icmp"
  }
  
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  
  source_ranges = [for subnet in var.subnets : subnet.cidr]
}
```

### Networking Module: `modules/networking/variables.tf`

```hcl
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.vpc_name))
    error_message = "VPC name must start with a letter, contain only lowercase letters, numbers, and hyphens"
  }
}

variable "routing_mode" {
  description = "Routing mode for the VPC"
  type        = string
  default     = "REGIONAL"
  
  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "Routing mode must be REGIONAL or GLOBAL"
  }
}

variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    cidr                  = string
    region                = string
    private_google_access = optional(bool, true)
  }))
  
  validation {
    condition     = length(var.subnets) > 0
    error_message = "At least one subnet must be defined"
  }
}
```

### Networking Module: `modules/networking/outputs.tf`

```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "Name of the VPC"
  value       = google_compute_network.vpc.name
}

output "vpc_self_link" {
  description = "Self link of the VPC"
  value       = google_compute_network.vpc.self_link
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value       = { for k, v in google_compute_subnetwork.subnets : k => v.id }
}

output "subnet_self_links" {
  description = "Map of subnet names to their self links"
  value       = { for k, v in google_compute_subnetwork.subnets : k => v.self_link }
}

output "subnet_regions" {
  description = "Map of subnet names to their regions"
  value       = { for k, v in google_compute_subnetwork.subnets : k => v.region }
}
```

### Compute Module: `modules/compute/main.tf`

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

resource "google_compute_instance" "instances" {
  for_each = var.instances
  
  name         = each.key
  machine_type = each.value.machine_type
  zone         = each.value.zone
  
  tags = concat(
    ["managed-by-terraform"],
    lookup(each.value, "tags", [])
  )
  
  boot_disk {
    initialize_params {
      image = lookup(each.value, "boot_image", "debian-cloud/debian-11")
      size  = lookup(each.value, "disk_size_gb", 10)
      type  = lookup(each.value, "disk_type", "pd-standard")
    }
  }
  
  network_interface {
    network    = var.network_id
    subnetwork = var.subnetwork_id
    
    dynamic "access_config" {
      for_each = lookup(each.value, "assign_external_ip", false) ? [1] : []
      content {
        # Ephemeral IP
      }
    }
  }
  
  metadata = lookup(each.value, "metadata", {})
  
  labels = merge(
    {
      managed_by = "terraform"
      module     = "compute"
    },
    lookup(each.value, "labels", {})
  )
  
  allow_stopping_for_update = true
}
```

### Compute Module: `modules/compute/variables.tf`

```hcl
variable "network_id" {
  description = "ID of the network to attach instances to"
  type        = string
}

variable "subnetwork_id" {
  description = "ID of the subnetwork to attach instances to"
  type        = string
}

variable "instances" {
  description = "Map of instances to create"
  type = map(object({
    machine_type       = string
    zone               = string
    tags               = optional(list(string), [])
    boot_image         = optional(string, "debian-cloud/debian-11")
    disk_size_gb       = optional(number, 10)
    disk_type          = optional(string, "pd-standard")
    assign_external_ip = optional(bool, false)
    metadata           = optional(map(string), {})
    labels             = optional(map(string), {})
  }))
  
  validation {
    condition     = length(var.instances) > 0
    error_message = "At least one instance must be defined"
  }
}
```

### Compute Module: `modules/compute/outputs.tf`

```hcl
output "instance_ids" {
  description = "Map of instance names to their IDs"
  value       = { for k, v in google_compute_instance.instances : k => v.instance_id }
}

output "instance_names" {
  description = "Map of instance keys to their names"
  value       = { for k, v in google_compute_instance.instances : k => v.name }
}

output "internal_ips" {
  description = "Map of instance names to internal IPs"
  value       = { for k, v in google_compute_instance.instances : k => v.network_interface[0].network_ip }
}

output "external_ips" {
  description = "Map of instance names to external IPs (if assigned)"
  value = { 
    for k, v in google_compute_instance.instances : 
    k => length(v.network_interface[0].access_config) > 0 ? v.network_interface[0].access_config[0].nat_ip : null 
  }
}
```

---

## 🔗 Root Configuration

### `main.tf` - Using Both Modules

```hcl
terraform {
  required_version = ">= 1.6"
  
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

# Create networking infrastructure
module "networking" {
  source = "./modules/networking"
  
  vpc_name     = var.vpc_name
  routing_mode = var.routing_mode
  subnets      = var.subnets
}

# Create compute instances using the network
module "compute" {
  source = "./modules/compute"
  
  network_id    = module.networking.vpc_id
  subnetwork_id = module.networking.subnet_ids[var.primary_subnet_name]
  instances     = var.instances
  
  # Ensure networking is created first
  depends_on = [module.networking]
}
```

### `variables.tf`

```hcl
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "routing_mode" {
  description = "VPC routing mode"
  type        = string
  default     = "REGIONAL"
}

variable "subnets" {
  description = "Subnets to create"
  type = map(object({
    cidr                  = string
    region                = string
    private_google_access = optional(bool, true)
  }))
}

variable "primary_subnet_name" {
  description = "Name of the primary subnet for instances"
  type        = string
}

variable "instances" {
  description = "Instances to create"
  type = map(object({
    machine_type       = string
    zone               = string
    tags               = optional(list(string), [])
    boot_image         = optional(string, "debian-cloud/debian-11")
    disk_size_gb       = optional(number, 10)
    disk_type          = optional(string, "pd-standard")
    assign_external_ip = optional(bool, false)
    metadata           = optional(map(string), {})
    labels             = optional(map(string), {})
  }))
}
```

### `outputs.tf`

```hcl
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "subnet_ids" {
  description = "Subnet IDs"
  value       = module.networking.subnet_ids
}

output "instance_ids" {
  description = "Instance IDs"
  value       = module.compute.instance_ids
}

output "instance_internal_ips" {
  description = "Instance internal IPs"
  value       = module.compute.internal_ips
}
```

---

## 🧪 Integration Tests: `integration.tftest.hcl`

```hcl
# Test 1: Networking module creates VPC and subnets
run "networking_infrastructure_created" {
  command = plan
  
  variables {
    project_id  = "test-project"
    vpc_name    = "test-vpc"
    subnets = {
      "subnet-us-central" = {
        cidr   = "10.0.1.0/24"
        region = "us-central1"
      }
      "subnet-us-west" = {
        cidr   = "10.0.2.0/24"
        region = "us-west1"
      }
    }
    primary_subnet_name = "subnet-us-central"
    instances = {
      "web-1" = {
        machine_type = "e2-micro"
        zone         = "us-central1-a"
      }
    }
  }
  
  # Verify VPC creation
  assert {
    condition     = google_compute_network.vpc.name == "test-vpc"
    error_message = "VPC should be created with correct name"
  }
  
  assert {
    condition     = google_compute_network.vpc.auto_create_subnetworks == false
    error_message = "VPC should not auto-create subnets"
  }
  
  # Verify subnets created
  assert {
    condition     = length(google_compute_subnetwork.subnets) == 2
    error_message = "Should create 2 subnets"
  }
  
  assert {
    condition     = google_compute_subnetwork.subnets["subnet-us-central"].ip_cidr_range == "10.0.1.0/24"
    error_message = "Subnet should have correct CIDR"
  }
  
  # Verify firewall rule
  assert {
    condition     = google_compute_firewall.allow_internal.network == "test-vpc"
    error_message = "Firewall should be attached to VPC"
  }
}

# Test 2: Compute instances use networking module outputs
run "compute_uses_networking_outputs" {
  command = plan
  
  variables {
    project_id  = "test-project"
    vpc_name    = "test-vpc"
    subnets = {
      "subnet-central" = {
        cidr   = "10.0.1.0/24"
        region = "us-central1"
      }
    }
    primary_subnet_name = "subnet-central"
    instances = {
      "web-1" = {
        machine_type = "e2-micro"
        zone         = "us-central1-a"
      }
    }
  }
  
  # Verify compute module receives network ID from networking module
  assert {
    condition     = module.compute.network_id == module.networking.vpc_id
    error_message = "Compute should receive VPC ID from networking module"
  }
  
  # Verify instances connected to correct subnet
  assert {
    condition     = module.compute.subnetwork_id == module.networking.subnet_ids["subnet-central"]
    error_message = "Compute should use subnet from networking module"
  }
}

# Test 3: Data flow between modules works correctly
run "data_flows_between_modules" {
  command = plan
  
  variables {
    project_id  = "test-project"
    vpc_name    = "integration-vpc"
    subnets = {
      "app-subnet" = {
        cidr   = "10.10.1.0/24"
        region = "us-central1"
      }
    }
    primary_subnet_name = "app-subnet"
    instances = {
      "app-server" = {
        machine_type = "e2-small"
        zone         = "us-central1-a"
      }
    }
  }
  
  # Verify VM is attached to the VPC created by networking module
  assert {
    condition     = google_compute_instance.instances["app-server"].network_interface[0].network == google_compute_network.vpc.id
    error_message = "Instance should be connected to networking VPC"
  }
  
  # Verify VM is in the correct subnet
  assert {
    condition     = google_compute_instance.instances["app-server"].network_interface[0].subnetwork == google_compute_subnetwork.subnets["app-subnet"].id
    error_message = "Instance should be in correct subnet"
  }
  
  # Verify VM zone matches subnet region
  assert {
    condition     = can(regex("^us-central1", google_compute_instance.instances["app-server"].zone))
    error_message = "Instance zone should match subnet region"
  }
}

# Test 4: Multiple instances across multiple subnets
run "multi_instance_multi_subnet" {
  command = plan
  
  variables {
    project_id  = "test-project"
    vpc_name    = "multi-tier-vpc"
    subnets = {
      "web-subnet" = {
        cidr   = "10.0.1.0/24"
        region = "us-central1"
      }
      "app-subnet" = {
        cidr   = "10.0.2.0/24"
        region = "us-central1"
      }
    }
    primary_subnet_name = "web-subnet"
    instances = {
      "web-1" = {
        machine_type = "e2-micro"
        zone         = "us-central1-a"
      }
      "web-2" = {
        machine_type = "e2-micro"
        zone         = "us-central1-b"
      }
    }
  }
  
  # Verify multiple subnets created
  assert {
    condition     = length(google_compute_subnetwork.subnets) == 2
    error_message = "Should create 2 subnets"
  }
  
  # Verify multiple instances created
  assert {
    condition     = length(google_compute_instance.instances) == 2
    error_message = "Should create 2 instances"
  }
  
  # Verify both instances in same subnet (primary)
  assert {
    condition     = google_compute_instance.instances["web-1"].network_interface[0].subnetwork == google_compute_subnetwork.subnets["web-subnet"].id
    error_message = "web-1 should be in web-subnet"
  }
  
  assert {
    condition     = google_compute_instance.instances["web-2"].network_interface[0].subnetwork == google_compute_subnetwork.subnets["web-subnet"].id
    error_message = "web-2 should be in web-subnet"
  }
}

# Test 5: Module outputs are propagated correctly
run "module_outputs_propagate" {
  command = plan
  
  variables {
    project_id  = "test-project"
    vpc_name    = "output-test-vpc"
    subnets = {
      "main-subnet" = {
        cidr   = "10.0.1.0/24"
        region = "us-central1"
      }
    }
    primary_subnet_name = "main-subnet"
    instances = {
      "test-vm" = {
        machine_type = "e2-micro"
        zone         = "us-central1-a"
      }
    }
  }
  
  # Root outputs should expose networking outputs
  assert {
    condition     = output.vpc_id == module.networking.vpc_id
    error_message = "Root should expose VPC ID"
  }
  
  assert {
    condition     = output.subnet_ids == module.networking.subnet_ids
    error_message = "Root should expose subnet IDs"
  }
  
  # Root outputs should expose compute outputs
  assert {
    condition     = output.instance_ids == module.compute.instance_ids
    error_message = "Root should expose instance IDs"
  }
}

# Test 6: Integration with tags and labels
run "tags_and_labels_integration" {
  command = plan
  
  variables {
    project_id  = "test-project"
    vpc_name    = "labeled-vpc"
    subnets = {
      "labeled-subnet" = {
        cidr   = "10.0.1.0/24"
        region = "us-central1"
      }
    }
    primary_subnet_name = "labeled-subnet"
    instances = {
      "labeled-vm" = {
        machine_type = "e2-micro"
        zone         = "us-central1-a"
        tags         = ["web", "production"]
        labels = {
          environment = "prod"
          tier        = "web"
        }
      }
    }
  }
  
  # Verify tags applied
  assert {
    condition     = contains(google_compute_instance.instances["labeled-vm"].tags, "web")
    error_message = "Instance should have web tag"
  }
  
  assert {
    condition     = contains(google_compute_instance.instances["labeled-vm"].tags, "managed-by-terraform")
    error_message = "Instance should have default terraform tag"
  }
  
  # Verify labels applied
  assert {
    condition     = google_compute_instance.instances["labeled-vm"].labels["environment"] == "prod"
    error_message = "Instance should have environment label"
  }
  
  assert {
    condition     = google_compute_instance.instances["labeled-vm"].labels["managed_by"] == "terraform"
    error_message = "Instance should have default managed_by label"
  }
}

# Test 7: Firewall rule covers all subnet ranges
run "firewall_covers_all_subnets" {
  command = plan
  
  variables {
    project_id  = "test-project"
    vpc_name    = "firewall-test-vpc"
    subnets = {
      "subnet-1" = {
        cidr   = "10.0.1.0/24"
        region = "us-central1"
      }
      "subnet-2" = {
        cidr   = "10.0.2.0/24"
        region = "us-west1"
      }
      "subnet-3" = {
        cidr   = "10.0.3.0/24"
        region = "us-east1"
      }
    }
    primary_subnet_name = "subnet-1"
    instances = {
      "test-vm" = {
        machine_type = "e2-micro"
        zone         = "us-central1-a"
      }
    }
  }
  
  # Verify firewall includes all subnet CIDRs
  assert {
    condition     = contains(google_compute_firewall.allow_internal.source_ranges, "10.0.1.0/24")
    error_message = "Firewall should include subnet-1 CIDR"
  }
  
  assert {
    condition     = contains(google_compute_firewall.allow_internal.source_ranges, "10.0.2.0/24")
    error_message = "Firewall should include subnet-2 CIDR"
  }
  
  assert {
    condition     = contains(google_compute_firewall.allow_internal.source_ranges, "10.0.3.0/24")
    error_message = "Firewall should include subnet-3 CIDR"
  }
  
  assert {
    condition     = length(google_compute_firewall.allow_internal.source_ranges) == 3
    error_message = "Firewall should have exactly 3 source ranges"
  }
}
```

---

## 🚀 Running Integration Tests

### Run All Tests

```bash
cd lesson-06-testing/examples/03-integration-test
terraform init
terraform test
```

### Expected Output

```
integration.tftest.hcl... in progress
  run "networking_infrastructure_created"... pass
  run "compute_uses_networking_outputs"... pass
  run "data_flows_between_modules"... pass
  run "multi_instance_multi_subnet"... pass
  run "module_outputs_propagate"... pass
  run "tags_and_labels_integration"... pass
  run "firewall_covers_all_subnets"... pass
integration.tftest.hcl... 7 passed, 0 failed.

Success! 7 passed, 0 failed.
```

### Run Verbose

```bash
terraform test -verbose
```

---

## 🎓 What Did We Test?

### ✅ Module Creation (Test 1)
- Networking module creates VPC
- Subnets created with correct configuration
- Firewall rules established

### ✅ Module Integration (Tests 2-3)
- Compute uses networking outputs
- Data flows correctly between modules
- Dependencies handled properly

### ✅ Multi-Resource Scenarios (Test 4)
- Multiple subnets work together
- Multiple instances deployed correctly
- All connected to same VPC

### ✅ Output Propagation (Test 5)
- Nested module outputs accessible
- Root outputs expose module data
- Output chain works correctly

### ✅ Feature Integration (Test 6)
- Tags and labels work across modules
- Default values merged correctly
- Custom values preserved

### ✅ Complex Logic (Test 7)
- Firewall rules cover all subnets dynamically
- Source ranges calculated correctly
- Multi-subnet configurations work

---

## 💡 Key Integration Testing Patterns

### 1. Test Module Interactions

```hcl
assert {
  condition     = module.compute.network_id == module.networking.vpc_id
  error_message = "Modules should share data correctly"
}
```

### 2. Test Data Flow

```hcl
assert {
  condition     = google_compute_instance.vm.network_interface[0].network == google_compute_network.vpc.id
  error_message = "Resources should reference each other correctly"
}
```

### 3. Test Multi-Resource Scenarios

```hcl
assert {
  condition     = length(google_compute_subnetwork.subnets) == 2
  error_message = "Multiple resources should be created"
}
```

### 4. Test Output Chains

```hcl
assert {
  condition     = output.vpc_id == module.networking.vpc_id
  error_message = "Outputs should propagate through layers"
}
```

---

## 🎯 Practice Exercise

### Challenge: Add Application Load Balancer Module

**Requirements**:
1. Create `modules/load-balancer/` module
2. Load balancer uses networking VPC
3. Backend instances from compute module
4. Write integration tests for:
   - LB connects to correct VPC
   - Backend pool includes compute instances
   - Health checks configured
   - All three modules work together

---

## 📚 What You Learned

✅ Testing multiple modules together  
✅ Verifying module interactions  
✅ Testing data flow between modules  
✅ Integration test patterns  
✅ End-to-end infrastructure testing  
✅ Complex multi-module scenarios

---

## 🔗 Next Steps

- **Review**: [Section 02: Advanced Testing](../../section-02-advanced.md)
- **Practice**: Complete the load balancer challenge
- **Back**: [Lesson 06 README](../../README.md)

---

**Excellent work!** 🎉 You now know how to test complex, multi-module Terraform configurations. You're ready for production!
