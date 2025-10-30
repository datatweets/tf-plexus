# Example 01: Multi-Stage Terraform Pipeline

## Overview

This example demonstrates a production-ready Azure DevOps pipeline for Terraform with three distinct stages: Validate, Plan, and Deploy. You'll learn secure authentication, proper stage separation, and artifact management.

**What You'll Learn**:
- Multi-stage pipeline architecture
- Secure GCP authentication
- Artifact publishing and consumption
- Variable passing to Terraform
- Stage dependencies and conditions

**Time**: 45 minutes

---

## Pipeline Architecture

```
Stage 1: Validate
├── Install Terraform
├── Download GCP credentials
├── Initialize (no backend)
└── Validate syntax

Stage 2: Plan
├── Install Terraform
├── Download GCP credentials  
├── Initialize with backend
├── Generate execution plan
├── Display plan summary
└── Publish plan artifact

Stage 3: Deploy (Optional)
├── Install Terraform
├── Download GCP credentials
├── Initialize with backend
├── Download plan artifact
└── Apply changes (commented out for safety)
```

The pipeline automatically triggers on changes to `.tf` files or `azure-pipelines.yml`.

---

## Files in This Example

- `main.tf` - VM instance configuration with labels and lifecycle rules
- `variables.tf` - Input variables with validation
- `outputs.tf` - Resource outputs
- `azure-pipelines.yml` - Multi-stage pipeline definition
- `terraform.tfvars.example` - Example variable values
- `.gitignore` - Git ignore patterns
- `README.md` - This file

---

## Prerequisites

Complete [Section 01: Setup](../../section-01-setup.md) first:

- Azure DevOps project created
- GCP service account created with Editor role
- Service account key uploaded to Secure Files as `terraform-ci-key.json`
- Variable group `terraform-variables` created with:
  - `TF_VERSION`: 1.9.5
  - `TF_STATE_BUCKET`: your-project-tfstate
  - `GCP_PROJECT_ID`: your-gcp-project-id
  - `GCP_REGION`: us-central1
- State bucket created in GCS

---

## Quick Start

### Step 1: Review Configuration

This repository is already configured and ready to use. The pipeline uses:

- Trigger paths: `/*.tf` and `/azure-pipelines.yml`
- Working directory: `$(System.DefaultWorkingDirectory)` (repository root)
- Backend prefix: `examples/01-basic-pipeline`

### Step 2: Create Pipeline in Azure DevOps

1. Navigate to **Pipelines** in your Azure DevOps project
2. Click **New pipeline**
3. Select **Azure Repos Git** (or your repository source)
4. Select your repository
5. Choose **Existing Azure Pipelines YAML file**
6. Select branch: `main`
7. Select path: `/azure-pipelines.yml`
8. Click **Continue** then **Run**

### Step 3: Watch Pipeline Execute

The pipeline will run three stages:

1. **Validate** (~1 minute) - Syntax validation without backend
2. **Plan** (~2 minutes) - Generate execution plan and publish artifact
3. **Deploy** (~1 minute) - Show deployment message (apply is disabled)

**Total Duration**: ~4 minutes

---

## Pipeline Details

### Trigger Configuration

```yaml
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - '/*.tf'
      - '/azure-pipelines.yml'
```

Triggers automatically on:

- Pushes to `main` branch
- Changes to `.tf` files in repository root
- Changes to `azure-pipelines.yml`

### Variable Configuration

```yaml
variables:
  - group: terraform-variables  # From Pipeline Library
  - name: working_directory
    value: '$(System.DefaultWorkingDirectory)'
```

Uses variables from the `terraform-variables` group plus a local working directory variable.

### Stage 1: Validate

Performs fast syntax validation without connecting to remote backend:

```yaml
- script: |
    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
    terraform init -backend=false
    terraform validate
```

### Stage 2: Plan

Generates execution plan with proper variable passing:

```yaml
- script: |
    terraform plan \
      -var="project_id=$(GCP_PROJECT_ID)" \
      -var="region=$(GCP_REGION)" \
      -out=tfplan
```

Publishes plan as artifact for the Deploy stage.

### Stage 3: Deploy

Configured but disabled by default for safety. Uncomment to enable:

```yaml
# Uncomment to actually apply:
# cp $(Pipeline.Workspace)/terraform-plan/tfplan .
# terraform apply -auto-approve tfplan
```

---

## Infrastructure Components

### Compute Instance

```hcl
resource "google_compute_instance" "pipeline_test_vm" {
  name         = "pipeline-test-vm-${var.environment}"
  machine_type = var.machine_type  # default: e2-micro
  zone         = var.zone
  
  # Includes:
  # - Debian 11 boot disk (10GB)
  # - No external IP (commented out)
  # - Environment tags and labels
  # - OS Login enabled
  # - Lifecycle rules
}
```

**Note**: The apply step is commented out, so no actual resources are created.

---

## Success Indicators

### Successful Pipeline Run

All three stages should show green checkmarks:

1. **Validate**: Syntax validation completes
2. **Plan**: Execution plan generated and artifact published
3. **Deploy**: Message displayed (no actual deployment)

### Expected Output

```text
Stage 1 - Validate:
Success! The configuration is valid.

Stage 2 - Plan:
Terraform will perform the following actions:
  # google_compute_instance.pipeline_test_vm will be created
  + resource "google_compute_instance" "pipeline_test_vm" {
      + name         = "pipeline-test-vm-dev"
      + machine_type = "e2-micro"
      ...
    }
Plan: 1 to add, 0 to change, 0 to destroy.

Stage 3 - Deploy:
Apply step is commented out for safety
```

---

## Troubleshooting

### Error: "Could not download secure file"

**Symptoms**:

```text
##[error]Could not find secure file 'terraform-ci-key.json'
```

**Solution**:

1. Verify file name in **Pipelines** → **Library** → **Secure files**
2. Check exact name matches in `azure-pipelines.yml`
3. Authorize pipeline to use the secure file

### Error: "google: could not find default credentials"

**Symptoms**:

```text
Error: google: could not find default credentials
```

**Solution**:

Ensure `GOOGLE_APPLICATION_CREDENTIALS` is set in every Terraform step:

```yaml
- script: |
    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
    terraform plan
  env:
    GOOGLE_APPLICATION_CREDENTIALS: $(gcpKey.secureFilePath)
```

### Error: "Backend initialization required"

**Symptoms**:

```text
Error: Backend initialization required
```

**Solution**:

1. Verify bucket exists: `gsutil ls gs://YOUR-BUCKET-NAME`
2. Check bucket name in variable group
3. Ensure service account has Storage Object Admin role

### Error: "Permission denied" on state bucket

**Symptoms**:

```text
Error: Failed to get existing workspaces: storage: Permission denied
```

**Solution**:

Grant storage permissions to service account:

```bash
gsutil iam ch \
  serviceAccount:terraform-ci@PROJECT_ID.iam.gserviceaccount.com:roles/storage.objectAdmin \
  gs://YOUR_BUCKET
```

### Error: "Project not found"

**Symptoms**:

```text
Error: googleapi: Error 404: The resource 'projects/...' was not found
```

**Solution**:

1. Verify `GCP_PROJECT_ID` variable is correct
2. Check service account belongs to the project
3. Ensure billing is enabled

### Pipeline Not Triggering Automatically

**Symptoms**:

Pipeline doesn't run when pushing `.tf` file changes.

**Solution**:

1. Check trigger paths in `azure-pipelines.yml`
2. Verify trigger configuration in Azure DevOps **Pipelines** → **Edit** → **Triggers**
3. Run pipeline manually once after updating trigger configuration

---

## Testing the Pipeline

### Test 1: Trigger on .tf File Change

Modify a variable description:

```bash
# Edit variables.tf
vim variables.tf

# Commit and push
git add variables.tf
git commit -m "Test: Update variable description"
git push origin main
```

Watch the pipeline trigger automatically.

### Test 2: Trigger on Pipeline Change

Modify the pipeline YAML:

```bash
# Edit azure-pipelines.yml
vim azure-pipelines.yml

# Commit and push  
git add azure-pipelines.yml
git commit -m "Test: Update pipeline configuration"
git push origin main
```

Pipeline should trigger on this change as well.

### Test 3: Review Plan Output

After the Plan stage completes:

1. Click on the **Plan** stage
2. Click on **Generate Plan** task
3. Review the Terraform plan output
4. Verify resource changes match expectations

---

## Key Concepts

### 1. Multi-Stage Pipelines

Stages run sequentially with dependencies:

```yaml
stages:
  - stage: Validate
  - stage: Plan
    dependsOn: Validate
  - stage: Deploy
    dependsOn: Plan
```

### 2. Secure Credential Management

Credentials are downloaded at runtime and never committed:

```yaml
- task: DownloadSecureFile@1
  name: gcpKey
  inputs:
    secureFile: 'terraform-ci-key.json'
```

### 3. Artifact Management

Plans are published and consumed across stages:

```yaml
# Publish in Plan stage
- publish: $(working_directory)/tfplan
  artifact: terraform-plan

# Download in Deploy stage
- download: current
  artifact: terraform-plan
```

### 4. Variable Passing

Variables from the group are passed to Terraform:

```yaml
terraform plan \
  -var="project_id=$(GCP_PROJECT_ID)" \
  -var="region=$(GCP_REGION)"
```

### 5. Working Directory

Pipeline uses the repository root:

```yaml
variables:
  - name: working_directory
    value: '$(System.DefaultWorkingDirectory)'
```

---

## Enabling Actual Deployment

To enable real infrastructure deployment:

### Step 1: Update Deploy Stage

In `azure-pipelines.yml`, uncomment the apply command:

```yaml
- script: |
    export GOOGLE_APPLICATION_CREDENTIALS=$(gcpKey.secureFilePath)
    cd $(working_directory)
    
    # Copy plan from artifact
    cp $(Pipeline.Workspace)/terraform-plan/tfplan .
    
    # Apply the plan
    terraform apply -auto-approve tfplan
  displayName: 'Terraform Apply'
```

### Step 2: Add Manual Approval (Recommended)

Create an environment in Azure DevOps:

1. Go to **Pipelines** → **Environments**
2. Click **New environment**
3. Name: `production`
4. Add **Approvals and checks**
5. Add yourself as approver

Update the Deploy stage to use the environment:

```yaml
- stage: Deploy
  jobs:
    - deployment: ApplyInfrastructure
      environment: 'production'  # Requires approval
```

### Step 3: Test Carefully

Start with a non-production project to test the deployment flow.

---

## Next Steps

### What You Accomplished

- Created a multi-stage pipeline with Validate, Plan, and Deploy
- Configured secure authentication with GCP
- Set up automatic triggers
- Published and consumed Terraform plan artifacts
- Learned troubleshooting techniques

### Continue Learning

1. **Review Azure DevOps runs**: Analyze timing and logs
2. **Experiment with changes**: Modify infrastructure and watch pipeline run
3. **Add more stages**: Consider adding testing or security scanning
4. **Move to multi-environment**: See [Example 03: Multi-Environment](../03-multi-environment/README.md)

---

## Related Resources

- [Azure DevOps Multi-Stage Pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/stages)
- [Terraform GCS Backend Documentation](https://developer.hashicorp.com/terraform/language/settings/backends/gcs)
- [Section 02: Pipeline Patterns](../../section-02-basic-pipeline.md)
- [Example 03: Multi-Environment Pipeline](../03-multi-environment/README.md)

---

**Pipeline working successfully? Continue to [Example 03: Multi-Environment](../03-multi-environment/README.md) for advanced deployment patterns!**
