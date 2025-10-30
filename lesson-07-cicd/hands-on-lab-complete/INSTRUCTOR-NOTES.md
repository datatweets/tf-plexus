# Instructor Notes - Multi-Environment Terraform CI/CD Pipeline

## Overview

This complete implementation is ready for testing and can be shared with students after validation.

## What's Been Created

### Directory Structure
```
lesson-07-cicd/hands-on-lab-complete/
├── terraform/
│   ├── modules/compute/          # Reusable module
│   │   ├── main.tf              # VPC, subnet, firewall, VMs
│   │   ├── variables.tf         # With validation rules
│   │   └── outputs.tf
│   └── environments/
│       ├── dev/                 # 1 VM, e2-micro
│       ├── staging/             # 2 VMs, e2-small
│       └── prod/                # 3 VMs, e2-medium
├── azure-pipelines.yml          # Complete 4-stage pipeline
├── .gitignore
├── setup.sh                     # Quick setup script
├── README.md                    # Detailed instructions
├── QUICKSTART.md               # Fast-track guide
├── TESTING-CHECKLIST.md        # Complete testing checklist
└── INSTRUCTOR-NOTES.md         # This file
```

### Total Files Created: 23 files

## Key Features Implemented

### 1. Multi-Environment Architecture
- **Dev**: Smallest resources, auto-deploy, fast feedback
- **Staging**: Medium resources, auto-deploy, pre-prod testing
- **Production**: Largest resources, **manual approval required**

### 2. Pipeline Stages
```
Validate → Dev → Staging → Production (⏸️ approval)
  (2min)   (3min)  (4min)     (5min)
```

### 3. Manual Approval Gate
- Configured via Azure DevOps Environments
- Uses `environment: 'terraform-prod'` in pipeline
- Requires explicit approval before production deployment
- Tracks approval history and approvers

### 4. Best Practices
- ✅ DRY: Reusable compute module
- ✅ Environment isolation: Separate state files
- ✅ Input validation: Terraform validation blocks
- ✅ Version control: All config in Git
- ✅ Change control: Manual approval for prod
- ✅ Auditability: Pipeline logs + deployment history
- ✅ Security: Service account with least privilege

## Testing Instructions

### Before Sharing with Students

1. **Complete Setup** (~10 minutes)
   - Run through QUICKSTART.md yourself
   - Use your own GCP project
   - Set up Azure DevOps completely

2. **Test Full Pipeline** (~25 minutes)
   - Push code and trigger pipeline
   - Watch all 4 stages execute
   - Verify manual approval works
   - Check GCP resources created

3. **Use Testing Checklist** (~60 minutes)
   - Go through TESTING-CHECKLIST.md
   - Document any issues
   - Update docs if needed
   - Test cleanup procedures

4. **Test Documentation** (~15 minutes)
   - Follow README.md step-by-step
   - Verify all commands work
   - Check for typos/errors
   - Ensure prerequisites are clear

### Expected Costs

**For Full Testing:**
- 6 VMs running for 1 hour: ~$0.30
- 3 GCS buckets (minimal): ~$0.01
- **Total**: ~$0.31 per test run

**Student Lab:**
- Same costs if they complete quickly
- Budget ~$1-2 per student for full lab

## Common Student Issues & Solutions

### Issue 1: "Permission denied on GCP"
**Cause**: Service account not granted Editor role
**Solution**:
```bash
gcloud projects add-iam-policy-binding PROJECT-ID \
  --member="serviceAccount:terraform-pipeline@PROJECT.iam.gserviceaccount.com" \
  --role="roles/editor"
```

### Issue 2: "Secure file not found"
**Cause**: File not uploaded or wrong name
**Solution**:
- File must be named exactly: `terraform-pipeline-key.json`
- Must be authorized for pipeline

### Issue 3: "Production deploys without approval"
**Cause**: Approval not configured on environment
**Solution**:
- Verify approval added to `terraform-prod` environment
- Check YAML uses: `environment: 'terraform-prod'`

### Issue 4: "Backend initialization failed"
**Cause**: State bucket doesn't exist or no access
**Solution**:
```bash
# Create bucket
gsutil mb gs://PROJECT-ID-dev-tfstate
# Enable versioning
gsutil versioning set on gs://PROJECT-ID-dev-tfstate
```

### Issue 5: "Variable not defined"
**Cause**: Variable group not created or not linked
**Solution**:
- Create `terraform-variables` group in Azure DevOps Library
- Add: GCP_PROJECT_ID, GCP_REGION, TF_VERSION
- Ensure pipeline references: `- group: terraform-variables`

## Teaching Tips

### Pre-Lab Preparation
1. **Time Allocation**: This is a 2-3 hour lab
   - Setup: 30 minutes
   - First deployment: 25 minutes
   - Testing/changes: 30 minutes
   - Cleanup: 15 minutes
   - Buffer: 30-60 minutes

2. **Prerequisites Check**:
   - Students have GCP accounts with billing
   - Students have Azure DevOps access
   - Students completed Lessons 1-5
   - Students understand basic CI/CD concepts

3. **Pre-Create Resources** (Optional):
   - Create service accounts beforehand
   - Pre-create Azure DevOps projects
   - Share template repositories

### During the Lab

1. **Common Sticking Points**:
   - Azure DevOps UI navigation (provide screenshots)
   - GCP service account permissions (demo this)
   - Manual approval process (show them first)
   - Git push to trigger pipeline (common mistakes)

2. **Monitoring Progress**:
   - Check Azure DevOps pipeline status for each student
   - Look for common errors in pipeline logs
   - Verify GCP resources are being created

3. **Time Management**:
   - Set checkpoints at each stage
   - Dev deployment by 45 minutes
   - Production approval by 90 minutes
   - Cleanup by 120 minutes

### After the Lab

1. **Verify Cleanup**:
   - Check students destroyed all resources
   - Verify no unexpected GCP charges
   - Ensure state buckets deleted

2. **Collect Feedback**:
   - What was confusing?
   - What took longer than expected?
   - What documentation needs improvement?

## Customization Options

### For Shorter Lab (1 hour)
- Remove staging environment
- Pre-create service accounts
- Provide pre-configured Azure DevOps

### For Longer Lab (4 hours)
- Add automated testing
- Implement drift detection
- Add security scanning (tfsec)
- Implement rollback procedures

### For Different Cloud Providers
- AWS: Replace GCS with S3, use AWS provider
- Azure: Use Azure Storage for state, ARM provider
- Multi-cloud: Keep GCP, show how to add AWS

## Files to Customize Before Sharing

1. **terraform.tfvars.example files**
   - Update project ID placeholder if needed
   - Adjust machine types for cost constraints
   - Change regions if needed

2. **README.md**
   - Add your organization-specific instructions
   - Update support contact information
   - Add your troubleshooting tips

3. **azure-pipelines.yml**
   - Adjust Terraform version if needed
   - Modify timeout values for slower environments
   - Add organization-specific steps

## Version Information

- **Terraform Version**: 1.9.0 (configurable via variable)
- **GCP Provider**: ~> 5.0
- **Azure Pipelines**: ubuntu-latest
- **Tested On**: [Add your testing date]

## Additional Resources for Students

Recommend these after completion:
1. Terraform testing (lesson-06-testing)
2. GitHub Actions alternative (if applicable)
3. Advanced topics: workspaces, remote state locking
4. Security: tfsec, checkov, sentinel policies

## Maintenance Notes

**Review Quarterly**:
- [ ] Update Terraform version in pipeline
- [ ] Update GCP provider version
- [ ] Test with latest Azure Pipelines ubuntu image
- [ ] Verify GCP API changes haven't broken anything
- [ ] Update cost estimates

**After Each Teaching Session**:
- [ ] Document new issues encountered
- [ ] Update troubleshooting section
- [ ] Collect student feedback
- [ ] Improve unclear documentation

## Contact & Support

When sharing with students, provide:
- Office hours for help
- Slack/Teams channel for questions
- Expected response time
- Escalation path for urgent issues

---

## Your Testing Checklist

Before sharing with students:
- [ ] Completed full pipeline test
- [ ] Verified all GCP resources created
- [ ] Tested manual approval flow
- [ ] Confirmed cleanup works
- [ ] Reviewed all documentation
- [ ] Tested setup.sh script
- [ ] Estimated actual costs
- [ ] Prepared backup materials
- [ ] Created support channel
- [ ] Scheduled lab time

**Tester**: ___________________________
**Date**: ___________________________
**Status**: ⬜ READY ⬜ NEEDS UPDATES

**Notes**:
