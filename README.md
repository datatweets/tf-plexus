# Terraform on Google Cloud Platform: Complete Learning Path

## Overview

A comprehensive, hands-on course for mastering Terraform infrastructure automation on Google Cloud Platform. This curriculum takes you from fundamental concepts through advanced testing and CI/CD implementation, with practical projects demonstrating real-world patterns.

**Level:** Beginner to Advanced  
**Platform:** Google Cloud Platform (GCP)  
**Tool:** Terraform 1.6.0+

---

## Course Objectives

| Category | Skills You'll Master |
|----------|---------------------|
| **Infrastructure Design** | IaC principles, cloud architecture patterns |
| **State Management** | Remote backends, locking, team collaboration |
| **Code Quality** | Reusable modules, DRY principles, testing |
| **Multi-Environment** | Dev/staging/prod separation, workspaces |
| **Automation** | CI/CD pipelines, automated deployments |
| **Security** | Credential management, best practices |
| **Real Projects** | Multi-tier web apps, Kubernetes clusters |

---

## Prerequisites

```
┌─────────────────────────────────────────────────────────────┐
│ Required Tools                                              │
├─────────────────────────────────────────────────────────────┤
│ ✓ Google Cloud Account (Free tier available)                │
│ ✓ Terraform 1.6.0+                                          │
│ ✓ gcloud CLI                                                │
│ ✓ Git                                                       │
│ ✓ Code Editor (VS Code recommended)                         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Required Knowledge                                          │
├─────────────────────────────────────────────────────────────┤
│ • Command-line interface (CLI) basics                       │
│ • Cloud computing concepts                                  │
│ • Version control (Git)                                     │
│ • Basic networking (IPs, subnets, firewalls)                │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Optional (for Advanced Topics)                              │
├─────────────────────────────────────────────────────────────┤
│ • Azure DevOps Account (for CI/CD)                          │
│ • Container/Kubernetes basics (for GKE project)             │
└─────────────────────────────────────────────────────────────┘
```

---

## Curriculum Structure

```
┌────────────────────────────────────────────────────────────────┐
│                    LEARNING PROGRESSION                        │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  Part 1: FOUNDATIONS                                           │
│  ├─ Lesson 0: Setup                                            │
│  ├─ Lesson 1: Terraform Basics        [Beginner]               │
│  └─ Lesson 2: State & Meta-Arguments  [Beginner]               │
│                                                                │
│  Part 2: ADVANCED FEATURES                                     │
│  ├─ Lesson 3: Variables & Functions   [Intermediate]           │
│  ├─ Lesson 4: Modules                 [Intermediate]           │
│  └─ Lesson 5: Multi-Environment       [Intermediate]           │
│                                                                │
│  Part 3: TESTING & AUTOMATION                                  │
│  ├─ Lesson 6: Testing                 [Intermediate]           │
│  └─ Lesson 7: CI/CD                   [Advanced]               │
│                                                                │
│  Part 4: CAPSTONE PROJECTS                                     │
│  ├─ Project 1: Multi-Tier Web App     [Advanced]               │
│  └─ Project 2: GKE Deployment         [Intermediate]           │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### Part 1: Foundations

#### Lesson 0: Environment Setup

Prepare your development environment with Terraform and GCP CLI.

**Key Files:**
- `guide_01.md` - Terraform installation
- `guide_02.md` - GCP authentication

---

#### Lesson 1: Introduction to Terraform
**Level:** Beginner

**Core Topics:** IaC principles • Terraform workflow • HCL syntax • Provider configuration • Resource management

**Learning Resources:**
- `section-01-introduction-iac-tf.md` - IaC fundamentals
- `section-02-introduction-iac-tf.md` - Terraform hands-on
- `gcp-auth-terraform.md` - Authentication patterns

**Examples:** `tf-hello-world/` • `complete-example/` • `cloudshell/`

---

#### Lesson 2: State Management and Meta-Arguments
**Level:** Beginner to Intermediate

**Core Topics:** State files • Remote backends • State locking • count/for_each • Lifecycle rules

**Learning Resources:**
- `section-01-state-mgm.md` - State management
- `section-02-meta-args.md` - Meta-arguments

**Examples:** `statefile/` • `backend/` • `count/` • `for_each/` • `lifecycle/` • `complete/`

---

### Part 2: Advanced Features

#### Lesson 3: Variables, Functions, and Expressions
**Level:** Intermediate

**Core Topics:** Type system • Dynamic blocks • Conditionals • Built-in functions • Data sources • Outputs

**Learning Resources:**
- `section-01-types-expressions.md` - Data types
- `section-02-functions-data.md` - Functions & data sources

**Examples:** `types/` • `dynamic-block/` • `conditional-expression/` • `data-source/` • `output/` • `complete/`

---

#### Lesson 4: Terraform Modules
**Level:** Intermediate

**Core Topics:** Module architecture • Local modules • Registry modules • Validation • Composition • DRY principles

**Learning Resources:**
- `section-01-module-basics.md` - Module fundamentals
- `section-02-advanced-modules.md` - Advanced patterns

**Examples:** `local-module/` • `flexible-module/` • `registry-module/` • `complete/`

---

#### Lesson 5: Multi-Environment Management
**Level:** Intermediate to Advanced

**Core Topics:** Workspaces • Directory structures • Remote state data sharing • Layered architecture

**Learning Resources:**
- `section-01-workspaces.md` - Workspace management
- `section-02-directory-structure.md` - Directory patterns

**Examples:** `workspaces/` • `directory-structure/` • `remote-state/` • `complete/`

---

### Part 3: Testing and Automation

#### Lesson 6: Infrastructure Testing
**Level:** Intermediate

**Core Topics:** Native testing framework • Test assertions • Module testing • TDD for infrastructure

**Learning Resources:**
- `section-01-basics.md` - Testing fundamentals
- `section-02-advanced.md` - Advanced patterns

**Examples:** `01-simple-test/` • `02-module-test/` • `03-integration-test/`

---

#### Lesson 7: CI/CD with Azure DevOps
**Level:** Intermediate to Advanced

**Core Topics:** Pipeline automation • Multi-stage deployments • Approval gates • Secure credential management

**Learning Resources:**
- `01-basic-pipeline-setup.md` - Security setup
- `section-02-basic-pipeline.md` - Pipeline patterns
- `02-hands-on-lab-multi-env-cicd-pipeline.md` - Complete lab

**Examples:** `01-basic-pipeline/` • `02-multi-environment/`

---

### Part 4: Capstone Projects

#### Project 1: Multi-Tier Web Application
**Level:** Intermediate to Advanced

Deploy production-ready infrastructure with load balancers, Cloud SQL, Cloud Storage, and secure networking.

**Architecture:**
```
┌─────────────────────────────────────────────────────┐
│                   Load Balancer                     │
└──────────────┬──────────────────┬───────────────────┘
               │                  │
        ┌──────▼──────┐    ┌──────▼──────┐
        │  Web Server │    │  Web Server │
        │   (VM 1)    │    │   (VM 2)    │
        └──────┬──────┘    └──────┬──────┘
               │                  │
               └────────┬─────────┘
                        │
                ┌───────▼────────┐
                │   Cloud SQL    │
                │  (PostgreSQL)  │
                └────────────────┘
                        │
                ┌───────▼────────┐
                │ Cloud Storage  │
                │  (User Files)  │
                └────────────────┘
```

**Documentation:** `README.md` • `INSTRUCTIONS.md` • `QUICKSTART.md` • `VALIDATION_CHECKLIST.md`

---

#### Project 2: Google Kubernetes Engine Deployment
**Level:** Intermediate

Deploy dev and production GKE clusters with custom networking and cost optimization.

**What You'll Build:**
- Development: Zonal cluster with spot instances
- Production: Regional cluster with HA
- Custom VPCs with secondary ranges
- Workspace-based environment separation

**Documentation:** `dev-prod-deployment-guide.md`

---

## Learning Paths

### Path 1: Beginner (Complete Curriculum)
```
Setup → Basics → State → Variables → Modules → Multi-Env → Web App Project
                                                              ↓
                                              Testing → CI/CD → GKE Project
```

### Path 2: Accelerated (Experienced Developers)
```
Review Lessons 1-2 → Variables → Modules → Multi-Env → Web App → Testing → CI/CD → GKE
```

### Path 3: CI/CD Focus (Adding to Existing Projects)
```
Review Modules & Multi-Env → Testing → CI/CD → Apply to Your Infrastructure
```

---

## Expected Outcomes

| Skill Category | What You'll Achieve |
|----------------|-------------------|
| **Infrastructure Design** | Architect cloud infrastructure using IaC principles |
| **Code Quality** | Write clean, reusable, well-documented Terraform |
| **State Management** | Implement remote state with locking |
| **Modularity** | Build and consume Terraform modules |
| **Testing** | Validate infrastructure before deployment |
| **Automation** | Deploy via CI/CD pipelines |
| **Security** | Manage credentials and apply best practices |
| **Practical Portfolio** | 25+ examples + 2 production projects |

### Career Readiness

Prepares you for roles in:
- DevOps Engineering
- Cloud Infrastructure Engineering
- Site Reliability Engineering (SRE)
- Platform Engineering
- Infrastructure Architecture

---

## Repository Structure

```
tf-plexus/
│
├── lesson-00-setup/              # Environment setup guides
│   ├── guide_01.md              # Terraform installation
│   └── guide_02.md              # GCP authentication
│
├── lesson-01-basics/             # Terraform fundamentals
│   ├── section-01-introduction-iac-tf.md
│   ├── section-02-introduction-iac-tf.md
│   ├── gcp-auth-terraform.md
│   ├── tf-hello-world/
│   ├── complete-example/
│   └── cloudshell/
│
├── lesson-02-state/              # State management
│   ├── section-01-state-mgm.md
│   ├── section-02-meta-args.md
│   ├── statefile/
│   ├── backend/
│   ├── count/
│   ├── for_each/
│   ├── lifecycle/
│   └── complete/
│
├── lesson-03-types/              # Variables and functions
│   ├── section-01-types-expressions.md
│   ├── section-02-functions-data.md
│   ├── types/
│   ├── dynamic-block/
│   ├── conditional-expression/
│   ├── data-source/
│   ├── output/
│   └── complete/
│
├── lesson-04-modules/            # Module development
│   ├── section-01-module-basics.md
│   ├── section-02-advanced-modules.md
│   ├── local-module/
│   ├── flexible-module/
│   ├── registry-module/
│   └── complete/
│
├── lesson-05-workspaces/         # Environment management
│   ├── section-01-workspaces.md
│   ├── section-02-directory-structure.md
│   ├── workspaces/
│   ├── directory-structure/
│   ├── remote-state/
│   └── complete/
│
├── lesson-06-testing/            # Infrastructure testing
│   ├── section-01-basics.md
│   ├── section-02-advanced.md
│   └── examples/
│       └── 01-simple-test/
│
├── lesson-07-cicd/               # CI/CD automation
│   ├── README.md
│   ├── 01-basic-pipeline-setup.md
│   ├── section-02-basic-pipeline.md
│   ├── 02-hands-on-lab-multi-env-cicd-pipeline.md
│   └── examples/
│       ├── 01-basic-pipeline/
│       └── 02-multi-environment/
│
├── project-01-webapp/            # Capstone: Web application
│   ├── README.md
│   ├── INSTRUCTIONS.md
│   ├── QUICKSTART.md
│   ├── VALIDATION_CHECKLIST.md
│   ├── student-version/
│   └── master-version/
│
└── project-02-gke/               # Capstone: Kubernetes
    └── dev-prod-deployment-guide.md
```

---

## Cost Considerations

| Component | Estimated Cost | Cost-Saving Tips |
|-----------|---------------|------------------|
| **Lessons 1-5** | $0-5/month | Use free tier; run `terraform destroy` daily |
| **Lesson 6** | $0 | Validation only, no resources |
| **Lesson 7** | <$2/month | State storage only |
| **Project 1 (Web App)** | Dev: $20/mo<br>Prod: $40/mo | Destroy when not in use |
| **Project 2 (GKE)** | Dev: $50/mo<br>Prod: $150/mo | Use spot instances; delete clusters |
| **Azure DevOps** | $0 | Free tier: 1,800 pipeline minutes/month |

---

## Getting Started

```bash
# 1. Install Tools (macOS examples - see lesson-00-setup for other OS)
brew install terraform google-cloud-sdk

# 2. Authenticate with GCP
gcloud auth login
gcloud auth application-default login

# 3. Create GCP Project
gcloud projects create YOUR_PROJECT_ID
gcloud config set project YOUR_PROJECT_ID

# 4. Enable billing at: https://console.cloud.google.com/billing

# 5. Clone repository
git clone <repository-url>
cd tf-plexus/lesson-01-basics

# 6. Start learning!
```

---

## Additional Resources

| Resource | Description |
|----------|-------------|
| [Terraform Docs](https://www.terraform.io/docs) | Official documentation |
| [GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs) | Google Cloud provider reference |
| [Terraform Registry](https://registry.terraform.io/) | Public module library |
| [Best Practices](https://www.terraform-best-practices.com/) | Community style guide |
| [HashiCorp Learn](https://learn.hashicorp.com/terraform) | Official tutorials |

---

## Support and Troubleshooting

Each lesson includes detailed README files with:
- Step-by-step instructions
- Common error solutions
- Validation checkpoints
- Debugging guidance

---

## Course Completion Checklist

**Foundations:**
- [ ] Lesson 0: Environment Setup
- [ ] Lesson 1: Terraform Basics
- [ ] Lesson 2: State Management

**Advanced:**
- [ ] Lesson 3: Variables & Functions
- [ ] Lesson 4: Modules
- [ ] Lesson 5: Multi-Environment

**Projects:**
- [ ] Project 1: Web Application
- [ ] Project 2: GKE Deployment (Optional)

**Advanced Topics (Optional):**
- [ ] Lesson 6: Testing
- [ ] Lesson 7: CI/CD

### Next Steps After Completion

**Continue Learning:** Multi-cloud (AWS/Azure) • Terraform Cloud • Policy as Code • GitOps

**Apply Skills:** Migrate existing infrastructure • Build personal projects • Contribute to open-source

---

**Ready to begin?** Start with [Lesson 0: Environment Setup](./lesson-00-setup/guide_01.md)
