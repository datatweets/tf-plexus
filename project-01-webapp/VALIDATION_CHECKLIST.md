# Validation Checklist for Hands-On Project #1

## Pre-Deployment Validation

### Environment Setup
- [ ] GCP project created with billing enabled
- [ ] gcloud CLI installed and authenticated (`gcloud auth list`)
- [ ] Terraform >= 1.0 installed (`terraform version`)
- [ ] Required APIs enabled:
  - [ ] `compute.googleapis.com`
  - [ ] `sqladmin.googleapis.com`
  - [ ] `storage.googleapis.com`

### Code Quality Checks
- [ ] All modules pass `terraform validate`
- [ ] Code formatted with `terraform fmt`
- [ ] No hardcoded credentials
- [ ] `terraform.tfvars` added to `.gitignore`

---

## Module Validation

### Networking Module
- [ ] VPC resource properly defined
- [ ] Subnets created using `for_each`
- [ ] Firewall rules use dynamic `allow` blocks
- [ ] All outputs defined correctly
- [ ] Can run `terraform init` and `terraform validate` successfully

#### Testing Commands:
```bash
cd modules/networking
terraform init
terraform validate
terraform fmt -check
```

### Compute Module
- [ ] Instances created using `count`
- [ ] Startup script file exists and is referenced correctly
- [ ] Lifecycle rules implemented
- [ ] Load balancer components conditionally created
- [ ] Health check configured properly
- [ ] Instance group references all instances
- [ ] All 7 load balancer resources defined

#### Testing Commands:
```bash
cd modules/compute
terraform init
terraform validate
```

### Database Module
- [ ] Cloud SQL instance defined
- [ ] Conditional backup configuration
- [ ] Dynamic `authorized_networks` blocks
- [ ] Lifecycle `prevent_destroy` implemented
- [ ] Database and user resources defined
- [ ] Sensitive outputs marked correctly

#### Testing Commands:
```bash
cd modules/database
terraform init
terraform validate
```

### Storage Module
- [ ] Random ID for bucket suffix
- [ ] Buckets created with `for_each`
- [ ] Dynamic `lifecycle_rule` blocks
- [ ] Versioning configurable per bucket
- [ ] Labels applied to all buckets

#### Testing Commands:
```bash
cd modules/storage
terraform init
terraform validate
```

---

## Environment Validation

### Development Environment

#### Pre-Apply Checks:
- [ ] `terraform.tfvars` created from example
- [ ] Project ID set correctly
- [ ] Region and zone specified
- [ ] All variable values appropriate for dev

#### Deployment:
```bash
cd environments/dev
terraform init
terraform plan -out=tfplan
# Review plan carefully
terraform apply tfplan
```

#### Post-Apply Validation:
- [ ] All resources created successfully (check output)
- [ ] No errors in apply output
- [ ] State file created locally or in GCS
- [ ] Outputs displayed correctly

#### Infrastructure Tests:
- [ ] VPC created: `gcloud compute networks describe <vpc-name>`
- [ ] Subnets exist: `gcloud compute networks subnets list`
- [ ] Instances running: `gcloud compute instances list`
- [ ] Load balancer exists: `gcloud compute forwarding-rules list`
- [ ] Database accessible: `gcloud sql instances list`
- [ ] Buckets created: `gsutil ls`

#### Functional Tests:
- [ ] Get load balancer IP: `terraform output load_balancer_ip`
- [ ] Access web application: `curl http://<lb-ip>`
- [ ] Verify HTML contains "Plexus"
- [ ] Verify instance name shown
- [ ] Refresh multiple times - see different instances (load balancing works)
- [ ] Health check responds: `curl http://<lb-ip>/health` returns "OK"
- [ ] Can SSH to instance: `gcloud compute ssh <instance-name>`
- [ ] Database connection command works: `terraform output -raw database_connection_command`

---

### Production Environment

#### Pre-Apply Checks:
- [ ] Separate `terraform.tfvars` for production
- [ ] Different project or resource prefix
- [ ] Larger instance types configured
- [ ] Backups enabled
- [ ] Deletion protection enabled
- [ ] Force destroy disabled

#### Deployment:
```bash
cd environments/prod
terraform init
terraform plan -out=tfplan
# Review plan carefully - check costs!
terraform apply tfplan
```

#### Post-Apply Validation:
- [ ] 3 instances created (not 2)
- [ ] e2-medium machine type (not e2-micro)
- [ ] db-g1-small database (not db-f1-micro)
- [ ] Backups enabled and configured
- [ ] Deletion protection active

#### Difference Verification:
```bash
# Compare resource counts
cd environments/dev && terraform state list > /tmp/dev-resources.txt
cd environments/prod && terraform state list > /tmp/prod-resources.txt
diff /tmp/dev-resources.txt /tmp/prod-resources.txt
```

---

## State Management Validation

### Remote State Setup
- [ ] GCS bucket created for state
- [ ] Versioning enabled on bucket
- [ ] Backend configuration uncommented
- [ ] State migrated successfully: `terraform init -migrate-state`
- [ ] Local state file removed
- [ ] State in GCS verified: `gsutil ls gs://<bucket>/terraform/state/`

### State Operations:
```bash
terraform state list           # List all resources
terraform state show <resource> # Show resource details
terraform refresh              # Sync state with real infrastructure
```

---

## Concept Mastery Checklist

### Can you answer these?
- [ ] **count vs for_each**: When to use each? What are tradeoffs?
- [ ] **Dynamic blocks**: How do they reduce code duplication?
- [ ] **Lifecycle rules**: Why use `create_before_destroy`?
- [ ] **Conditional resources**: How does `count = condition ? 1 : 0` work?
- [ ] **For expressions**: How to transform a map of resources into a map of IDs?
- [ ] **Splat operator**: What does `[*]` do? When to use it?
- [ ] **Module design**: What makes a good module boundary?
- [ ] **State management**: Why is remote state important for teams?
- [ ] **Environment strategy**: Directory structure vs workspaces - pros/cons?

---

## Security Validation

### Credentials:
- [ ] No hardcoded passwords in `.tf` files
- [ ] Database password in `terraform.tfvars` (not in code)
- [ ] `terraform.tfvars` in `.gitignore`
- [ ] Sensitive outputs marked with `sensitive = true`
- [ ] No service account keys committed to Git

### Network Security:
- [ ] SSH access restricted (not 0.0.0.0/0 in production)
- [ ] Database not publicly accessible (or with authorized networks)
- [ ] Storage buckets have `public_access_prevention = "enforced"`
- [ ] Firewall rules follow least privilege

### Production Safety:
- [ ] `deletion_protection = true` for critical resources
- [ ] `prevent_destroy` in lifecycle for production database
- [ ] `force_destroy = false` for production buckets
- [ ] Backups enabled in production

---

## Cost Validation

### Pre-Deployment:
- [ ] Reviewed cost estimates in README
- [ ] Appropriate instance sizes for environment
- [ ] Budget alerts configured in GCP (optional)
- [ ] Team aware of costs

### Post-Deployment:
- [ ] Verified actual resources match plan
- [ ] No unexpected resources created
- [ ] Billing shows expected charges
- [ ] Cleanup plan scheduled

### Development:
- [ ] Using smallest viable instance types
- [ ] Backups disabled to save costs
- [ ] Plan to destroy resources daily

### Production:
- [ ] Instance sizes justify the cost
- [ ] Backups scheduled appropriately
- [ ] Retention periods reasonable
- [ ] Long-term costs budgeted

---

## Cleanup Validation

### Before Destroying:
- [ ] Backup any important data
- [ ] Export state for reference: `terraform show > final-state.txt`
- [ ] Document any manual changes made
- [ ] Notify team of planned destruction

### Destruction Process:
```bash
# Development
cd environments/dev
terraform plan -destroy        # Review what will be destroyed
terraform destroy              # Confirm destruction

# Production (if deletion_protection enabled)
# 1. First disable protection
terraform apply -var="deletion_protection=false"
# 2. Then destroy
terraform destroy
```

### Post-Destruction:
- [ ] All compute instances gone: `gcloud compute instances list`
- [ ] Database deleted: `gcloud sql instances list`
- [ ] Buckets removed: `gsutil ls`
- [ ] VPC cleaned up: `gcloud compute networks list`
- [ ] No unexpected resources remain
- [ ] Billing stopped

### State Cleanup:
```bash
# Remove state buckets if no longer needed
gsutil -m rm -r gs://plexus-terraform-state-dev
gsutil -m rm -r gs://plexus-terraform-state-prod
```

---

## Documentation Validation

### Code Documentation:
- [ ] All resources have description in variables
- [ ] Complex logic has inline comments
- [ ] Each module has clear purpose
- [ ] README exists for project

### Personal Documentation:
- [ ] Architecture diagram created
- [ ] Deployment notes documented
- [ ] Lessons learned captured
- [ ] Reflection questions answered

---

## Final Assessment

### Technical Competency:
- [ ] All modules implemented correctly
- [ ] Both environments deployed successfully
- [ ] Infrastructure tested and validated
- [ ] Resources cleaned up properly

### Concept Understanding:
- [ ] Can explain all Terraform code written
- [ ] Understands count vs for_each tradeoffs
- [ ] Can describe dynamic blocks use cases
- [ ] Comprehends module design principles
- [ ] Articulates environment management strategy

### Best Practices:
- [ ] Code follows Terraform style guide
- [ ] Variables properly defined and documented
- [ ] Outputs useful and well-named
- [ ] Security considerations addressed
- [ ] Cost optimization applied

---

## Troubleshooting Checklist

If something doesn't work, check:

### General:
- [ ] Ran `terraform init` after changes?
- [ ] Ran `terraform validate` to check syntax?
- [ ] Reviewed error message carefully?
- [ ] Checked Terraform documentation?
- [ ] Looked at master version for reference?

### API Errors:
- [ ] API enabled in GCP Console?
- [ ] Sufficient permissions?
- [ ] Correct project ID?
- [ ] Quota available?

### State Issues:
- [ ] State lock released?
- [ ] Backend configured correctly?
- [ ] GCS bucket accessible?
- [ ] State file not corrupted?

### Resource Creation:
- [ ] Required fields populated?
- [ ] Resource names unique?
- [ ] Dependencies satisfied?
- [ ] Timeouts sufficient?

---

## Success Criteria

### You have successfully completed this project when you can check ALL of these:

#### Deployment:
- [ ] ✅ Dev environment deployed and functional
- [ ] ✅ Prod environment deployed with different configuration
- [ ] ✅ Remote state configured and working
- [ ] ✅ All resources accessible and tested

#### Infrastructure:
- [ ] ✅ Web application accessible via load balancer
- [ ] ✅ Load balancing working (instances rotate)
- [ ] ✅ Health checks passing
- [ ] ✅ Database connection works
- [ ] ✅ Storage buckets accessible

#### Code Quality:
- [ ] ✅ All modules pass `terraform validate`
- [ ] ✅ Code properly formatted
- [ ] ✅ No hardcoded credentials
- [ ] ✅ Appropriate comments and documentation

#### Concepts:
- [ ] ✅ Demonstrated count meta-argument
- [ ] ✅ Demonstrated for_each meta-argument
- [ ] ✅ Implemented dynamic blocks
- [ ] ✅ Used for expressions
- [ ] ✅ Applied lifecycle rules
- [ ] ✅ Created reusable modules
- [ ] ✅ Managed multiple environments

#### Understanding:
- [ ] ✅ Can explain every line of code
- [ ] ✅ Answered all reflection questions
- [ ] ✅ Documented architecture decisions
- [ ] ✅ Identified lessons learned

#### Cleanup:
- [ ] ✅ All resources destroyed successfully
- [ ] ✅ No orphaned resources in GCP
- [ ] ✅ State buckets cleaned up
- [ ] ✅ Billing stopped

---

## Submission Checklist (For Students)

Include in your submission:

### Required:
- [ ] All implemented Terraform code (student-version)
- [ ] `terraform.tfvars.example` (NOT actual tfvars with credentials)
- [ ] Architecture diagram (can be hand-drawn or digital)
- [ ] Reflection questions answers
- [ ] Screenshot of successful `terraform apply`
- [ ] Screenshot of working web application

### Optional:
- [ ] Deployment notes and challenges faced
- [ ] Comparison of dev vs prod configurations
- [ ] Cost analysis
- [ ] Bonus challenges attempted

---

## Instructor Review Checklist

### Code Review:
- [ ] Modules properly structured
- [ ] Variables and outputs well-defined
- [ ] Resources correctly configured
- [ ] Best practices followed

### Functionality:
- [ ] Infrastructure deploys without errors
- [ ] All components work as expected
- [ ] Environment differences appropriate
- [ ] Security considerations addressed

### Understanding:
- [ ] Reflection questions answered thoroughly
- [ ] Can explain design decisions
- [ ] Demonstrates concept mastery
- [ ] Shows critical thinking

### Overall Assessment:
- [ ] Meets all success criteria
- [ ] Ready for real-world Terraform projects
- [ ] Grade: _____ / 100

---

**Congratulations on completing this comprehensive Terraform project! 🎉**
