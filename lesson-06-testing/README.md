# Lesson 06: Terraform Testing

## 📚 Overview

Learn how to write comprehensive tests for your Terraform infrastructure using the native `terraform test` framework. This lesson teaches you to validate your infrastructure code before deployment, catch errors early, and ensure your modules work as expected.

**Duration**: 2-3 hours  
**Difficulty**: Intermediate  
**Prerequisites**: Lessons 1-4 (especially Module development)

---

## 🎯 Learning Objectives

By the end of this lesson, you will be able to:

- ✅ Understand why infrastructure testing is critical
- ✅ Write Terraform tests using `.tftest.hcl` files
- ✅ Test individual resources and complete modules
- ✅ Use assertions to validate infrastructure properties
- ✅ Create integration tests across multiple modules
- ✅ Integrate testing into your development workflow
- ✅ Debug and troubleshoot failing tests

---

## 🧐 Why Test Infrastructure Code?

### The Problem

Without testing:
- 💥 **Bugs in production**: Errors only discovered after deployment
- 💰 **Costly mistakes**: Resources created incorrectly, leading to unexpected bills
- ⏰ **Slow feedback**: Wait for `terraform apply` to find configuration errors
- 😰 **Lack of confidence**: Fear of breaking things with changes

### The Solution

With Terraform testing:
- ✅ **Early error detection**: Catch issues before deployment
- ✅ **Faster feedback**: Tests run in seconds, not minutes
- ✅ **Refactoring confidence**: Change code knowing tests will catch breakage
- ✅ **Documentation**: Tests show how modules should be used
- ✅ **Team collaboration**: Tests ensure consistent behavior

---

## 📖 What You'll Learn

### Section 01: Testing Basics
- Introduction to `terraform test`
- Test file structure (`.tftest.hcl`)
- Writing your first test
- Running tests locally
- Understanding test output
- Basic assertions

**Time**: 45 minutes  
**File**: [section-01-basics.md](./section-01-basics.md)

### Section 02: Advanced Testing
- Testing modules with inputs/outputs
- Multiple test scenarios
- Integration testing patterns
- Mocking and test doubles
- expect_failures blocks
- Test organization best practices

**Time**: 60 minutes  
**File**: [section-02-advanced.md](./section-02-advanced.md)

---

## 🔨 Hands-On Examples

### Example 01: Simple Resource Test
**Path**: `examples/01-simple-test/`  
**Focus**: Testing a single Compute Engine VM  
**Concepts**: Basic test structure, simple assertions  
**Time**: 20 minutes

Learn to:
- Write a basic `.tftest.hcl` file
- Test resource properties (machine type, zone, disk)
- Run tests with `terraform test`
- Interpret test results

### Example 02: Module Testing
**Path**: `examples/02-module-test/`  
**Focus**: Testing a reusable compute module  
**Concepts**: Testing inputs, outputs, multiple resources  
**Time**: 30 minutes

Learn to:
- Test module variables and defaults
- Validate module outputs
- Test multiple resource configurations
- Use `run` blocks for different scenarios

### Example 03: Integration Testing
**Path**: `examples/03-integration-test/`  
**Focus**: Testing multiple modules together  
**Concepts**: Module composition, end-to-end validation  
**Time**: 40 minutes

Learn to:
- Test networking + compute integration
- Validate resource relationships
- Test cross-module dependencies
- Create realistic test scenarios

---

## 🚀 Quick Start

### 1. Prerequisites Check

```bash
# Verify Terraform version (1.6.0+ required for testing)
terraform version

# Should show 1.6.0 or higher
```

### 2. Navigate to Examples

```bash
cd lesson-06-testing/examples/01-simple-test
```

### 3. Run Your First Test

```bash
# Initialize Terraform
terraform init

# Run the tests
terraform test

# See the results!
```

### 4. Expected Output

```
Success! 3 passed, 0 failed.
```

---

## 📂 Lesson Structure

```
lesson-06-testing/
├── README.md                          # This file
├── section-01-basics.md              # Testing fundamentals
├── section-02-advanced.md            # Advanced patterns
│
└── examples/
    ├── 01-simple-test/               # Basic resource testing
    │   ├── main.tf                   # Simple VM resource
    │   ├── variables.tf              # Input variables
    │   ├── outputs.tf                # Resource outputs
    │   ├── simple.tftest.hcl         # Test file
    │   └── README.md                 # Example guide
    │
    ├── 02-module-test/               # Module testing
    │   ├── modules/
    │   │   └── compute/              # Compute module
    │   │       ├── main.tf
    │   │       ├── variables.tf
    │   │       └── outputs.tf
    │   ├── main.tf                   # Module usage
    │   ├── compute.tftest.hcl        # Module tests
    │   └── README.md
    │
    └── 03-integration-test/          # Integration testing
        ├── modules/
        │   ├── networking/           # Network module
        │   └── compute/              # Compute module
        ├── main.tf                   # Full stack
        ├── integration.tftest.hcl    # Integration tests
        └── README.md
```

---

## 🎓 Key Concepts

### Test File Structure

```hcl
# Example test file: example.tftest.hcl

# Test case (can have multiple)
run "verify_vm_configuration" {
  command = plan  # or apply
  
  # Assertions
  assert {
    condition     = google_compute_instance.vm.machine_type == "e2-micro"
    error_message = "VM must use e2-micro for cost efficiency"
  }
  
  assert {
    condition     = google_compute_instance.vm.zone == "us-central1-a"
    error_message = "VM must be in us-central1-a zone"
  }
}
```

### Test Commands

| Command | Description | Use When |
|---------|-------------|----------|
| `plan` | Tests configuration without creating resources | Quick validation, most tests |
| `apply` | Creates actual resources | Integration tests, real environment validation |

### Assertion Syntax

```hcl
assert {
  condition     = <boolean expression>
  error_message = "Custom error message"
}
```

---

## 💡 Testing Best Practices

### ✅ DO

- **Write tests first** (Test-Driven Development)
- **Test one concept per test case**
- **Use descriptive test names** (`verify_vpc_cidr_configuration`)
- **Test both success and failure scenarios**
- **Keep tests fast** (prefer `plan` over `apply`)
- **Test module contracts** (inputs → outputs)
- **Use meaningful error messages**

### ❌ DON'T

- **Don't test Terraform itself** (assume providers work)
- **Don't test every possible configuration** (focus on critical paths)
- **Don't make tests depend on external state**
- **Don't ignore test failures** (fix immediately)
- **Don't create expensive resources in tests** (use small/cheap resources)

---

## 🔄 Testing Workflow

### Development Cycle

```
1. Write Terraform code
   ↓
2. Write tests
   ↓
3. Run terraform test
   ↓
4. Tests fail? → Fix code → Go to step 3
   ↓
5. Tests pass? → Continue development
   ↓
6. Refactor with confidence
```

### Integration with Git Workflow

```bash
# Before committing
terraform fmt -recursive
terraform validate
terraform test

# If all pass, commit
git add .
git commit -m "Add networking module with tests"
```

---

## 🛠️ Common Test Patterns

### 1. Testing Resource Attributes

```hcl
run "verify_instance_type" {
  command = plan
  
  assert {
    condition     = google_compute_instance.vm.machine_type == var.machine_type
    error_message = "Machine type mismatch"
  }
}
```

### 2. Testing Module Outputs

```hcl
run "verify_vpc_id_output" {
  command = plan
  
  assert {
    condition     = output.vpc_id != ""
    error_message = "VPC ID must be exported"
  }
}
```

### 3. Testing Counts/Lengths

```hcl
run "verify_subnet_count" {
  command = plan
  
  assert {
    condition     = length(google_compute_subnetwork.subnets) == 3
    error_message = "Must create exactly 3 subnets"
  }
}
```

### 4. Testing with Variables

```hcl
run "test_dev_environment" {
  command = plan
  
  variables {
    environment = "dev"
    machine_type = "e2-micro"
  }
  
  assert {
    condition     = google_compute_instance.vm.machine_type == "e2-micro"
    error_message = "Dev must use e2-micro"
  }
}
```

---

## 📊 Example Test Output

### Successful Test

```
$ terraform test

tests/simple.tftest.hcl... in progress
  run "verify_vm_configuration"... pass
  run "verify_network_interface"... pass
  run "verify_disk_configuration"... pass
tests/simple.tftest.hcl... tearing down
tests/simple.tftest.hcl... pass

Success! 3 passed, 0 failed.
```

### Failed Test

```
$ terraform test

tests/simple.tftest.hcl... in progress
  run "verify_vm_configuration"... fail
╷
│ Error: Test assertion failed
│ 
│   on simple.tftest.hcl line 8, in run "verify_vm_configuration":
│    8:     condition     = google_compute_instance.vm.machine_type == "e2-micro"
│     ├────────────────
│     │ google_compute_instance.vm.machine_type is "e2-small"
│ 
│ VM must use e2-micro for cost efficiency
╵

Failure! 0 passed, 1 failed.
```

---

## 🎯 Learning Path

### Beginner → Intermediate → Advanced

**Start Here** (If you're new to testing):
1. Read [section-01-basics.md](./section-01-basics.md)
2. Complete Example 01: Simple Test
3. Practice writing assertions
4. Understand `plan` vs `apply`

**Intermediate** (Comfortable with basics):
1. Read [section-02-advanced.md](./section-02-advanced.md)
2. Complete Example 02: Module Test
3. Test one of your own modules
4. Learn multiple test scenarios

**Advanced** (Ready for complex scenarios):
1. Complete Example 03: Integration Test
2. Test project-01-webapp modules
3. Create test suite for production code
4. Implement TDD workflow

---

## 🔗 Integration with Other Lessons

### Builds On
- **Lesson 01**: Terraform basics
- **Lesson 02**: State management
- **Lesson 03**: Variables and functions
- **Lesson 04**: Module development (critical!)

### Prepares For
- **Lesson 07**: CI/CD (run tests in pipelines)
- **Project 01**: Test the webapp modules

### Works With
- **Testing** → **CI/CD** → **Production Deployment**

---

## 📚 Additional Resources

### Official Documentation
- [Terraform Test Documentation](https://developer.hashicorp.com/terraform/language/tests)
- [Writing Terraform Tests](https://developer.hashicorp.com/terraform/tutorials/configuration-language/test)
- [Test Syntax Reference](https://developer.hashicorp.com/terraform/language/tests#test-syntax)

### Best Practices
- [Testing Infrastructure as Code](https://www.hashicorp.com/blog/testing-infrastructure-as-code-on-localhost)
- [Module Testing Patterns](https://developer.hashicorp.com/terraform/language/modules/testing-experiment)

---

## ✅ What's Next?

After completing this lesson:

1. **Practice**: Test the modules from previous lessons
2. **Apply**: Add tests to project-01-webapp
3. **Integrate**: Move to Lesson 07 (CI/CD) to automate testing
4. **Share**: Help others by reviewing their test code

---

## 🆘 Getting Help

### Common Issues

**"terraform test not found"**
- Update to Terraform 1.6.0 or higher

**"Tests are too slow"**
- Use `command = plan` instead of `apply`
- Avoid creating expensive resources

**"Tests pass locally but fail in CI/CD"**
- Check provider credentials
- Verify Terraform version consistency

### Questions?
- Review the section guides
- Check example README files
- Re-read this overview

---

## 📝 Summary

**What you learned:**
- ✅ Why infrastructure testing matters
- ✅ How to write `.tftest.hcl` files
- ✅ Testing resources and modules
- ✅ Writing effective assertions
- ✅ Integration testing patterns

**Skills gained:**
- 🎯 Catch errors before deployment
- 🎯 Refactor code with confidence
- 🎯 Document module usage through tests
- 🎯 Validate infrastructure contracts

**Next steps:**
- 📖 Read [section-01-basics.md](./section-01-basics.md)
- 🔨 Complete the examples
- 🚀 Move to Lesson 07: CI/CD

---

**Ready to start? Let's begin with [Section 01: Testing Basics](./section-01-basics.md)!** 🚀
