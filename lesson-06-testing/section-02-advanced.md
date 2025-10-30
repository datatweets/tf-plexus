# Section 02: Advanced Terraform Testing

## 📚 Introduction

Now that you understand testing basics, let's explore advanced patterns including module testing, integration tests, mocking, and test organization strategies.

**Time to Complete**: 60-90 minutes  
**Prerequisites**: Section 01 completed

---

## 🎯 Learning Objectives

After completing this section, you will:

- Test reusable Terraform modules
- Write integration tests across multiple modules
- Use multiple test scenarios in one file
- Organize tests for large projects
- Apply testing best practices
- Use expect_failures for negative testing

---

## 🧩 Module Testing

### Why Test Modules?

Modules are reusable components, so they must be reliable:

- ✅ **Input validation**: Ensure variables work as expected
- ✅ **Output correctness**: Verify outputs are properly exposed
- ✅ **Multiple scenarios**: Test with different configurations
- ✅ **Contract testing**: Ensure module interface is stable

### Module Test Structure

```hcl
# modules/compute/main.tf
resource "google_compute_instance" "vm" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  # ...
}

# compute.tftest.hcl
run "test_default_values" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "test-vm"
  }
  
  assert {
    condition     = google_compute_instance.vm.machine_type == "e2-micro"
    error_message = "Default machine type should be e2-micro"
  }
}
```

### Testing Module Inputs

```hcl
# Test with custom values
run "test_custom_machine_type" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "test-vm"
    machine_type  = "e2-medium"
  }
  
  assert {
    condition     = google_compute_instance.vm.machine_type == "e2-medium"
    error_message = "Should use provided machine type"
  }
}
```

### Testing Module Outputs

```hcl
run "test_module_outputs" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "test-vm"
  }
  
  # Test that outputs are exposed
  assert {
    condition     = output.instance_id != null
    error_message = "Module must export instance_id"
  }
  
  assert {
    condition     = output.instance_self_link != null
    error_message = "Module must export instance_self_link"
  }
}
```

---

## 🔗 Integration Testing

### Testing Module Composition

When modules work together, test their integration:

```hcl
# main.tf - using multiple modules
module "networking" {
  source = "./modules/networking"
  
  vpc_name = "test-vpc"
  subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
}

module "compute" {
  source = "./modules/compute"
  
  network_id = module.networking.vpc_id
  subnet_id  = module.networking.subnet_ids[0]
}

# integration.tftest.hcl
run "test_networking_and_compute" {
  command = plan
  
  # Test that compute module receives correct network ID
  assert {
    condition     = module.compute.network_id == module.networking.vpc_id
    error_message = "Compute should use networking VPC"
  }
  
  # Test resource creation
  assert {
    condition     = length(google_compute_instance.vm) > 0
    error_message = "Compute instances should be created"
  }
}
```

### Testing Data Flow

```hcl
run "test_data_flow_between_modules" {
  command = plan
  
  # Verify networking module creates VPC
  assert {
    condition     = google_compute_network.vpc.name == "test-vpc"
    error_message = "VPC should be created with correct name"
  }
  
  # Verify compute uses that VPC
  assert {
    condition     = google_compute_instance.vm[0].network_interface[0].network == google_compute_network.vpc.id
    error_message = "VM should be connected to the VPC"
  }
}
```

---

## 🎭 Multiple Test Scenarios

### Using Variables for Different Scenarios

```hcl
# Test dev environment configuration
run "test_dev_environment" {
  command = plan
  
  variables {
    environment  = "dev"
    machine_type = "e2-micro"
    disk_size    = 10
  }
  
  assert {
    condition     = google_compute_instance.vm.machine_type == "e2-micro"
    error_message = "Dev should use e2-micro"
  }
  
  assert {
    condition     = google_compute_instance.vm.boot_disk[0].initialize_params[0].size == 10
    error_message = "Dev should use 10GB disk"
  }
}

# Test prod environment configuration
run "test_prod_environment" {
  command = plan
  
  variables {
    environment  = "prod"
    machine_type = "n2-standard-2"
    disk_size    = 50
  }
  
  assert {
    condition     = google_compute_instance.vm.machine_type == "n2-standard-2"
    error_message = "Prod should use n2-standard-2"
  }
  
  assert {
    condition     = google_compute_instance.vm.boot_disk[0].initialize_params[0].size == 50
    error_message = "Prod should use 50GB disk"
  }
}
```

---

## ❌ Negative Testing with expect_failures

### Testing Validation Rules

```hcl
# Test that invalid input fails
run "test_invalid_machine_type_fails" {
  command = plan
  
  variables {
    machine_type = "invalid-type"
  }
  
  # Expect this to fail due to validation
  expect_failures = [
    var.machine_type
  ]
}

# Test that variable validation works
run "test_environment_validation" {
  command = plan
  
  variables {
    environment = "testing"  # Not in allowed list
  }
  
  expect_failures = [
    var.environment
  ]
}
```

### Why Negative Testing Matters

```hcl
# In variables.tf
variable "environment" {
  type = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

# In test file
run "test_invalid_environment_rejected" {
  command = plan
  
  variables {
    environment = "test"  # Should fail
  }
  
  expect_failures = [
    var.environment  # This validation should fail
  ]
}
```

---

## 📁 Test Organization

### Single Test File

Good for small projects:

```
project/
├── main.tf
├── variables.tf
└── tests.tftest.hcl  # All tests in one file
```

### Multiple Test Files by Feature

Better for larger projects:

```
project/
├── main.tf
├── variables.tf
└── tests/
    ├── networking.tftest.hcl    # Network-related tests
    ├── compute.tftest.hcl        # Compute-related tests
    ├── storage.tftest.hcl        # Storage-related tests
    └── integration.tftest.hcl    # Integration tests
```

### Module-Specific Tests

For reusable modules:

```
modules/
└── compute/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── tests/
        ├── defaults.tftest.hcl      # Test default values
        ├── custom-config.tftest.hcl # Test custom configurations
        └── validation.tftest.hcl    # Test input validation
```

---

## 🎯 Testing Patterns

### Pattern 1: Test Module Defaults

```hcl
run "module_uses_sensible_defaults" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "test"
    # No other variables - testing defaults
  }
  
  assert {
    condition     = google_compute_instance.vm.machine_type == "e2-micro"
    error_message = "Should default to e2-micro"
  }
  
  assert {
    condition     = google_compute_instance.vm.allow_stopping_for_update == true
    error_message = "Should allow stopping for updates by default"
  }
}
```

### Pattern 2: Test Required Variables

```hcl
run "required_variables_enforced" {
  command = plan
  
  # Intentionally omit required variable
  variables {
    # instance_name is required but not provided
  }
  
  expect_failures = [
    var.instance_name
  ]
}
```

### Pattern 3: Test Output Types

```hcl
run "outputs_have_correct_types" {
  command = plan
  
  variables {
    instance_name = "test"
  }
  
  assert {
    condition     = can(regex("^projects/.*/zones/.*/instances/.*", output.instance_id))
    error_message = "instance_id should be a valid GCP resource ID"
  }
  
  assert {
    condition     = length(output.instance_tags) >= 0
    error_message = "instance_tags should be a list"
  }
}
```

### Pattern 4: Test Conditional Resources

```hcl
# main.tf
resource "google_compute_firewall" "ssh" {
  count = var.enable_ssh ? 1 : 0
  # ...
}

# test.tftest.hcl
run "ssh_enabled_when_requested" {
  command = plan
  
  variables {
    enable_ssh = true
  }
  
  assert {
    condition     = length(google_compute_firewall.ssh) == 1
    error_message = "SSH firewall should be created when enabled"
  }
}

run "ssh_disabled_when_not_requested" {
  command = plan
  
  variables {
    enable_ssh = false
  }
  
  assert {
    condition     = length(google_compute_firewall.ssh) == 0
    error_message = "SSH firewall should not be created when disabled"
  }
}
```

### Pattern 5: Test for_each and count

```hcl
# main.tf
resource "google_compute_instance" "vms" {
  for_each = var.instances
  
  name = each.key
  # ...
}

# test.tftest.hcl
run "creates_correct_number_of_instances" {
  command = plan
  
  variables {
    instances = {
      "web-1" = { machine_type = "e2-micro" }
      "web-2" = { machine_type = "e2-micro" }
      "web-3" = { machine_type = "e2-micro" }
    }
  }
  
  assert {
    condition     = length(google_compute_instance.vms) == 3
    error_message = "Should create 3 instances"
  }
  
  assert {
    condition     = google_compute_instance.vms["web-1"].name == "web-1"
    error_message = "Instance names should match keys"
  }
}
```

---

## 🧪 Advanced Testing Techniques

### Using Local Values in Tests

```hcl
run "test_with_locals" {
  command = plan
  
  variables {
    environment = "prod"
  }
  
  # Access locals from main.tf
  assert {
    condition     = local.name_prefix == "prod"
    error_message = "Name prefix should match environment"
  }
}
```

### Testing Data Sources

```hcl
# main.tf
data "google_compute_zones" "available" {
  region = var.region
}

# test.tftest.hcl
run "test_data_source" {
  command = plan
  
  variables {
    region = "us-central1"
  }
  
  assert {
    condition     = length(data.google_compute_zones.available.names) > 0
    error_message = "Should find available zones"
  }
  
  assert {
    condition     = contains(data.google_compute_zones.available.names, "us-central1-a")
    error_message = "Should include us-central1-a zone"
  }
}
```

### Testing with Mock Providers (Future Feature)

*Note: Full mocking support is being developed. Currently, use `command = plan` for most tests.*

---

## 💡 Best Practices

### ✅ DO

1. **Test module contracts**
   ```hcl
   # Test that module provides expected outputs
   assert {
     condition = output.vpc_id != null
   }
   ```

2. **Test multiple scenarios**
   ```hcl
   run "test_dev" { ... }
   run "test_staging" { ... }
   run "test_prod" { ... }
   ```

3. **Test validation rules**
   ```hcl
   run "test_invalid_input" {
     expect_failures = [var.invalid_variable]
   }
   ```

4. **Organize tests logically**
   - Separate files for different components
   - Clear test names
   - Group related tests

5. **Keep tests fast**
   - Use `command = plan` by default
   - Only use `apply` when necessary

### ❌ DON'T

1. **Don't test Terraform internals**
   ```hcl
   # ❌ Bad - testing Terraform's functionality
   assert {
     condition = can(tostring("test"))
   }
   ```

2. **Don't make tests interdependent**
   ```hcl
   # ❌ Bad - test2 depends on test1
   run "test1" { ... }
   run "test2" {  # Assumes test1 ran
     assert { condition = ... }
   }
   ```

3. **Don't ignore test failures**
   - Fix immediately
   - Don't disable tests
   - Investigate root cause

4. **Don't over-test**
   - Focus on critical paths
   - Test module contracts, not implementation details
   - Balance coverage with maintainability

---

## 🎓 Practice Exercise

### Challenge: Test a Networking Module

Create a VPC module and comprehensive tests:

**Requirements**:
1. Create `modules/networking/` with VPC + subnets
2. Write tests for:
   - Default configuration
   - Custom CIDR ranges
   - Multiple subnets
   - Output validation
   - Invalid input handling

**Starter Code**:

```hcl
# modules/networking/main.tf
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets
  
  name          = each.key
  ip_cidr_range = each.value.cidr
  region        = each.value.region
  network       = google_compute_network.vpc.id
}
```

**Your Task**: Write `networking.tftest.hcl` with at least 5 test cases!

<details>
<summary>💡 Solution (Click to expand)</summary>

```hcl
# networking.tftest.hcl

run "vpc_created_with_correct_name" {
  command = plan
  
  module {
    source = "./modules/networking"
  }
  
  variables {
    vpc_name = "test-vpc"
    subnets  = {}
  }
  
  assert {
    condition     = google_compute_network.vpc.name == "test-vpc"
    error_message = "VPC name should match input"
  }
  
  assert {
    condition     = google_compute_network.vpc.auto_create_subnetworks == false
    error_message = "Auto-create subnets should be disabled"
  }
}

run "subnets_created_correctly" {
  command = plan
  
  module {
    source = "./modules/networking"
  }
  
  variables {
    vpc_name = "test-vpc"
    subnets = {
      "subnet-1" = {
        cidr   = "10.0.1.0/24"
        region = "us-central1"
      }
      "subnet-2" = {
        cidr   = "10.0.2.0/24"
        region = "us-west1"
      }
    }
  }
  
  assert {
    condition     = length(google_compute_subnetwork.subnets) == 2
    error_message = "Should create 2 subnets"
  }
  
  assert {
    condition     = google_compute_subnetwork.subnets["subnet-1"].ip_cidr_range == "10.0.1.0/24"
    error_message = "Subnet CIDR should match input"
  }
}

run "outputs_exported_correctly" {
  command = plan
  
  module {
    source = "./modules/networking"
  }
  
  variables {
    vpc_name = "test-vpc"
    subnets = {
      "subnet-1" = {
        cidr   = "10.0.1.0/24"
        region = "us-central1"
      }
    }
  }
  
  assert {
    condition     = output.vpc_id != null
    error_message = "VPC ID must be exported"
  }
  
  assert {
    condition     = output.vpc_self_link != null
    error_message = "VPC self link must be exported"
  }
}
```

</details>

---

## 📚 Key Takeaways

### What You Learned

- ✅ Testing reusable modules with different configurations
- ✅ Integration testing across modules
- ✅ Multiple test scenarios in one file
- ✅ Negative testing with expect_failures
- ✅ Test organization strategies
- ✅ Advanced testing patterns

### Next Steps

1. **Practice**: Complete the networking module exercise
2. **Apply**: Test modules from previous lessons
3. **Experiment**: Try different test patterns
4. **Continue**: Work through [Example 02: Module Testing](../examples/02-module-test/README.md)

---

## 🔗 Related Resources

- [Example 02: Module Testing](../examples/02-module-test/README.md)
- [Example 03: Integration Testing](../examples/03-integration-test/README.md)
- [Back to Lesson 06 README](../README.md)
- [Terraform Test Documentation](https://developer.hashicorp.com/terraform/language/tests)

---

**Ready to see these patterns in action? Continue to [Example 02: Module Testing](../examples/02-module-test/README.md)!** 🚀
