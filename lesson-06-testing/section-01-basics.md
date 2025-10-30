# Section 01: Terraform Testing Basics

## 📚 Introduction

Welcome to Terraform testing! In this section, you'll learn the fundamentals of testing infrastructure code using Terraform's native testing framework.

**Time to Complete**: 45 minutes  
**Prerequisites**: Lessons 1-3 (Terraform basics, state, variables)

---

## 🎯 Learning Objectives

After completing this section, you will:

- Understand what `terraform test` does and why it matters
- Know the structure of a `.tftest.hcl` file
- Write basic test assertions
- Run tests and interpret results
- Apply testing to simple resources

---

## 🤔 What is `terraform test`?

### Overview

`terraform test` is Terraform's built-in testing framework (introduced in v1.6.0) that allows you to:

- **Validate infrastructure code** before applying
- **Test modules** in isolation
- **Assert expected behavior** with custom conditions
- **Run fast feedback loops** without creating real resources

### Why Test Infrastructure?

**Traditional Workflow** (without tests):
```
Write code → terraform apply → Check if it works → Fix errors → Apply again
```
⏰ Slow, 💰 Expensive, 😰 Risky

**Testing Workflow**:
```
Write code → terraform test → Fix errors → Test again → Apply with confidence
```
⚡ Fast, 💵 Free, 😊 Safe

---

## 📁 Test File Structure

### File Naming

Test files use the `.tftest.hcl` extension:

```
project/
├── main.tf              # Your Terraform code
├── variables.tf
├── outputs.tf
└── tests/
    ├── basic.tftest.hcl     # Test file
    └── advanced.tftest.hcl  # Another test file
```

**Naming Convention**:
- Use descriptive names: `vpc_configuration.tftest.hcl`
- Group related tests: `compute_instances.tftest.hcl`
- Can be in root or `tests/` directory

### Basic Test File Anatomy

```hcl
# basic.tftest.hcl

# Test block (can have multiple in one file)
run "test_name" {
  command = plan  # or "apply"
  
  # Variables to pass (optional)
  variables {
    project_id = "test-project"
    region     = "us-central1"
  }
  
  # Assertions
  assert {
    condition     = <boolean expression>
    error_message = "Descriptive error message"
  }
}
```

---

## 🔧 The `run` Block

The `run` block defines a single test case.

### Syntax

```hcl
run "descriptive_test_name" {
  command = plan  # Required: "plan" or "apply"
  
  # Optional: Override variables
  variables {
    variable_name = "value"
  }
  
  # Optional: One or more assertions
  assert {
    condition     = <expression>
    error_message = "Message shown if condition is false"
  }
}
```

### The `command` Parameter

Two options:

| Command | Creates Resources? | Use Case | Speed |
|---------|-------------------|----------|-------|
| `plan` | ❌ No | Most tests, validation | ⚡ Fast |
| `apply` | ✅ Yes | Integration tests | 🐌 Slow |

**Best Practice**: Use `plan` for 90% of tests. Only use `apply` when you need to test real resource creation.

---

## ✅ Writing Assertions

### The `assert` Block

```hcl
assert {
  condition     = google_compute_instance.vm.machine_type == "e2-micro"
  error_message = "VM must be e2-micro for cost optimization"
}
```

**Components**:
- `condition`: Boolean expression (must evaluate to `true`)
- `error_message`: Custom message shown on failure

### Accessing Resources

In assertions, you can reference:

```hcl
# Resources
google_compute_instance.vm.machine_type
google_compute_network.vpc.name

# Data sources
data.google_compute_zones.available.names

# Variables
var.project_id

# Outputs
output.instance_ip
```

### Multiple Assertions

```hcl
run "verify_vm" {
  command = plan
  
  # All assertions must pass
  assert {
    condition     = google_compute_instance.vm.machine_type == "e2-micro"
    error_message = "Wrong machine type"
  }
  
  assert {
    condition     = google_compute_instance.vm.zone == "us-central1-a"
    error_message = "Wrong zone"
  }
  
  assert {
    condition     = length(google_compute_instance.vm.network_interface) > 0
    error_message = "Must have network interface"
  }
}
```

---

## 🏃 Running Tests

### Command Syntax

```bash
# Run all tests in the current directory
terraform test

# Run a specific test file
terraform test tests/basic.tftest.hcl

# Verbose output
terraform test -verbose

# JSON output (for CI/CD)
terraform test -json
```

### Test Execution Flow

```
1. terraform init (if needed)
   ↓
2. Load configuration
   ↓
3. For each run block:
   - Apply variables
   - Execute command (plan/apply)
   - Evaluate assertions
   ↓
4. Report results
```

---

## 📊 Understanding Test Output

### Successful Test

```bash
$ terraform test

tests/simple.tftest.hcl... in progress
  run "verify_instance"... pass
  run "verify_network"... pass
tests/simple.tftest.hcl... tearing down
tests/simple.tftest.hcl... pass

Success! 2 passed, 0 failed.
```

**Interpretation**:
- ✅ All assertions passed
- ✅ Configuration is valid
- ✅ Ready to apply

### Failed Test

```bash
$ terraform test

tests/simple.tftest.hcl... in progress
  run "verify_instance"... fail
╷
│ Error: Test assertion failed
│ 
│   on simple.tftest.hcl line 8, in run "verify_instance":
│    8:     condition     = google_compute_instance.vm.machine_type == "e2-micro"
│     ├────────────────
│     │ google_compute_instance.vm.machine_type is "e2-small"
│ 
│ VM must be e2-micro for cost optimization
╵

Failure! 0 passed, 1 failed.
```

**Interpretation**:
- ❌ Assertion failed
- 📍 Shows exact file and line
- 📊 Shows actual value vs expected
- 💬 Shows your custom error message

---

## 📝 Example: Testing a Simple VM

### Step 1: Create Terraform Configuration

```hcl
# main.tf
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

resource "google_compute_instance" "test_vm" {
  name         = "test-instance"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
  }

  tags = var.tags
}
```

```hcl
# variables.tf
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "Machine type for VM"
  type        = string
  default     = "e2-micro"
}

variable "tags" {
  description = "Network tags"
  type        = list(string)
  default     = ["web", "ssh"]
}
```

```hcl
# outputs.tf
output "instance_name" {
  description = "Name of the created instance"
  value       = google_compute_instance.test_vm.name
}

output "instance_zone" {
  description = "Zone of the instance"
  value       = google_compute_instance.test_vm.zone
}

output "instance_id" {
  description = "ID of the instance"
  value       = google_compute_instance.test_vm.instance_id
}
```

### Step 2: Write the Test

```hcl
# simple.tftest.hcl

# Test 1: Verify machine type
run "verify_machine_type" {
  command = plan

  variables {
    project_id = "test-project-123"
  }

  assert {
    condition     = google_compute_instance.test_vm.machine_type == "e2-micro"
    error_message = "Expected machine type e2-micro, got ${google_compute_instance.test_vm.machine_type}"
  }
}

# Test 2: Verify zone placement
run "verify_zone" {
  command = plan

  variables {
    project_id = "test-project-123"
  }

  assert {
    condition     = google_compute_instance.test_vm.zone == "us-central1-a"
    error_message = "VM must be in us-central1-a zone"
  }
}

# Test 3: Verify network tags
run "verify_tags" {
  command = plan

  variables {
    project_id = "test-project-123"
  }

  assert {
    condition     = contains(google_compute_instance.test_vm.tags, "web")
    error_message = "VM must have 'web' tag"
  }

  assert {
    condition     = length(google_compute_instance.test_vm.tags) >= 2
    error_message = "VM must have at least 2 tags"
  }
}

# Test 4: Verify outputs are not empty
run "verify_outputs" {
  command = plan

  variables {
    project_id = "test-project-123"
  }

  assert {
    condition     = output.instance_name != ""
    error_message = "Instance name output must not be empty"
  }

  assert {
    condition     = output.instance_zone != ""
    error_message = "Instance zone output must not be empty"
  }
}

# Test 5: Test with custom machine type
run "test_custom_machine_type" {
  command = plan

  variables {
    project_id   = "test-project-123"
    machine_type = "e2-small"
  }

  assert {
    condition     = google_compute_instance.test_vm.machine_type == "e2-small"
    error_message = "Machine type should be e2-small when specified"
  }
}
```

### Step 3: Run the Test

```bash
# Initialize Terraform
terraform init

# Run the tests
terraform test

# Expected output:
# Success! 5 passed, 0 failed.
```

---

## 💡 Common Test Patterns

### Pattern 1: Testing String Values

```hcl
assert {
  condition     = google_compute_instance.vm.name == "expected-name"
  error_message = "Instance name mismatch"
}
```

### Pattern 2: Testing Numeric Values

```hcl
assert {
  condition     = google_compute_disk.disk.size >= 10
  error_message = "Disk must be at least 10GB"
}
```

### Pattern 3: Testing Booleans

```hcl
assert {
  condition     = google_compute_instance.vm.deletion_protection == true
  error_message = "Production VMs must have deletion protection"
}
```

### Pattern 4: Testing Collections

```hcl
# Check if element exists
assert {
  condition     = contains(var.allowed_regions, "us-central1")
  error_message = "us-central1 must be an allowed region"
}

# Check length
assert {
  condition     = length(google_compute_subnetwork.subnets) == 3
  error_message = "Must create exactly 3 subnets"
}
```

### Pattern 5: Testing with Functions

```hcl
# String manipulation
assert {
  condition     = startswith(google_compute_instance.vm.name, "prod-")
  error_message = "Production instances must start with 'prod-'"
}

# Regex matching
assert {
  condition     = can(regex("^[a-z0-9-]+$", google_compute_instance.vm.name))
  error_message = "Instance name must be lowercase alphanumeric with hyphens"
}
```

---

## 🎯 Testing Best Practices

### ✅ Good Practices

1. **Use Descriptive Test Names**
   ```hcl
   # ✅ Good
   run "verify_production_vm_has_deletion_protection" { }
   
   # ❌ Bad
   run "test1" { }
   ```

2. **Write Clear Error Messages**
   ```hcl
   # ✅ Good
   error_message = "Production VMs require machine type n1-standard-2 or larger, got ${var.machine_type}"
   
   # ❌ Bad
   error_message = "Wrong type"
   ```

3. **Test One Concept Per Run Block**
   ```hcl
   # ✅ Good - separate concerns
   run "verify_machine_type" { }
   run "verify_disk_size" { }
   
   # ❌ Bad - testing everything together
   run "verify_everything" { }
   ```

4. **Use Variables for Test Data**
   ```hcl
   # ✅ Good
   variables {
     project_id = "test-project"
     environment = "test"
   }
   ```

### ❌ Anti-Patterns

1. **Don't Test Terraform Built-ins**
   ```hcl
   # ❌ Bad - testing Terraform's functionality
   assert {
     condition = can(regex(".*", "test"))
     error_message = "Regex function broken"
   }
   ```

2. **Don't Make Tests Depend on Each Other**
   ```hcl
   # ❌ Bad - run blocks should be independent
   run "create_vpc" { }  # Don't rely on this in next test
   run "create_subnet" { }  # This should work standalone
   ```

3. **Don't Over-Test**
   ```hcl
   # ❌ Bad - testing provider behavior
   assert {
     condition = google_compute_instance.vm.self_link != ""
     error_message = "Google provider should set self_link"
   }
   ```

---

## 🔍 Debugging Failed Tests

### Technique 1: Add Verbose Output

```bash
terraform test -verbose
```

Shows detailed plan output for each test.

### Technique 2: Print Actual Values

```hcl
assert {
  condition = google_compute_instance.vm.machine_type == "e2-micro"
  error_message = "Expected e2-micro, got '${google_compute_instance.vm.machine_type}'"
}
```

### Technique 3: Test Incrementally

Start with simple assertions, add complexity:

```hcl
# Step 1: Test resource exists
run "test_exists" {
  command = plan
  
  assert {
    condition = google_compute_instance.vm != null
    error_message = "Instance must be defined"
  }
}

# Step 2: Test specific attributes
run "test_attributes" {
  command = plan
  
  assert {
    condition = google_compute_instance.vm.machine_type == "e2-micro"
    error_message = "Wrong machine type"
  }
}
```

### Technique 4: Isolate the Problem

Comment out assertions to find which one fails:

```hcl
run "debug" {
  command = plan
  
  # assert { ... }  # Comment out
  # assert { ... }  # Comment out
  assert { ... }    # Test this one
}
```

---

## 🎓 Practice Exercise

### Challenge: Test a Cloud Storage Bucket

**Requirements**:
1. Create a GCS bucket configuration
2. Write tests to verify:
   - Bucket name follows naming convention
   - Location is in allowed region
   - Versioning is enabled
   - Lifecycle rule exists

**Starter Code**:

```hcl
# main.tf
resource "google_storage_bucket" "app_bucket" {
  name          = var.bucket_name
  location      = var.location
  force_destroy = false
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}
```

**Your Task**: Write `bucket.tftest.hcl` with at least 4 test cases!

<details>
<summary>💡 Solution (Click to expand)</summary>

```hcl
# bucket.tftest.hcl

run "verify_bucket_name_format" {
  command = plan
  
  variables {
    bucket_name = "my-app-bucket"
    location    = "US"
  }
  
  assert {
    condition     = can(regex("^[a-z0-9-]+$", var.bucket_name))
    error_message = "Bucket name must be lowercase alphanumeric with hyphens"
  }
}

run "verify_location" {
  command = plan
  
  variables {
    bucket_name = "test-bucket"
    location    = "US"
  }
  
  assert {
    condition     = contains(["US", "EU", "ASIA"], google_storage_bucket.app_bucket.location)
    error_message = "Location must be US, EU, or ASIA"
  }
}

run "verify_versioning_enabled" {
  command = plan
  
  variables {
    bucket_name = "test-bucket"
    location    = "US"
  }
  
  assert {
    condition     = google_storage_bucket.app_bucket.versioning[0].enabled == true
    error_message = "Bucket versioning must be enabled"
  }
}

run "verify_lifecycle_rule" {
  command = plan
  
  variables {
    bucket_name = "test-bucket"
    location    = "US"
  }
  
  assert {
    condition     = length(google_storage_bucket.app_bucket.lifecycle_rule) > 0
    error_message = "Bucket must have at least one lifecycle rule"
  }
  
  assert {
    condition     = google_storage_bucket.app_bucket.lifecycle_rule[0].condition[0].age == 30
    error_message = "Lifecycle rule should delete objects after 30 days"
  }
}
```

</details>

---

## 📚 Key Takeaways

### What You Learned

- ✅ `terraform test` validates infrastructure without creating resources
- ✅ Tests live in `.tftest.hcl` files
- ✅ `run` blocks define test cases
- ✅ `assert` blocks validate conditions
- ✅ Use `command = plan` for fast tests
- ✅ Write descriptive test names and error messages
- ✅ Tests catch errors before deployment

### Next Steps

1. **Practice**: Complete the practice exercise above
2. **Experiment**: Add more assertions to Example 01
3. **Apply**: Test your own modules from previous lessons
4. **Continue**: Move to [Section 02: Advanced Testing](./section-02-advanced.md)

---

## 🔗 Related Resources

- [Terraform Test Documentation](https://developer.hashicorp.com/terraform/language/tests)
- [Example 01: Simple Test](../examples/01-simple-test/README.md)
- [Next: Section 02 - Advanced Testing](./section-02-advanced.md)

---

**Ready for advanced testing patterns? Continue to [Section 02: Advanced Testing](./section-02-advanced.md)!** 🚀
