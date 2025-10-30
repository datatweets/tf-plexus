# Testing Checklist for Instructors

Use this checklist to test the complete pipeline before sharing with students.

## Pre-Testing Setup

- [ ] GCP project created and billing enabled
- [ ] Compute Engine API enabled
- [ ] Storage API enabled
- [ ] gcloud CLI installed and configured
- [ ] Azure DevOps organization and project ready
- [ ] Git repository created in Azure DevOps

## Phase 1: GCP Setup (15 minutes)

### Service Account
- [ ] Created service account: `terraform-pipeline`
- [ ] Granted Editor role to service account
- [ ] Downloaded key file: `terraform-pipeline-key.json`
- [ ] Key file is valid JSON format

### State Buckets
- [ ] Created dev state bucket: `PROJECT-ID-dev-tfstate`
- [ ] Created staging state bucket: `PROJECT-ID-staging-tfstate`
- [ ] Created prod state bucket: `PROJECT-ID-prod-tfstate`
- [ ] Versioning enabled on all three buckets
- [ ] Verified buckets exist: `gsutil ls | grep tfstate`

### Update Configuration Files
- [ ] Ran setup script: `./setup.sh YOUR-PROJECT-ID`
- [ ] Verified backend.tf files have correct bucket names
- [ ] Verified terraform.tfvars files have correct project ID
- [ ] All files created successfully

## Phase 2: Azure DevOps Setup (10 minutes)

### Secure Files
- [ ] Navigated to Pipelines → Library → Secure files
- [ ] Uploaded `terraform-pipeline-key.json`
- [ ] File name is exactly: `terraform-pipeline-key.json`
- [ ] Authorized pipeline to use secure file

### Variable Group
- [ ] Created variable group: `terraform-variables`
- [ ] Added variable: `GCP_PROJECT_ID` = your-project-id
- [ ] Added variable: `GCP_REGION` = us-central1
- [ ] Added variable: `TF_VERSION` = 1.9.0
- [ ] Saved variable group

### Environments
- [ ] Created environment: `terraform-dev`
- [ ] Created environment: `terraform-staging`
- [ ] Created environment: `terraform-prod`
- [ ] All three environments show in Environments list

### Production Approval Configuration
- [ ] Opened `terraform-prod` environment
- [ ] Clicked ⋮ → Approvals and checks
- [ ] Added Approvals check
- [ ] Added yourself as approver
- [ ] Set instructions: "Review Terraform plan before approving"
- [ ] Minimum approvers: 1
- [ ] Saved approval configuration
- [ ] "Approvals" shows under terraform-prod checks

## Phase 3: Repository Setup (5 minutes)

- [ ] Initialized git repository: `git init`
- [ ] Added remote: `git remote add origin <URL>`
- [ ] Added all files: `git add .`
- [ ] Committed: `git commit -m "Add multi-environment pipeline"`
- [ ] Pushed to Azure DevOps: `git push -u origin main`
- [ ] Verified files appear in Azure DevOps repository

## Phase 4: Pipeline Creation (5 minutes)

- [ ] Navigated to Pipelines → Pipelines
- [ ] Clicked New pipeline
- [ ] Selected repository
- [ ] Chose "Existing Azure Pipelines YAML file"
- [ ] Selected `/azure-pipelines.yml`
- [ ] Pipeline YAML loaded successfully
- [ ] Clicked Run

## Phase 5: Pipeline Execution Testing (25-35 minutes)

### Validate Stage (Expected: 2-3 minutes)
- [ ] Stage started automatically
- [ ] Terraform installed successfully
- [ ] GCP key downloaded
- [ ] Module validation passed
- [ ] Dev environment validation passed
- [ ] Staging environment validation passed
- [ ] Prod environment validation passed
- [ ] Stage completed with green checkmark

### Dev Stage (Expected: 3-4 minutes)
- [ ] Stage started automatically after Validate
- [ ] Environment shows: `terraform-dev`
- [ ] Terraform init completed
- [ ] Terraform plan created
- [ ] Terraform apply executed
- [ ] No errors during apply
- [ ] Outputs saved as artifact
- [ ] Artifact `dev-outputs` published
- [ ] Stage completed with green checkmark

### Staging Stage (Expected: 4-5 minutes)
- [ ] Stage started automatically after Dev
- [ ] Environment shows: `terraform-staging`
- [ ] Terraform init completed
- [ ] Terraform plan created (shows 2 VMs)
- [ ] Terraform apply executed
- [ ] No errors during apply
- [ ] Outputs saved as artifact
- [ ] Artifact `staging-outputs` published
- [ ] Stage completed with green checkmark

### Production Stage (Expected: 5-6 minutes + approval time)
- [ ] Stage shows "Waiting for approval"
- [ ] **MANUAL ACTION**: Clicked Review button
- [ ] Approval dialog appeared
- [ ] Reviewed the request
- [ ] Added comment: "Reviewed and approved for testing"
- [ ] Clicked Approve
- [ ] Stage started after approval
- [ ] Environment shows: `terraform-prod`
- [ ] Terraform init completed
- [ ] Terraform plan created (shows 3 VMs)
- [ ] Terraform apply executed
- [ ] No errors during apply
- [ ] Deployment summary displayed
- [ ] Outputs saved as artifact
- [ ] Artifact `prod-outputs` published
- [ ] Stage completed with green checkmark
- [ ] All stages show green checkmarks

## Phase 6: GCP Resource Verification (5 minutes)

### Dev Environment
```bash
gcloud compute instances list --project=PROJECT-ID --filter="name:dev-*"
```
- [ ] 1 VM exists: `dev-vm-1`
- [ ] Machine type: e2-micro
- [ ] Status: RUNNING
- [ ] Has external IP
- [ ] VPC network exists: `dev-vpc`
- [ ] Subnet exists: `dev-subnet`

### Staging Environment
```bash
gcloud compute instances list --project=PROJECT-ID --filter="name:staging-*"
```
- [ ] 2 VMs exist: `staging-vm-1`, `staging-vm-2`
- [ ] Machine type: e2-small
- [ ] Status: RUNNING
- [ ] Both have external IPs
- [ ] VPC network exists: `staging-vpc`
- [ ] Subnet exists: `staging-subnet`

### Production Environment
```bash
gcloud compute instances list --project=PROJECT-ID --filter="name:prod-*"
```
- [ ] 3 VMs exist: `prod-vm-1`, `prod-vm-2`, `prod-vm-3`
- [ ] Machine type: e2-medium
- [ ] Status: RUNNING
- [ ] All have external IPs
- [ ] VPC network exists: `prod-vpc`
- [ ] Subnet exists: `prod-subnet`

### State Files
```bash
gsutil ls -l gs://PROJECT-ID-dev-tfstate/terraform/state/
gsutil ls -l gs://PROJECT-ID-staging-tfstate/terraform/state/
gsutil ls -l gs://PROJECT-ID-prod-tfstate/terraform/state/
```
- [ ] Dev state file exists
- [ ] Staging state file exists
- [ ] Prod state file exists
- [ ] All state files have size > 0

## Phase 7: Change Testing (10 minutes)

### Make a Change
- [ ] Updated dev terraform.tfvars (change machine_type to e2-small)
- [ ] Committed change: `git commit -m "test: Upgrade dev VM"`
- [ ] Pushed change: `git push origin main`

### Verify Pipeline Triggers
- [ ] Pipeline automatically triggered
- [ ] Validate stage passed
- [ ] Dev stage shows changes
- [ ] Staging stage shows "No changes"
- [ ] Prod stage shows "No changes"
- [ ] Dev VM upgraded successfully

## Phase 8: Environment History (2 minutes)

- [ ] Navigated to Pipelines → Environments
- [ ] Clicked `terraform-dev`
- [ ] Deployment history shows 2 deployments
- [ ] Shows who deployed
- [ ] Shows when deployed
- [ ] Shows pipeline run number
- [ ] Repeated for `terraform-staging` and `terraform-prod`

## Phase 9: Cleanup Testing (10 minutes)

### Manual Terraform Destroy
```bash
cd terraform/environments/prod
export GOOGLE_APPLICATION_CREDENTIALS=~/terraform-pipeline-key.json
terraform init
terraform destroy -auto-approve
```
- [ ] Prod resources destroyed successfully
- [ ] Repeated for staging
- [ ] Repeated for dev

### Delete Buckets
```bash
gsutil -m rm -r gs://PROJECT-ID-dev-tfstate
gsutil -m rm -r gs://PROJECT-ID-staging-tfstate
gsutil -m rm -r gs://PROJECT-ID-prod-tfstate
```
- [ ] All buckets deleted
- [ ] No resources remaining in GCP
- [ ] No unexpected costs

## Phase 10: Documentation Review

- [ ] README.md is clear and complete
- [ ] All commands in README work correctly
- [ ] Setup script works as expected
- [ ] No typos or broken links
- [ ] Prerequisites are accurate
- [ ] Troubleshooting section covers common issues

## Common Issues Encountered

Document any issues you encountered during testing:

| Issue | Solution | Should Update Docs? |
|-------|----------|---------------------|
|       |          |                     |
|       |          |                     |
|       |          |                     |

## Final Approval

- [ ] All checklist items completed successfully
- [ ] Pipeline runs from start to finish without errors
- [ ] All resources created correctly
- [ ] Manual approval works as expected
- [ ] Documentation is accurate
- [ ] Ready to share with students

---

**Tester Name**: ___________________________
**Date**: ___________________________
**Total Time**: ___________________________ minutes
**Overall Status**: ⬜ PASS  ⬜ FAIL (requires fixes)

**Notes**:
