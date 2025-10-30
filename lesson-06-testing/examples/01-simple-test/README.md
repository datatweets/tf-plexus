# Example 01: Simple Resource Test

## 📚 Overview

This example demonstrates the basics of Terraform testing by testing a single Compute Engine VM instance.

**What You'll Learn**:
- Creating a basic test file
- Writing simple assertions
- Testing resource attributes
- Running tests locally

**Time**: 20 minutes

---

## 🏗️ Infrastructure

A simple VM instance with:
- Machine type: `e2-micro`
- Zone: `us-central1-a`
- Network tags: `web`, `ssh`
- Debian 11 boot disk

---

## 📁 Files

- `main.tf` - VM resource configuration
- `variables.tf` - Input variables
- `outputs.tf` - Resource outputs
- `simple.tftest.hcl` - Test file
- `README.md` - This file

---

## 🚀 Quick Start

### 1. Set Your GCP Project

```bash
export TF_VAR_project_id="YOUR_PROJECT_ID"
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Run the Tests

```bash
terraform test
```

Expected output:
```
Success! 5 passed, 0 failed.
```

---

## 📝 What's Being Tested

### Test 1: Machine Type
Verifies the VM uses `e2-micro` (cost-effective).

### Test 2: Zone Placement
Ensures the VM is in `us-central1-a`.

### Test 3: Network Tags
Checks that the VM has proper network tags.

### Test 4: Outputs
Validates that outputs are not empty.

### Test 5: Custom Machine Type
Tests variable override functionality.

---

## 🔍 Understanding the Test File

### Structure

```hcl
run "test_name" {
  command = plan
  
  variables {
    # Override variables
  }
  
  assert {
    condition = ...
    error_message = "..."
  }
}
```

### Why `command = plan`?

- ⚡ **Fast**: No real resources created
- 💰 **Free**: No GCP charges
- 🔒 **Safe**: Can't break anything

Use `apply` only for integration tests that need real resources.

---

## 💡 Try This

### Experiment 1: Break a Test

Change `machine_type` default in `variables.tf` to `e2-small`:

```bash
terraform test
```

You'll see a failed assertion! This demonstrates how tests catch unintended changes.

### Experiment 2: Add a New Test

Add this to `simple.tftest.hcl`:

```hcl
run "verify_boot_disk" {
  command = plan
  
  variables {
    project_id = "test-project"
  }
  
  assert {
    condition     = google_compute_instance.test_vm.boot_disk[0].initialize_params[0].image == "debian-cloud/debian-11"
    error_message = "Must use Debian 11"
  }
}
```

Run `terraform test` again to see it pass!

### Experiment 3: Test Different Zones

```hcl
run "test_different_zone" {
  command = plan
  
  variables {
    project_id = "test-project"
    zone       = "us-west1-a"
  }
  
  assert {
    condition     = google_compute_instance.test_vm.zone == "us-west1-a"
    error_message = "Zone should match variable"
  }
}
```

---

## 🎯 Key Concepts

### 1. Tests Don't Need Real Projects

Notice `project_id = "test-project"` in tests. With `command = plan`, Terraform validates configuration without touching GCP!

### 2. Multiple Assertions Per Test

Each `run` block can have multiple `assert` blocks. All must pass.

### 3. Variable Overrides

Tests can override any variable:

```hcl
variables {
  machine_type = "e2-small"
  zone         = "us-west1-a"
}
```

### 4. Error Messages are Important

Write clear error messages:

```hcl
# ✅ Good
error_message = "Expected machine type e2-micro, got ${google_compute_instance.test_vm.machine_type}"

# ❌ Bad
error_message = "Wrong type"
```

---

## 🐛 Troubleshooting

### "terraform test: command not found"

**Solution**: Upgrade to Terraform 1.6.0 or higher:

```bash
terraform version
```

### Test fails with "project_id not set"

**Solution**: Set the variable:

```bash
export TF_VAR_project_id="your-project"
```

Or use a `terraform.tfvars` file (but `.gitignore` it!).

### "Error: Insufficient provider auth"

**Solution**: Tests with `command = plan` don't need real credentials! But if you see this:

```bash
# Authenticate
gcloud auth application-default login
```

---

## ✅ Success Criteria

You've completed this example when:

- [ ] Tests run successfully (`terraform test`)
- [ ] You understand each assertion
- [ ] You can add your own test case
- [ ] You've experimented with breaking tests

---

## 🔗 Next Steps

1. **Review the code**: Open each file and understand it
2. **Modify tests**: Try adding new assertions
3. **Move on**: Continue to [Example 02: Module Test](../02-module-test/README.md)

---

## 📚 Additional Resources

- [Back to Lesson 06 README](../../README.md)
- [Section 01: Testing Basics](../../section-01-basics.md)
- [Terraform Test Documentation](https://developer.hashicorp.com/terraform/language/tests)
