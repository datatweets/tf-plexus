# Lesson 2: Exploring Terraform

This lesson covers advanced Terraform concepts including state management, team collaboration, and meta-arguments.

## Contents

### Documentation
- **section-01-state-mgm.md** - State management and team collaboration
- **section-02-meta-args.md** - Meta-arguments and advanced concepts

### Code Examples

All examples are ready to run with complete instructions in each directory's README.md.

#### 1. State Management Examples

**statefile/** - Understanding Terraform State
- Basic state file operations
- State inspection commands
- Destructive vs non-destructive changes
- See: `statefile/README.md`

**backend/** - Remote Backend for Team Collaboration
- Google Cloud Storage backend setup
- State locking
- Team collaboration workflows
- See: `backend/README.md`

#### 2. Meta-Arguments Examples

**count/** - The count Meta-Argument
- Creating multiple similar resources
- Using count.index for unique names
- Zone distribution strategies
- Conditional resource creation
- See: `count/README.md`

**for_each/** - The for_each Meta-Argument
- Creating resources with meaningful keys
- Working with maps and objects
- Cross-referencing resources
- Adding/removing resources safely
- See: `for_each/README.md`

**lifecycle/** - The lifecycle Meta-Argument
- create_before_destroy for zero downtime
- prevent_destroy for resource protection
- ignore_changes for external tool harmony
- See: `lifecycle/README.md`

**complete/** - Complete Example Combining All Concepts
- Multi-region VPC infrastructure
- All meta-arguments in action
- Production-ready patterns
- See: `complete/README.md`

## Quick Start

Each example directory contains:
- ✅ Complete Terraform configuration files
- ✅ terraform.tfvars.example for easy setup
- ✅ Comprehensive README.md with instructions
- ✅ .gitignore configured properly

### Running an Example

```bash
# Choose an example
cd statefile  # or backend, count, for_each, lifecycle, complete

# Set up your project
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project ID

# Run Terraform
terraform init
terraform plan
terraform apply
```

## Learning Path

**Recommended order:**

1. **statefile/** - Understand state basics
2. **backend/** - Set up remote state
3. **count/** - Learn simple resource multiplication
4. **for_each/** - Master flexible resource creation
5. **lifecycle/** - Control resource behavior
6. **complete/** - See everything together

## Key Concepts Covered

### Section 1: State Management
- What is Terraform state
- State inspection commands (`terraform state list`, `show`, `console`)
- Destructive vs non-destructive changes
- Remote backend configuration
- State locking for team collaboration
- Best practices for state management

### Section 2: Meta-Arguments
- **count** - Create multiple resources with numeric indices
- **for_each** - Create resources with meaningful keys
- **depends_on** - Explicit dependency management
- **lifecycle** - Control resource creation/destruction behavior
  - create_before_destroy
  - prevent_destroy
  - ignore_changes
- **self_link** - Google Cloud best practice for resource references

## Prerequisites

- Terraform >= 1.9 installed
- Google Cloud account with billing enabled
- gcloud CLI installed and authenticated
- Basic understanding of Terraform from Lesson 1

## Common Setup for All Examples

### 1. Get Your Project ID

```bash
gcloud projects list
# or
gcloud config get-value project
```

### 2. Enable Compute API

```bash
gcloud services enable compute.googleapis.com
```

### 3. Configure terraform.tfvars

Every example includes `terraform.tfvars.example`. Copy and customize:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit with your project ID
```

## Tips

✅ Always run `terraform plan` before `apply`
✅ Use `.gitignore` - never commit state files
✅ Read each example's README.md for specific instructions
✅ Start simple (statefile) and progress to complex (complete)
✅ Experiment! These examples are designed for learning

## Troubleshooting

### API Not Enabled Error
```bash
gcloud services enable compute.googleapis.com
gcloud services enable storage.googleapis.com
```

### Project ID Not Set
Edit `terraform.tfvars` in the example directory:
```hcl
project_id = "your-actual-project-id"
```

### State Lock Error
Someone else is running Terraform. Wait for them to finish, or use:
```bash
terraform force-unlock LOCK-ID  # Use with caution!
```

### Resources Already Exist
If you've run an example before:
```bash
terraform destroy  # Clean up first
```

## Cost Considerations

All examples use minimal resources:
- e2-micro instances (free tier eligible)
- Small disk sizes
- Standard networking

**Remember to clean up after testing:**
```bash
terraform destroy
```

## Next Steps

After completing this lesson, you'll be ready for:
- **Lesson 3**: Modules and code organization
- **Lesson 4**: Managing multiple environments
- **Lesson 5**: Advanced Google Cloud resources
- **Lesson 6**: CI/CD integration

---

**Total Learning Time:** ~2 hours
**Hands-on Examples:** 6 complete, working examples
**Concepts Covered:** 10+ advanced Terraform features

Happy Learning! 🚀
