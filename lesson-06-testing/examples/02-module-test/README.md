# Example 02: Module Testing

## 📋 Overview

This example demonstrates comprehensive testing for a reusable Terraform module. Learn to test module inputs, outputs, defaults, and multiple configurations.

**What You'll Learn**:
- Testing module with default values
- Testing module with custom configurations
- Validating module outputs
- Testing variable validation rules
- Multiple test scenarios

**Time to Complete**: 30-45 minutes

---

## 📁 Project Structure

```
02-module-test/
├── README.md                    # This file
├── modules/
│   └── compute/
│       ├── main.tf              # Compute instance module
│       ├── variables.tf         # Module input variables
│       └── outputs.tf           # Module outputs
├── main.tf                      # Root configuration using module
├── variables.tf                 # Root variables
├── outputs.tf                   # Root outputs
└── compute-module.tftest.hcl    # Module tests
```

---

## 🎯 Scenario

You're creating a **reusable compute instance module** that:
- Creates GCP VM instances with configurable settings
- Provides sensible defaults for development
- Supports customization for production workloads
- Exposes all necessary outputs

The module must be **tested thoroughly** before being used in production.

---

## 📝 Module Code

### Module: `modules/compute/main.tf`

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

resource "google_compute_instance" "vm" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  
  tags = var.tags
  
  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = var.disk_size_gb
      type  = var.disk_type
    }
  }
  
  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    
    # Conditionally assign external IP
    dynamic "access_config" {
      for_each = var.assign_external_ip ? [1] : []
      content {
        # Ephemeral IP
      }
    }
  }
  
  metadata = var.metadata
  
  labels = merge(
    {
      managed_by = "terraform"
      module     = "compute"
    },
    var.labels
  )
  
  allow_stopping_for_update = var.allow_stopping_for_update
  
  lifecycle {
    create_before_destroy = var.enable_create_before_destroy
  }
}
```

### Module: `modules/compute/variables.tf`

```hcl
variable "instance_name" {
  description = "Name of the compute instance"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.instance_name))
    error_message = "Instance name must start with a letter, contain only lowercase letters, numbers, and hyphens, and be 1-63 characters long"
  }
}

variable "machine_type" {
  description = "Machine type for the instance"
  type        = string
  default     = "e2-micro"
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.machine_type))
    error_message = "Machine type must be a valid GCP machine type"
  }
}

variable "zone" {
  description = "GCP zone for the instance"
  type        = string
  default     = "us-central1-a"
}

variable "tags" {
  description = "Network tags for the instance"
  type        = list(string)
  default     = []
}

variable "boot_image" {
  description = "Boot disk image"
  type        = string
  default     = "debian-cloud/debian-11"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 10
  
  validation {
    condition     = var.disk_size_gb >= 10 && var.disk_size_gb <= 10000
    error_message = "Disk size must be between 10 and 10000 GB"
  }
}

variable "disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-standard"
  
  validation {
    condition     = contains(["pd-standard", "pd-ssd", "pd-balanced"], var.disk_type)
    error_message = "Disk type must be pd-standard, pd-ssd, or pd-balanced"
  }
}

variable "network" {
  description = "Network to attach the instance to"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "Subnetwork to attach the instance to"
  type        = string
  default     = null
}

variable "assign_external_ip" {
  description = "Whether to assign an external IP address"
  type        = bool
  default     = true
}

variable "metadata" {
  description = "Instance metadata"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Labels to apply to the instance"
  type        = map(string)
  default     = {}
}

variable "allow_stopping_for_update" {
  description = "Allow stopping the instance to update properties"
  type        = bool
  default     = true
}

variable "enable_create_before_destroy" {
  description = "Enable create_before_destroy lifecycle rule"
  type        = bool
  default     = false
}
```

### Module: `modules/compute/outputs.tf`

```hcl
output "instance_id" {
  description = "ID of the compute instance"
  value       = google_compute_instance.vm.instance_id
}

output "instance_name" {
  description = "Name of the compute instance"
  value       = google_compute_instance.vm.name
}

output "instance_self_link" {
  description = "Self link of the compute instance"
  value       = google_compute_instance.vm.self_link
}

output "internal_ip" {
  description = "Internal IP address of the instance"
  value       = google_compute_instance.vm.network_interface[0].network_ip
}

output "external_ip" {
  description = "External IP address of the instance (if assigned)"
  value       = length(google_compute_instance.vm.network_interface[0].access_config) > 0 ? google_compute_instance.vm.network_interface[0].access_config[0].nat_ip : null
}

output "zone" {
  description = "Zone where the instance is located"
  value       = google_compute_instance.vm.zone
}

output "machine_type" {
  description = "Machine type of the instance"
  value       = google_compute_instance.vm.machine_type
}

output "tags" {
  description = "Tags applied to the instance"
  value       = google_compute_instance.vm.tags
}
```

---

## 🧪 Test File: `compute-module.tftest.hcl`

```hcl
# Test 1: Module works with only required variables
run "module_with_minimal_config" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "test-vm"
  }
  
  # Should use default values
  assert {
    condition     = google_compute_instance.vm.machine_type == "e2-micro"
    error_message = "Default machine type should be e2-micro"
  }
  
  assert {
    condition     = google_compute_instance.vm.zone == "us-central1-a"
    error_message = "Default zone should be us-central1-a"
  }
  
  assert {
    condition     = google_compute_instance.vm.boot_disk[0].initialize_params[0].size == 10
    error_message = "Default disk size should be 10 GB"
  }
  
  assert {
    condition     = google_compute_instance.vm.boot_disk[0].initialize_params[0].type == "pd-standard"
    error_message = "Default disk type should be pd-standard"
  }
}

# Test 2: Module accepts custom machine type
run "module_with_custom_machine_type" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "test-vm"
    machine_type  = "n2-standard-2"
  }
  
  assert {
    condition     = google_compute_instance.vm.machine_type == "n2-standard-2"
    error_message = "Should use provided machine type"
  }
}

# Test 3: Module accepts custom disk configuration
run "module_with_custom_disk" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "test-vm"
    disk_size_gb  = 50
    disk_type     = "pd-ssd"
  }
  
  assert {
    condition     = google_compute_instance.vm.boot_disk[0].initialize_params[0].size == 50
    error_message = "Should use provided disk size"
  }
  
  assert {
    condition     = google_compute_instance.vm.boot_disk[0].initialize_params[0].type == "pd-ssd"
    error_message = "Should use provided disk type"
  }
}

# Test 4: Module applies tags correctly
run "module_applies_tags" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "test-vm"
    tags          = ["web", "production", "http-server"]
  }
  
  assert {
    condition     = length(google_compute_instance.vm.tags) == 3
    error_message = "Should apply 3 tags"
  }
  
  assert {
    condition     = contains(google_compute_instance.vm.tags, "web")
    error_message = "Should include 'web' tag"
  }
  
  assert {
    condition     = contains(google_compute_instance.vm.tags, "production")
    error_message = "Should include 'production' tag"
  }
}

# Test 5: Module applies labels correctly including default labels
run "module_applies_labels" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "test-vm"
    labels = {
      environment = "dev"
      team        = "platform"
    }
  }
  
  # Check custom labels
  assert {
    condition     = google_compute_instance.vm.labels["environment"] == "dev"
    error_message = "Should apply custom environment label"
  }
  
  assert {
    condition     = google_compute_instance.vm.labels["team"] == "platform"
    error_message = "Should apply custom team label"
  }
  
  # Check default labels added by module
  assert {
    condition     = google_compute_instance.vm.labels["managed_by"] == "terraform"
    error_message = "Should add managed_by label"
  }
  
  assert {
    condition     = google_compute_instance.vm.labels["module"] == "compute"
    error_message = "Should add module label"
  }
}

# Test 6: External IP is conditional
run "module_without_external_ip" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name       = "test-vm"
    assign_external_ip  = false
  }
  
  assert {
    condition     = length(google_compute_instance.vm.network_interface[0].access_config) == 0
    error_message = "Should not have external IP when disabled"
  }
}

run "module_with_external_ip" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name      = "test-vm"
    assign_external_ip = true
  }
  
  assert {
    condition     = length(google_compute_instance.vm.network_interface[0].access_config) == 1
    error_message = "Should have external IP when enabled"
  }
}

# Test 7: Module exports all required outputs
run "module_exports_outputs" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "test-vm"
  }
  
  assert {
    condition     = output.instance_id != null
    error_message = "Module must export instance_id"
  }
  
  assert {
    condition     = output.instance_name == "test-vm"
    error_message = "Module must export instance_name"
  }
  
  assert {
    condition     = output.instance_self_link != null
    error_message = "Module must export instance_self_link"
  }
  
  assert {
    condition     = output.internal_ip != null
    error_message = "Module must export internal_ip"
  }
  
  assert {
    condition     = output.zone == "us-central1-a"
    error_message = "Module must export zone"
  }
  
  assert {
    condition     = output.machine_type == "e2-micro"
    error_message = "Module must export machine_type"
  }
}

# Test 8: Validation - Invalid instance name
run "invalid_instance_name_rejected" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "Test-VM-123"  # Capital letters not allowed
  }
  
  expect_failures = [
    var.instance_name
  ]
}

# Test 9: Validation - Disk size too small
run "disk_size_too_small_rejected" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "test-vm"
    disk_size_gb  = 5  # Below minimum
  }
  
  expect_failures = [
    var.disk_size_gb
  ]
}

# Test 10: Validation - Invalid disk type
run "invalid_disk_type_rejected" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "test-vm"
    disk_type     = "pd-extreme"  # Not in allowed list
  }
  
  expect_failures = [
    var.disk_type
  ]
}

# Test 11: Development environment configuration
run "dev_environment_config" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "dev-vm"
    machine_type  = "e2-micro"
    disk_size_gb  = 10
    disk_type     = "pd-standard"
    tags          = ["dev", "web"]
    labels = {
      environment = "dev"
    }
  }
  
  assert {
    condition     = google_compute_instance.vm.machine_type == "e2-micro"
    error_message = "Dev should use e2-micro"
  }
  
  assert {
    condition     = google_compute_instance.vm.boot_disk[0].initialize_params[0].type == "pd-standard"
    error_message = "Dev should use standard disk"
  }
}

# Test 12: Production environment configuration
run "prod_environment_config" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "prod-vm"
    machine_type  = "n2-standard-4"
    disk_size_gb  = 100
    disk_type     = "pd-ssd"
    tags          = ["prod", "web", "https-server"]
    labels = {
      environment = "prod"
      criticality = "high"
    }
  }
  
  assert {
    condition     = google_compute_instance.vm.machine_type == "n2-standard-4"
    error_message = "Prod should use n2-standard-4"
  }
  
  assert {
    condition     = google_compute_instance.vm.boot_disk[0].initialize_params[0].size == 100
    error_message = "Prod should use 100 GB disk"
  }
  
  assert {
    condition     = google_compute_instance.vm.boot_disk[0].initialize_params[0].type == "pd-ssd"
    error_message = "Prod should use SSD disk"
  }
  
  assert {
    condition     = length(google_compute_instance.vm.tags) == 3
    error_message = "Prod should have 3 tags"
  }
}
```

---

## 🚀 Running the Tests

### Run All Tests

```bash
cd lesson-06-testing/examples/02-module-test
terraform init
terraform test
```

### Expected Output

```
compute-module.tftest.hcl... in progress
  run "module_with_minimal_config"... pass
  run "module_with_custom_machine_type"... pass
  run "module_with_custom_disk"... pass
  run "module_applies_tags"... pass
  run "module_applies_labels"... pass
  run "module_without_external_ip"... pass
  run "module_with_external_ip"... pass
  run "module_exports_outputs"... pass
  run "invalid_instance_name_rejected"... pass
  run "disk_size_too_small_rejected"... pass
  run "invalid_disk_type_rejected"... pass
  run "dev_environment_config"... pass
  run "prod_environment_config"... pass
compute-module.tftest.hcl... 12 passed, 0 failed.

Success! 12 passed, 0 failed.
```

### Run Individual Test

```bash
terraform test -filter=module_with_custom_machine_type
```

### Verbose Output

```bash
terraform test -verbose
```

---

## 🎓 What Did We Test?

### ✅ Default Values (Test 1)
- Module uses sensible defaults
- `e2-micro` machine type
- `10 GB` standard disk
- `us-central1-a` zone

### ✅ Customization (Tests 2-3)
- Custom machine types work
- Custom disk configurations work
- Override default values

### ✅ Tags and Labels (Tests 4-5)
- Tags applied correctly
- Custom labels work
- Default labels added automatically

### ✅ Conditional Resources (Tests 6-7)
- External IP conditional logic
- Access config created/skipped correctly

### ✅ Module Contract (Test 8)
- All outputs exported
- Output values correct
- Module interface stable

### ✅ Validation Rules (Tests 9-11)
- Invalid inputs rejected
- Validation messages work
- Input constraints enforced

### ✅ Environment Scenarios (Tests 12-13)
- Dev configuration works
- Prod configuration works
- Different use cases covered

---

## 💡 Key Insights

### Why This Testing Approach Works

1. **Comprehensive Coverage**
   - Tests defaults and custom values
   - Tests all major features
   - Tests validation rules

2. **Real-World Scenarios**
   - Dev and prod configurations
   - Different use cases
   - Common patterns

3. **Module Contract Testing**
   - Verifies outputs exist
   - Validates input handling
   - Ensures interface stability

4. **Fast Execution**
   - All tests use `command = plan`
   - No actual resources created
   - Runs in seconds

---

## 🎯 Practice Exercise

### Challenge: Add More Tests

Add tests for:

1. **Network configuration**
   - Custom network and subnetwork
   - Verify network attachment

2. **Metadata**
   - Add metadata key-value pairs
   - Verify metadata applied

3. **Boot image**
   - Custom boot images
   - Different OS families

**Hint**: Follow the existing test patterns!

---

## 📚 What You Learned

✅ Testing module defaults  
✅ Testing custom configurations  
✅ Validating module outputs  
✅ Testing variable validation  
✅ Multiple environment scenarios  
✅ Comprehensive module testing

---

## 🔗 Next Steps

- **Continue**: [Example 03: Integration Testing](../03-integration-test/README.md)
- **Review**: [Section 02: Advanced Testing](../../section-02-advanced.md)
- **Back**: [Lesson 06 README](../../README.md)

---

**Congratulations!** 🎉 You can now test Terraform modules comprehensively. Continue to integration testing!
