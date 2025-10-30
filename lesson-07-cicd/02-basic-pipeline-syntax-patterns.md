# Section 02: Basic Pipeline Patterns

## Introduction

Now that you've set up Azure DevOps and understand the security fundamentals, let's dive deep into building Azure Pipelines for Terraform. This section covers YAML pipeline syntax, task configuration, and common patterns.
  
**Prerequisites**: Section 01 completed

---

## Learning Objectives

After completing this section, you will:

- Master Azure Pipelines YAML syntax
- Configure Terraform tasks correctly
- Use variables and parameters effectively
- Implement conditional execution
- Handle artifacts and dependencies
- Apply common pipeline patterns

---

## Azure Pipelines YAML Basics

### Pipeline Structure

```yaml
# Basic pipeline structure
trigger:
  - main  # Branches that trigger the pipeline

pool:
  vmImage: 'ubuntu-latest'  # Agent to run on

stages:
  - stage: Validate
    jobs:
      - job: TerraformPlan
        steps:
          - task: SomeTask@version
            inputs:
              key: value
```

### Key Components

1. **Trigger**: When the pipeline runs
2. **Pool**: Where the pipeline runs (agent)
3. **Stages**: High-level phases
4. **Jobs**: Units of work within stages
5. **Steps**: Individual tasks

---

## Terraform Tasks

### Task 1: TerraformInstaller

Install specific Terraform version:

```yaml
steps:
  - task: TerraformInstaller@1
    displayName: 'Install Terraform'
    inputs:
      terraformVersion: '1.9.0'  # Specify exact version
```

**Best Practices**:
- Pin to specific version for consistency
- Use latest stable version
- Test version updates in dev first

### Task 2: TerraformTaskV4

Main Terraform task for all commands:

```yaml
# Terraform Init
- task: TerraformTaskV4@4
  displayName: 'Terraform Init'
  inputs:
    provider: 'azurerm'
    command: 'init'
    workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'
    backendServiceArm: '$(serviceConnectionName)'
    backendAzureRmResourceGroupName: '$(backendResourceGroup)'
    backendAzureRmStorageAccountName: '$(backendStorageAccount)'
    backendAzureRmContainerName: '$(backendContainer)'
    backendAzureRmKey: 'terraform.tfstate'

# Terraform Plan
- task: TerraformTaskV4@4
  displayName: 'Terraform Plan'
  inputs:
    provider: 'azurerm'
    command: 'plan'
    workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'
    environmentServiceNameAzureRM: '$(serviceConnectionName)'
    commandOptions: '-out=$(Build.ArtifactStagingDirectory)/tfplan'

# Terraform Apply
- task: TerraformTaskV4@4
  displayName: 'Terraform Apply'
  inputs:
    provider: 'azurerm'
    command: 'apply'
    workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'
    environmentServiceNameAzureRM: '$(serviceConnectionName)'
    commandOptions: '$(Build.ArtifactStagingDirectory)/tfplan'
```

### Task Input Reference

| Input | Purpose | Example |
|-------|---------|---------|
| `provider` | Cloud provider | `azurerm`, `aws`, `google` |
| `command` | Terraform command | `init`, `plan`, `apply`, `destroy` |
| `workingDirectory` | Where Terraform files are | `$(System.DefaultWorkingDirectory)/terraform` |
| `backendServiceArm` | Service connection for state | `terraform-backend-connection` |
| `environmentServiceNameAzureRM` | Service connection for resources | `terraform-deploy-connection` |
| `commandOptions` | Additional CLI arguments | `-var-file=dev.tfvars` |

---

## Artifact Management

### Publishing Artifacts

Save plan files for later stages:

```yaml
- task: PublishPipelineArtifact@1
  displayName: 'Publish Terraform Plan'
  inputs:
    targetPath: '$(Build.ArtifactStagingDirectory)/tfplan'
    artifact: 'terraform-plan'
    publishLocation: 'pipeline'
```

### Downloading Artifacts

Retrieve artifacts in later stages:

```yaml
- task: DownloadPipelineArtifact@2
  displayName: 'Download Terraform Plan'
  inputs:
    artifact: 'terraform-plan'
    path: '$(Build.ArtifactStagingDirectory)'
```

### Why Use Artifacts?

✅ **Consistency**: Apply the exact plan you reviewed  
✅ **Auditability**: Track what was deployed  
✅ **Multi-stage**: Pass data between stages  
✅ **Approval gates**: Review before applying

---

##  Variables and Parameters

### Pipeline Variables

Define once, use everywhere:

```yaml
variables:
  terraformVersion: '1.9.0'
  workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'
  serviceConnectionName: 'azure-terraform-connection'
  backendResourceGroup: 'rg-terraform-state'
  backendStorageAccount: 'sttfstate12345'
  backendContainer: 'tfstate'

steps:
  - task: TerraformInstaller@1
    inputs:
      terraformVersion: '$(terraformVersion)'
  
  - task: TerraformTaskV4@4
    inputs:
      workingDirectory: '$(workingDirectory)'
      backendServiceArm: '$(serviceConnectionName)'
```

### Variable Groups

Store sensitive values securely:

```yaml
# Link variable group in pipeline
variables:
  - group: 'terraform-secrets'  # Contains sensitive values

# Use in pipeline
steps:
  - script: terraform apply -auto-approve
    env:
      ARM_CLIENT_SECRET: $(clientSecret)  # From variable group
```

### Runtime Parameters

Allow user input at queue time:

```yaml
parameters:
  - name: environment
    displayName: 'Target Environment'
    type: string
    default: 'dev'
    values:
      - dev
      - staging
      - prod
  
  - name: terraformAction
    displayName: 'Terraform Action'
    type: string
    default: 'plan'
    values:
      - plan
      - apply
      - destroy

stages:
  - stage: Deploy_${{ parameters.environment }}
    jobs:
      - job: Terraform
        steps:
          - script: |
              echo "Deploying to ${{ parameters.environment }}"
              echo "Action: ${{ parameters.terraformAction }}"
```

---

## ⚡ Conditional Execution

### Condition Types

**1. Branch Conditions**

```yaml
trigger:
  branches:
    include:
      - main
      - develop
      - release/*

steps:
  - task: TerraformTaskV4@4
    displayName: 'Auto-apply on main'
    condition: eq(variables['Build.SourceBranch'], 'refs/heads/main')
    inputs:
      command: 'apply'
```

**2. Manual Approval**

```yaml
stages:
  - stage: Apply
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - deployment: TerraformApply
        environment: 'production'  # Requires manual approval
        strategy:
          runOnce:
            deploy:
              steps:
                - task: TerraformTaskV4@4
                  inputs:
                    command: 'apply'
```

**3. Variable-Based Conditions**

```yaml
variables:
  autoApprove: false

steps:
  - task: TerraformTaskV4@4
    displayName: 'Apply (if auto-approve enabled)'
    condition: eq(variables['autoApprove'], 'true')
    inputs:
      command: 'apply'
```

**4. Success/Failure Conditions**

```yaml
steps:
  - task: TerraformTaskV4@4
    name: Plan
    inputs:
      command: 'plan'
  
  - task: TerraformTaskV4@4
    displayName: 'Apply (only if plan succeeded)'
    condition: succeeded()
    inputs:
      command: 'apply'
  
  - task: PublishBuildArtifacts@1
    displayName: 'Publish logs on failure'
    condition: failed()
    inputs:
      PathtoPublish: '$(System.DefaultWorkingDirectory)/terraform'
```

---

## Common Pipeline Patterns

### Pattern 1: Plan-Only Pipeline

For PR validation:

```yaml
trigger: none  # Manual trigger only

pr:
  branches:
    include:
      - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  terraformVersion: '1.9.0'
  workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'

stages:
  - stage: Validate
    jobs:
      - job: TerraformValidate
        steps:
          - task: TerraformInstaller@1
            inputs:
              terraformVersion: '$(terraformVersion)'
          
          - task: TerraformTaskV4@4
            displayName: 'Terraform Init'
            inputs:
              provider: 'azurerm'
              command: 'init'
              workingDirectory: '$(workingDirectory)'
              backendServiceArm: 'terraform-backend'
          
          - task: TerraformTaskV4@4
            displayName: 'Terraform Validate'
            inputs:
              provider: 'azurerm'
              command: 'validate'
              workingDirectory: '$(workingDirectory)'
          
          - task: TerraformTaskV4@4
            displayName: 'Terraform Plan'
            inputs:
              provider: 'azurerm'
              command: 'plan'
              workingDirectory: '$(workingDirectory)'
              environmentServiceNameAzureRM: 'terraform-deploy'
          
          - script: |
              echo "✅ Terraform plan succeeded"
              echo "Review output above before merging PR"
            displayName: 'Success Message'
```

### Pattern 2: Plan and Save Artifact

For review workflows:

```yaml
stages:
  - stage: Plan
    jobs:
      - job: TerraformPlan
        steps:
          - task: TerraformInstaller@1
            inputs:
              terraformVersion: '1.9.0'
          
          - task: TerraformTaskV4@4
            displayName: 'Terraform Init'
            inputs:
              provider: 'azurerm'
              command: 'init'
              workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'
              backendServiceArm: 'terraform-backend'
          
          - task: TerraformTaskV4@4
            displayName: 'Terraform Plan'
            inputs:
              provider: 'azurerm'
              command: 'plan'
              workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'
              environmentServiceNameAzureRM: 'terraform-deploy'
              commandOptions: '-out=$(Build.ArtifactStagingDirectory)/tfplan'
          
          - script: |
              terraform show -json $(Build.ArtifactStagingDirectory)/tfplan > $(Build.ArtifactStagingDirectory)/tfplan.json
            displayName: 'Convert Plan to JSON'
            workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'
          
          - task: PublishPipelineArtifact@1
            displayName: 'Publish Plan Artifact'
            inputs:
              targetPath: '$(Build.ArtifactStagingDirectory)'
              artifact: 'terraform-plan'
```

### Pattern 3: Matrix Strategy for Multiple Environments

Deploy to multiple environments in parallel:

```yaml
strategy:
  matrix:
    dev:
      environment: 'dev'
      resourceGroup: 'rg-dev'
      tfvarsFile: 'dev.tfvars'
    staging:
      environment: 'staging'
      resourceGroup: 'rg-staging'
      tfvarsFile: 'staging.tfvars'
    prod:
      environment: 'prod'
      resourceGroup: 'rg-prod'
      tfvarsFile: 'prod.tfvars'

steps:
  - task: TerraformTaskV4@4
    displayName: 'Deploy to $(environment)'
    inputs:
      provider: 'azurerm'
      command: 'apply'
      workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'
      commandOptions: '-var-file=$(tfvarsFile) -auto-approve'
```

### Pattern 4: Terraform with PR Comments

Post plan output to PR:

```yaml
steps:
  - task: TerraformTaskV4@4
    name: Plan
    displayName: 'Terraform Plan'
    inputs:
      provider: 'azurerm'
      command: 'plan'
      workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'
      publishPlanResults: 'tfplan'
  
  - task: PowerShell@2
    displayName: 'Comment Plan on PR'
    condition: eq(variables['Build.Reason'], 'PullRequest')
    inputs:
      targetType: 'inline'
      script: |
        $planOutput = Get-Content "$(System.DefaultWorkingDirectory)/terraform/tfplan.txt"
        
        $comment = @"
        ## Terraform Plan Results
        
        ``````terraform
        $planOutput
        ``````
        "@
        
        # Post to PR using Azure DevOps API
        # (Implementation depends on your setup)
```

---

## Debugging Pipelines

### Enable Verbose Logging

```yaml
steps:
  - task: TerraformTaskV4@4
    displayName: 'Terraform Init (Verbose)'
    inputs:
      provider: 'azurerm'
      command: 'init'
      workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'
    env:
      TF_LOG: DEBUG  # Terraform verbose logging
```

### System Diagnostics

```yaml
variables:
  system.debug: true  # Enable pipeline debug logging

steps:
  - script: |
      echo "Working Directory: $(System.DefaultWorkingDirectory)"
      echo "Build ID: $(Build.BuildId)"
      echo "Source Branch: $(Build.SourceBranch)"
      ls -la $(System.DefaultWorkingDirectory)
    displayName: 'Print Debug Info'
```

### Common Issues and Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| "Backend initialization required" | State not found | Check service connection permissions |
| "Error locking state" | Concurrent runs | Use dependencies between stages |
| "Authentication failed" | Expired credentials | Refresh service connection |
| "File not found" | Wrong working directory | Verify `workingDirectory` path |
| "Provider not found" | Missing `terraform init` | Ensure init runs before other commands |

---

## 💡 Best Practices

### ✅ DO

1. **Pin Terraform Version**
   ```yaml
   terraformVersion: '1.9.0'  # Not 'latest'
   ```

2. **Use Working Directory Variable**
   ```yaml
   variables:
     workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'
   ```

3. **Save Plans as Artifacts**
   ```yaml
   - task: PublishPipelineArtifact@1
     inputs:
       artifact: 'terraform-plan'
   ```

4. **Separate Backend and Deploy Connections**
   ```yaml
   backendServiceArm: 'terraform-backend'
   environmentServiceNameAzureRM: 'terraform-deploy'
   ```

5. **Use Display Names**
   ```yaml
   - task: TerraformTaskV4@4
     displayName: 'Terraform Init - Backend Configuration'
   ```

### ❌ DON'T

1. **Don't use `latest` version**
   ```yaml
   # ❌ Bad
   terraformVersion: 'latest'
   
   # ✅ Good
   terraformVersion: '1.9.0'
   ```

2. **Don't hardcode secrets**
   ```yaml
   # ❌ Bad
   ARM_CLIENT_SECRET: 'my-secret-123'
   
   # ✅ Good
   ARM_CLIENT_SECRET: $(clientSecret)  # From variable group
   ```

3. **Don't skip `terraform init`**
   ```yaml
   # ❌ Bad - Plan without init
   - task: TerraformTaskV4@4
     inputs:
       command: 'plan'
   
   # ✅ Good - Always init first
   - task: TerraformTaskV4@4
     inputs:
       command: 'init'
   - task: TerraformTaskV4@4
     inputs:
       command: 'plan'
   ```

4. **Don't auto-approve without review**
   ```yaml
   # ❌ Bad - Auto-approve in prod
   commandOptions: '-auto-approve'
   
   # ✅ Good - Use manual approval
   environment: 'production'  # Requires approval
   ```

---

## Quick Reference

### Essential Variables

```yaml
variables:
  terraformVersion: '1.9.0'
  workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'
  serviceConnectionName: 'azure-terraform'
  backendResourceGroup: 'rg-tfstate'
  backendStorageAccount: 'sttfstate'
  backendContainer: 'tfstate'
  backendKey: 'terraform.tfstate'
```

### Standard Init Task

```yaml
- task: TerraformTaskV4@4
  displayName: 'Terraform Init'
  inputs:
    provider: 'azurerm'
    command: 'init'
    workingDirectory: '$(workingDirectory)'
    backendServiceArm: '$(serviceConnectionName)'
    backendAzureRmResourceGroupName: '$(backendResourceGroup)'
    backendAzureRmStorageAccountName: '$(backendStorageAccount)'
    backendAzureRmContainerName: '$(backendContainer)'
    backendAzureRmKey: '$(backendKey)'
```

### Standard Plan Task

```yaml
- task: TerraformTaskV4@4
  displayName: 'Terraform Plan'
  inputs:
    provider: 'azurerm'
    command: 'plan'
    workingDirectory: '$(workingDirectory)'
    environmentServiceNameAzureRM: '$(serviceConnectionName)'
    commandOptions: '-out=$(Build.ArtifactStagingDirectory)/tfplan'
```

---

## 🎓 Practice Exercise

### Challenge: Build a Validation Pipeline

Create a pipeline that:

1. Triggers on pull requests to `main`
2. Installs Terraform 1.9.0
3. Runs `terraform fmt -check`
4. Runs `terraform init`
5. Runs `terraform validate`
6. Runs `terraform plan`
7. Posts results as PR comment

**Starter Template**:

```yaml
trigger: none

pr:
  branches:
    include:
      - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  # Add your variables here

stages:
  - stage: Validate
    jobs:
      - job: TerraformValidate
        steps:
          # Add your steps here
```

---

## 📚 Key Takeaways

✅ Azure Pipelines YAML structure (triggers, pools, stages, jobs, steps)  
✅ Terraform task configuration (TerraformInstaller, TerraformTaskV4)  
✅ Artifact management (publish/download plans)  
✅ Variables and parameters (reusability and flexibility)  
✅ Conditional execution (branches, approvals, conditions)  
✅ Common pipeline patterns (plan-only, save artifacts, matrix)


**Great progress!** 🎉 You now understand Azure Pipelines for Terraform. Continue to multi-stage pipelines!
