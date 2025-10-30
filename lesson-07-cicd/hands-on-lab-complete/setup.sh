#!/bin/bash

# Multi-Environment Terraform Pipeline - Quick Setup Script
# This script helps you quickly configure the project for your GCP project

set -e  # Exit on error

echo "=========================================="
echo "Multi-Environment Terraform Setup"
echo "=========================================="
echo ""

# Check if PROJECT_ID is provided
if [ -z "$1" ]; then
  echo "Usage: ./setup.sh YOUR-GCP-PROJECT-ID"
  echo ""
  echo "Example: ./setup.sh my-terraform-project"
  exit 1
fi

PROJECT_ID=$1

echo "🔧 Configuring project for: ${PROJECT_ID}"
echo ""

# Step 1: Create service account
echo "📝 Step 1: Creating service account..."
echo "Run this command manually:"
echo ""
echo "gcloud iam service-accounts create terraform-pipeline \\"
echo "  --display-name='Terraform CI/CD Pipeline' \\"
echo "  --project=${PROJECT_ID}"
echo ""
echo "gcloud projects add-iam-policy-binding ${PROJECT_ID} \\"
echo "  --member='serviceAccount:terraform-pipeline@${PROJECT_ID}.iam.gserviceaccount.com' \\"
echo "  --role='roles/editor'"
echo ""
echo "gcloud iam service-accounts keys create ~/terraform-pipeline-key.json \\"
echo "  --iam-account=terraform-pipeline@${PROJECT_ID}.iam.gserviceaccount.com"
echo ""
read -p "Press Enter after completing Step 1..."

# Step 2: Create state buckets
echo ""
echo "📦 Step 2: Creating GCS state buckets..."
echo "Run this command manually:"
echo ""
echo "for ENV in dev staging prod; do"
echo "  gsutil mb -p ${PROJECT_ID} -l us-central1 gs://${PROJECT_ID}-\${ENV}-tfstate"
echo "  gsutil versioning set on gs://${PROJECT_ID}-\${ENV}-tfstate"
echo "  echo '✅ Created bucket: ${PROJECT_ID}-'\${ENV}'-tfstate'"
echo "done"
echo ""
read -p "Press Enter after completing Step 2..."

# Step 3: Update backend files
echo ""
echo "🔧 Step 3: Updating backend configuration files..."

cat > terraform/environments/dev/backend.tf << EOF
terraform {
  backend "gcs" {
    bucket = "${PROJECT_ID}-dev-tfstate"
    prefix = "terraform/state"
  }
}
EOF

cat > terraform/environments/staging/backend.tf << EOF
terraform {
  backend "gcs" {
    bucket = "${PROJECT_ID}-staging-tfstate"
    prefix = "terraform/state"
  }
}
EOF

cat > terraform/environments/prod/backend.tf << EOF
terraform {
  backend "gcs" {
    bucket = "${PROJECT_ID}-prod-tfstate"
    prefix = "terraform/state"
  }
}
EOF

echo "✅ Backend files updated"

# Step 4: Create terraform.tfvars files
echo ""
echo "📝 Step 4: Creating terraform.tfvars files..."

cat > terraform/environments/dev/terraform.tfvars << EOF
project_id     = "${PROJECT_ID}"
environment    = "dev"
region         = "us-central1"
subnet_cidr    = "10.0.1.0/24"
instance_count = 1
machine_type   = "e2-micro"
disk_size_gb   = 10
EOF

cat > terraform/environments/staging/terraform.tfvars << EOF
project_id     = "${PROJECT_ID}"
environment    = "staging"
region         = "us-central1"
subnet_cidr    = "10.1.1.0/24"
instance_count = 2
machine_type   = "e2-small"
disk_size_gb   = 20
EOF

cat > terraform/environments/prod/terraform.tfvars << EOF
project_id     = "${PROJECT_ID}"
environment    = "prod"
region         = "us-central1"
subnet_cidr    = "10.2.1.0/24"
instance_count = 3
machine_type   = "e2-medium"
disk_size_gb   = 50
EOF

echo "✅ terraform.tfvars files created"

# Step 5: Instructions for Azure DevOps
echo ""
echo "=========================================="
echo "✅ Local Setup Complete!"
echo "=========================================="
echo ""
echo "📋 Next Steps - Azure DevOps Setup:"
echo ""
echo "1. Upload Service Account Key:"
echo "   - Go to Pipelines → Library → Secure files"
echo "   - Upload ~/terraform-pipeline-key.json"
echo "   - Authorize for pipeline use"
echo ""
echo "2. Create Variable Group:"
echo "   - Go to Pipelines → Library → + Variable group"
echo "   - Name: terraform-variables"
echo "   - Add variables:"
echo "     * GCP_PROJECT_ID = ${PROJECT_ID}"
echo "     * GCP_REGION = us-central1"
echo "     * TF_VERSION = 1.9.0"
echo ""
echo "3. Create Environments:"
echo "   - Go to Pipelines → Environments"
echo "   - Create: terraform-dev (no approval)"
echo "   - Create: terraform-staging (no approval)"
echo "   - Create: terraform-prod (with approval)"
echo ""
echo "4. Configure Production Approval:"
echo "   - Click terraform-prod → ⋮ → Approvals and checks"
echo "   - Add → Approvals"
echo "   - Add yourself as approver"
echo ""
echo "5. Push to Azure DevOps:"
echo "   git init"
echo "   git remote add origin <YOUR-AZURE-DEVOPS-REPO-URL>"
echo "   git add ."
echo "   git commit -m 'Add multi-environment Terraform pipeline'"
echo "   git push -u origin main"
echo ""
echo "6. Create Pipeline:"
echo "   - Go to Pipelines → New pipeline"
echo "   - Select your repo"
echo "   - Choose 'Existing Azure Pipelines YAML file'"
echo "   - Select /azure-pipelines.yml"
echo "   - Run"
echo ""
echo "=========================================="
echo "📖 See README.md for detailed instructions"
echo "=========================================="
