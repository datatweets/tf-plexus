# Lesson 07: CI/CD with Azure DevOps

## 📚 Overview

Master Terraform automation with Azure DevOps through **hands-on tutorials and comprehensive guides**. You'll learn to build automated pipelines from basic validation to production-ready multi-environment deployments.

**Duration**: 3-4 hours  
**Difficulty**: Intermediate  
**Prerequisites**: Lessons 1-5, Azure DevOps account, GCP project

---

## 🎯 What You'll Build

### Tutorial 1: Basic Multi-Stage Pipeline ⚡
A complete CI/CD pipeline that:
- Validates Terraform code automatically
- Creates execution plans
- Publishes plan artifacts for review
- Deploys infrastructure to GCP (optional deploy stage)
- Manages state remotely in GCS

### Tutorial 2: Multi-Environment Pipeline 🚀
Production-ready deployment workflow with:
- Three environments: Dev, Staging, Production
- Automatic deployment to dev and staging
- Manual approval gates for production
- Environment-specific configurations
- Isolated state management per environment
- Deployment tracking and audit history

---

## 🧐 Why Automate Infrastructure?

### Without CI/CD

```
Developer's Laptop → Manual Commands → GCP
     ❌ Inconsistent          ❌ Error-prone
     ❌ Secrets on laptop     ❌ No audit trail
     ❌ Slow feedback         ❌ Manual reviews
```

### With CI/CD

```
Git Push → Azure Pipeline → Validated & Deployed → GCP
    ✅ Automated          ✅ Consistent
    ✅ Secure secrets     ✅ Full audit log
    ✅ Fast feedback      ✅ Approval gates
```

---

## 📚 Learning Path

This lesson provides multiple learning resources:

### 🎓 Tutorial 1: Basic Multi-Stage Pipeline (1.5-2 hours)

Build your first automated Terraform pipeline with proper stage separation.

**What You'll Learn:**
- Set up Azure DevOps with GCP securely
- Store credentials safely using Secure Files
- Create multi-stage YAML pipeline (Validate → Plan → Deploy)
- Manage remote state in GCS
- Publish and consume plan artifacts

**Resources:**
1. **[Setup & Configuration](./01-basic-pipeline-setup.md)** (60 min)
   - Azure DevOps account creation
   - GCP service account setup
   - State bucket configuration
   - Secure credential storage

2. **[Pipeline Patterns](./section-02-basic-pipeline.md)** (30 min)
   - YAML syntax essentials
   - Terraform tasks configuration
   - Variables and parameters
   - Conditional execution

3. **[Working Example](./examples/01-basic-pipeline/README.md)** (45 min)
   - Complete multi-stage pipeline
   - Step-by-step deployment guide
   - Troubleshooting tips

**✅ End Result:** Working pipeline with three stages: Validate → Plan → Deploy

---

### 🚀 Tutorial 2: Multi-Environment Pipeline (2-2.5 hours)

Scale to production with isolated dev, staging, and production environments.

**What You'll Learn:**
- Deploy to multiple environments from one pipeline
- Configure environment-specific variables
- Implement manual approval workflows
- Track deployment history per environment
- Apply production best practices

**Complete Guide:**
- **[Multi-Environment Hands-On Lab](./02-hands-on-lab-multi-env-cicd-pipeline.md)** (2-2.5 hours)
  - 10 progressive sections with time estimates
  - Explicit file creation steps for VS Code
  - Verification checkpoints throughout
  - Complete working infrastructure code
  - Deployment and testing scenarios
  - Comprehensive troubleshooting guide

**Additional Reference:**
- **[Multi-Environment Example](./examples/02-multi-environment/README.md)**
  - Alternative implementation approach
  - GCP multi-project setup
  - Environment isolation strategies

**✅ End Result:** Production-ready pipeline with approval gates and environment isolation

---

## 🗺️ Tutorial Flow

```
┌────────────────────────────────────────────────────────┐
│       Tutorial 1: Basic Pipeline (1.5-2 hours)         │
├────────────────────────────────────────────────────────┤
│                                                         │
│  Part 1: Setup & Security (60 min)                     │
│  ┌──────────────────────────────────────────────────┐  │
│  │ • Create Azure DevOps organization               │  │
│  │ • Set up GCP service account                     │  │
│  │ • Configure state bucket                         │  │
│  │ • Upload secure credentials                      │  │
│  │ • Create variable groups                         │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  Part 2: Pipeline Patterns (30 min)                    │
│  ┌──────────────────────────────────────────────────┐  │
│  │ • Master YAML structure                          │  │
│  │ • Configure Terraform tasks                      │  │
│  │ • Work with variables                            │  │
│  │ • Implement conditionals                         │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  Part 3: Deploy Working Example (45 min)               │
│  ┌──────────────────────────────────────────────────┐  │
│  │ • Clone example repository                       │  │
│  │ • Create pipeline in Azure DevOps                │  │
│  │ • Run Validate → Plan → Deploy stages            │  │
│  │ • Verify GCP resources created                   │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ✅ You now have: Automated multi-stage pipeline       │
└────────────────────────────────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────────┐
│   Tutorial 2: Multi-Environment Pipeline (2+ hours)    │
├────────────────────────────────────────────────────────┤
│                                                         │
│  Complete Hands-On Lab (10 Sections)                   │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Section 1: Prerequisites & Setup (15 min)        │  │
│  │ Section 2: Azure DevOps Config (10 min)          │  │
│  │ Section 3: GCP Setup (10 min)                    │  │
│  │ Section 4: Basic Validation Pipeline (25 min)    │  │
│  │ Section 5: Build Terraform Modules (30 min)      │  │
│  │ Section 6: Configure Environments (25 min)       │  │
│  │ Section 7: Complete Multi-Stage Pipeline (40 min)│  │
│  │ Section 8: Deploy & Verify (30 min)              │  │
│  │ Section 9: Test & Iterate (20 min)               │  │
│  │ Section 10: Cleanup (10 min)                     │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  Features:                                              │
│  • Step-by-step file creation in VS Code              │
│  • Verification checkpoints after each section        │
│  • Time estimates for planning                        │
│  • Complete infrastructure code provided             │
│  • Discussion questions for understanding            │
│  • Comprehensive troubleshooting guide               │
│                                                         │
│  ✅ You now have: Production-ready CI/CD workflow      │
└────────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start

### Prerequisites Checklist

Before starting, ensure you have:

- [ ] **Azure DevOps Account** - [Create free account](https://dev.azure.com)
- [ ] **GCP Project** with billing enabled - [Create project](https://console.cloud.google.com)
- [ ] **Terraform installed** - Version 1.6.0+ (`terraform version`)
- [ ] **gcloud CLI installed** - Latest version (`gcloud version`)
- [ ] **Basic Git knowledge** - Clone, commit, push
- [ ] **VS Code** (recommended) - For hands-on labs

### Start Learning

**Recommended Path:**

1. **Start with Tutorial 1 Setup** → [01-basic-pipeline-setup.md](./01-basic-pipeline-setup.md)
2. **Learn Pipeline Patterns** → [section-02-basic-pipeline.md](./section-02-basic-pipeline.md)
3. **Deploy First Pipeline** → [examples/01-basic-pipeline](./examples/01-basic-pipeline/README.md)
4. **Build Multi-Environment** → [02-hands-on-lab-multi-env-cicd-pipeline.md](./02-hands-on-lab-multi-env-cicd-pipeline.md)

**Alternative Path (Hands-On First):**

1. **Jump to Multi-Environment Lab** → [02-hands-on-lab-multi-env-cicd-pipeline.md](./02-hands-on-lab-multi-env-cicd-pipeline.md)
   - Includes all setup steps
   - Self-contained tutorial
   - Builds from scratch

---

## 📂 Lesson Structure

```
lesson-07-cicd/
├── README.md                                        # 👈 You are here
│
├── 01-basic-pipeline-setup.md                      # Setup & security guide (60 min)
├── section-02-basic-pipeline.md                    # Pipeline patterns & YAML (30 min)
├── 02-hands-on-lab-multi-env-cicd-pipeline.md     # Complete multi-env lab (2+ hours)
│
└── examples/
    ├── 01-basic-pipeline/                          # Tutorial 1: Working example
    │   ├── README.md                               # Step-by-step deployment
    │   ├── terraform/                              # Sample infrastructure
    │   │   ├── main.tf                            # VM configuration
    │   │   ├── variables.tf                       # Input variables
    │   │   └── outputs.tf                         # Resource outputs
    │   └── azure-pipelines.yml                     # Multi-stage pipeline
    │
    └── 02-multi-environment/                       # Tutorial 2: Alternative approach
        ├── README.md                               # Multi-project setup guide
        └── environments/                           # Environment configs
            ├── dev/
            ├── staging/
            └── prod/
```

---

## 💡 Key Concepts You'll Master

### Pipeline Automation
- YAML pipeline syntax and structure
- Multi-stage pipeline design (Validate → Plan → Deploy)
- Terraform task configuration
- Artifact management for plan files
- Stage dependencies and conditions

### Security Best Practices
- Service account with least privilege
- Secure credential storage in Azure DevOps
- Secret management in pipelines
- Never committing credentials to Git
- Audit logging and compliance

### Multi-Environment Strategy
- Environment isolation (dev/staging/prod)
- Environment-specific configurations
- Approval workflows for production
- Separate state management per environment
- Variable management across environments

### Production Readiness
- State locking mechanisms
- Plan review before apply
- Deployment validation and testing
- Rollback procedures
- Deployment history tracking

---

## 🎯 Learning Outcomes

After completing both tutorials, you will be able to:

✅ Set up end-to-end CI/CD for Terraform on Azure DevOps  
✅ Securely manage cloud credentials and secrets  
✅ Build multi-stage pipelines with proper separation  
✅ Automate infrastructure validation and deployment  
✅ Implement multi-environment workflows with isolation  
✅ Add manual approval gates for production deployments  
✅ Follow infrastructure automation best practices  
✅ Troubleshoot common pipeline issues effectively  
✅ Apply these patterns to AWS, Azure, or other clouds  

---

## 🔗 Navigation

### Start Here
- **[Setup & Configuration →](./01-basic-pipeline-setup.md)** - Begin with security setup
- **[Hands-On Multi-Env Lab →](./02-hands-on-lab-multi-env-cicd-pipeline.md)** - Jump to complete tutorial

### Examples
- **[Basic Pipeline Example →](./examples/01-basic-pipeline/README.md)** - Working multi-stage pipeline
- **[Multi-Environment Example →](./examples/02-multi-environment/README.md)** - Production patterns

### Reference
- **[Pipeline Patterns →](./section-02-basic-pipeline.md)** - YAML syntax and patterns
- **[← Back to Main Course](../README.md)** - Return to course overview

---

## 📝 Notes

### Important Points

- **Tutorial 1 recommended first** - Establishes foundation in setup and security
- **Tutorial 2 is self-contained** - Can be completed independently if you understand Azure DevOps basics
- **All code is tested and working** - Examples are ready to deploy
- **Time estimates are realistic** - Based on actual completion times
- **Patterns apply to any cloud** - Examples use GCP, but concepts work with AWS/Azure

### Tips for Success

- ⏰ **Budget enough time** - Don't rush through setup and security
- 📝 **Follow verification steps** - Confirm each section works before proceeding
- 🔒 **Never skip security** - Proper credential management is critical
- 🧪 **Test in dev first** - Always validate changes in non-production
- 💬 **Read troubleshooting** - Common issues have documented solutions

---

**Ready to automate your infrastructure? Start with [Setup & Configuration →](./01-basic-pipeline-setup.md)**

---

## 🗺️ Tutorial Flow

```
┌────────────────────────────────────────────────────────┐
│         Tutorial 1: Basic Pipeline (2 hours)           │
├────────────────────────────────────────────────────────┤
│                                                         │
│  Part 1: Setup (60 min)                                │
│  ┌──────────────────────────────────────────────────┐  │
│  │ • Create Azure DevOps organization               │  │
│  │ • Set up GCP service account                     │  │
│  │ • Configure state bucket                         │  │
│  │ • Upload secure credentials                      │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  Part 2: Pipeline (30 min)                             │
│  ┌──────────────────────────────────────────────────┐  │
│  │ • Understand YAML structure                      │  │
│  │ • Configure Terraform tasks                      │  │
│  │ • Set up variables                               │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  Part 3: Deploy (30 min)                               │
│  ┌──────────────────────────────────────────────────┐  │
│  │ • Push code to repo                              │  │
│  │ • Run pipeline                                   │  │
│  │ • Verify GCP resources                           │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ✅ You now have: Automated Terraform pipeline         │
└────────────────────────────────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────────┐
│    Tutorial 2: Multi-Environment Pipeline (2 hours)    │
├────────────────────────────────────────────────────────┤
│                                                         │
│  Part 1: Environment Setup (45 min)                    │
│  ┌──────────────────────────────────────────────────┐  │
│  │ • Create Azure environments                      │  │
│  │ • Configure approval gates                       │  │
│  │ • Set up variable groups                         │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  Part 2: Pipeline Config (45 min)                      │
│  ┌──────────────────────────────────────────────────┐  │
│  │ • Multi-stage YAML                               │  │
│  │ • Environment-specific variables                 │  │
│  │ • Branch-based triggers                          │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  Part 3: Deploy & Test (30 min)                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │ • Deploy to dev (automatic)                      │  │
│  │ • Deploy to staging (automatic)                  │  │
│  │ • Approve production deployment                  │  │
│  │ • Verify all environments                        │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ✅ You now have: Production-ready CI/CD workflow      │
└────────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start

### Prerequisites Checklist

Before starting, ensure you have:

- [ ] **Azure DevOps Account** - [Create free account](https://dev.azure.com)
- [ ] **GCP Project** with billing enabled - [Create project](https://console.cloud.google.com)
- [ ] **Terraform installed** - Version 1.6.0+ (`terraform version`)
- [ ] **gcloud CLI installed** - Latest version (`gcloud version`)
- [ ] **Basic Git knowledge** - Clone, commit, push

### Start Learning

1. **Begin with Tutorial 1** - [Setup & Configuration](./section-01-setup.md)
2. **Complete Tutorial 2** - [Multi-Environment Pipeline](./examples/03-multi-environment/README.md)

---

## 📂 Lesson Structure

```
lesson-07-cicd/
├── README.md                           # 👈 You are here
│
├── section-01-setup.md                 # Azure DevOps & GCP setup
├── section-02-basic-pipeline.md        # Pipeline fundamentals
│
└── examples/
    ├── 01-basic-pipeline/              # Tutorial 1: Basic pipeline
    │   ├── README.md                   # Step-by-step guide
    │   ├── terraform/                  # Sample Terraform code
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   └── azure-pipelines.yml         # Pipeline configuration
    │
    └── 03-multi-environment/           # Tutorial 2: Multi-env pipeline
        ├── README.md                   # Complete guide
        ├── terraform/                  # Infrastructure code
        │   ├── environments/
        │   │   ├── dev/
        │   │   ├── staging/
        │   │   └── prod/
        │   └── modules/
        └── azure-pipelines.yml         # Multi-stage pipeline
```

---

## 💡 Key Concepts You'll Master

### Pipeline Automation
- YAML pipeline syntax
- Terraform task configuration
- Stage and job organization
- Artifact management

### Security Best Practices
- Service account principle of least privilege
- Secure credential storage
- Secret management in pipelines
- Audit logging

### Multi-Environment Strategy
- Environment isolation
- Configuration management
- Approval workflows
- Branch-based deployment

### Production Readiness
- State locking
- Plan review process
- Deployment validation
- Rollback procedures

---

## 🎯 Learning Outcomes

After completing both tutorials, you will be able to:

✅ Set up end-to-end CI/CD for Terraform  
✅ Securely manage cloud credentials  
✅ Automate infrastructure validation and deployment  
✅ Implement multi-environment workflows  
✅ Add manual approval gates for production  
✅ Follow infrastructure automation best practices  
✅ Troubleshoot common pipeline issues  
✅ Apply these patterns to your own projects  

---

### Start Here

- **[Setup & Configuration →](./01-basic-pipeline-setup.md)** - Begin with security setup
- **[Hands-On Multi-Env Lab →](./02-hands-on-lab-multi-env-cicd-pipeline.md)** - Jump to complete tutorial

### Examples

- **[Basic Pipeline Example →](./examples/01-basic-pipeline/README.md)** - Working multi-stage pipeline
- **[Multi-Environment Example →](./examples/02-multi-environment/README.md)** - Production patterns

### Reference

- **[Pipeline Patterns →](./section-02-basic-pipeline.md)** - YAML syntax and patterns
- **[← Back to Main Course](../README.md)** - Return to course overview

---

## 📝 Notes

### Important Points

- **Tutorial 1 recommended first** - Establishes foundation in setup and security
- **Tutorial 2 is self-contained** - Can be completed independently if you understand Azure DevOps basics
- **All code is tested and working** - Examples are ready to deploy
- **Time estimates are realistic** - Based on actual completion times
- **Patterns apply to any cloud** - Examples use GCP, but concepts work with AWS/Azure

### Tips for Success

- ⏰ **Budget enough time** - Don't rush through setup and security
- 📝 **Follow verification steps** - Confirm each section works before proceeding
- 🔒 **Never skip security** - Proper credential management is critical
- 🧪 **Test in dev first** - Always validate changes in non-production
- 💬 **Read troubleshooting** - Common issues have documented solutions

---

**Ready to automate your infrastructure? Start with [Setup & Configuration →](./01-basic-pipeline-setup.md)**
