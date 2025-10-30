# Hands-On Project #1: Multi-Tier Web Application Infrastructure

## 🏢 Company: Plexus

**Project Type:** Guided Hands-On Project  
**Difficulty:** Intermediate  
**Estimated Time:** 4-6 hours  
**Technologies:** Terraform, Google Cloud Platform (GCP)

---

## 📖 Scenario

You are a DevOps Engineer at **Plexus**, a fast-growing technology company that's launching a new web application platform. The company needs a robust, scalable infrastructure that can support both development and production environments.

Your mission is to design and deploy a complete multi-tier infrastructure on Google Cloud Platform that includes:

- **High-availability web servers** with load balancing
- **Managed PostgreSQL database** for application data
- **Cloud storage** for user uploads and backups
- **Secure networking** with proper firewall rules
- **Separate environments** for development and production

---

## 🎯 Learning Objectives

By completing this project, you will demonstrate mastery of:

### **Terraform Fundamentals**
- ✅ Resource creation and management
- ✅ Provider configuration
- ✅ Variable usage and tfvars files
- ✅ Output values for important information

### **State Management**
- ✅ Remote state with GCS backend
- ✅ State locking mechanisms
- ✅ Environment isolation

### **Meta-Arguments**
- ✅ `count` for multiple resources
- ✅ `for_each` for collections
- ✅ `depends_on` for explicit dependencies
- ✅ `lifecycle` for critical resource protection

### **Advanced Terraform**
- ✅ Data sources for existing resources
- ✅ Built-in functions (lookup, merge, format)
- ✅ Conditional expressions
- ✅ Dynamic blocks

### **Module Development**
- ✅ Creating reusable modules
- ✅ Module composition
- ✅ Input/output design
- ✅ Using public registry modules

### **Environment Management**
- ✅ Directory-based environment separation
- ✅ Environment-specific configurations
- ✅ Shared modules across environments

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        Internet                              │
└────────────────────┬────────────────────────────────────────┘
                     │
            ┌────────▼────────┐
            │  Load Balancer  │
            │   (HTTP/HTTPS)  │
            └────────┬────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
   ┌────▼───┐   ┌───▼────┐   ┌──▼─────┐
   │ Web    │   │ Web    │   │ Web    │
   │ Server │   │ Server │   │ Server │
   │   #1   │   │   #2   │   │   #3   │
   └────┬───┘   └───┬────┘   └──┬─────┘
        │           │           │
        └───────────┼───────────┘
                    │
         ┌──────────▼──────────┐
         │                     │
    ┌────▼────┐         ┌─────▼─────┐
    │ Cloud   │         │  Cloud    │
    │ SQL     │         │  Storage  │
    │ (PostgreSQL)      │  Buckets  │
    └─────────┘         └───────────┘
```

### **Components:**

1. **Network Layer**
   - VPC with custom subnets
   - Public subnet for web servers
   - Private subnet for database
   - Firewall rules for security

2. **Compute Layer**
   - Multiple web server instances
   - HTTP load balancer
   - Auto-configured with startup scripts

3. **Database Layer**
   - Cloud SQL PostgreSQL instance
   - Automated backups
   - High availability configuration

4. **Storage Layer**
   - Assets bucket for user uploads
   - Backups bucket with lifecycle policies

5. **Security**
   - Restricted firewall rules
   - IAM service accounts
   - Network isolation

---

## 📂 Project Structure

```
project-01-webapp/
├── README.md                          # This file
├── INSTRUCTIONS.md                    # Step-by-step guide
│
├── modules/                           # Reusable modules
│   ├── networking/                    # VPC, subnets, firewall
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── compute/                       # Web servers & load balancer
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── startup.sh
│   │
│   ├── database/                      # Cloud SQL
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── storage/                       # GCS buckets
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── environments/
│   ├── dev/                          # Development environment
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars.example
│   │   ├── backend.tf
│   │   └── outputs.tf
│   │
│   └── prod/                         # Production environment
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars.example
│       ├── backend.tf
│       └── outputs.tf
│
├── master-version/                    # Complete solution
│   └── [Full implementation]
│
└── student-version/                   # Learning version with TODOs
    └── [Skeleton code with hints]
```

---

## 🚀 Quick Start

### **For Students:**

1. Navigate to `student-version/`
2. Read `INSTRUCTIONS.md` carefully
3. Follow the 20 guided steps
4. Complete all TODO markers
5. Deploy and validate

### **For Instructors:**

1. Navigate to `master-version/`
2. Review complete implementation
3. Use for grading and reference
4. Optionally deploy to verify

---

## 📋 Prerequisites

### **Knowledge:**
- Completed Lessons 1-5 of the Terraform course
- Basic understanding of:
  - GCP services (Compute Engine, VPC, Cloud SQL, GCS)
  - Command line operations
  - Text editing

### **Tools Required:**
- Terraform >= 1.0
- Google Cloud SDK (gcloud)
- GCP project with billing enabled
- Text editor (VS Code recommended)
- Git (optional)

### **GCP APIs to Enable:**
```bash
gcloud services enable compute.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable storage-api.googleapis.com
```

---

## 💰 Cost Estimate

Running this project for **8 hours** (typical learning session):

| Resource | Quantity | Estimated Cost |
|----------|----------|----------------|
| Compute Engine (e2-micro) | 3 instances | ~$0.30 |
| Cloud SQL (db-f1-micro) | 1 instance | ~$0.15 |
| Load Balancer | 1 | ~$0.20 |
| Cloud Storage | 2 buckets | ~$0.01 |
| Network Egress | Minimal | ~$0.05 |
| **Total (8 hours)** | | **~$0.71** |

**Important:** Always run `terraform destroy` after completion to avoid ongoing charges!

---

## ✅ Success Criteria

Your project is complete when you can:

1. ✅ Successfully deploy both dev and prod environments
2. ✅ Access the load balancer and see web server responses
3. ✅ Verify 3 web servers are running in production
4. ✅ Connect to Cloud SQL database
5. ✅ Confirm GCS buckets are created with lifecycle policies
6. ✅ Run `terraform plan` and see no changes needed
7. ✅ Destroy all resources cleanly

---

## 📚 What You'll Learn

### **Module 1: Networking** (Steps 1-5)
- Creating VPCs and subnets
- Using `for_each` with maps
- Dynamic firewall rules
- Network dependencies

### **Module 2: Compute** (Steps 6-10)
- Using `count` for multiple instances
- Startup scripts and metadata
- Load balancer integration
- Public registry modules

### **Module 3: Database & Storage** (Steps 11-15)
- Cloud SQL configuration
- Lifecycle protection rules
- GCS bucket management
- Conditional resource creation

### **Module 4: Environments** (Steps 16-20)
- Directory-based environments
- Environment-specific variables
- Shared module usage
- Remote state management

---

## 🎓 Assessment

To receive credit for this project, submit:

1. **Code Repository** (or ZIP file)
   - All completed Terraform files
   - terraform.tfvars (sanitized - no secrets!)

2. **Documentation**
   - Architecture diagram (can use ASCII art)
   - Explanation of key design decisions

3. **Evidence of Deployment**
   - Screenshot of `terraform apply` success
   - Screenshot of GCP Console showing resources
   - Screenshot of load balancer URL in browser
   - Output of `terraform output` command

4. **Reflection** (1-2 paragraphs)
   - What was most challenging?
   - What would you improve?
   - How would you extend this for production?

---

## 🔧 Troubleshooting

### Common Issues:

**Issue:** "Error 403: Compute Engine API has not been used"
- **Solution:** Enable required APIs (see Prerequisites)

**Issue:** "Backend configuration changed"
- **Solution:** Run `terraform init -reconfigure`

**Issue:** "Error creating instance: quotas exceeded"
- **Solution:** Check GCP quotas or reduce instance count

**Issue:** Cloud SQL creation takes 10+ minutes
- **Solution:** This is normal! Cloud SQL takes time to provision

---

## 🌟 Bonus Challenges

After completing the core project, try these extensions:

1. **Monitoring & Alerting**
   - Add Cloud Monitoring dashboards
   - Set up uptime checks
   - Create alerting policies

2. **Auto-Scaling**
   - Convert to Managed Instance Groups
   - Configure auto-scaling policies
   - Add health checks

3. **Security Hardening**
   - Implement Cloud Armor
   - Add SSL certificates
   - Configure private Google access

4. **CI/CD Integration**
   - Create GitHub Actions workflow
   - Automated testing with Terratest
   - Plan/apply automation

5. **Cost Optimization**
   - Add committed use discounts
   - Implement resource scheduling
   - Use preemptible instances for dev

---

## 📞 Support

- **Course Materials:** Check lesson-01 through lesson-05
- **Terraform Docs:** https://registry.terraform.io/providers/hashicorp/google/latest/docs
- **GCP Docs:** https://cloud.google.com/docs

---

## 📝 License

This project is part of the Plexus Terraform Training Course.  
© 2025 Datatweets | Mehdi Lotfinejad. All rights reserved.

---

**Ready to build production-grade infrastructure? Let's get started! 🚀**

Navigate to `INSTRUCTIONS.md` for your step-by-step guide.
