# Production Environment - Backend Configuration
# Purpose: Configure remote state storage in GCS

# Uncomment and configure after creating the state bucket
# terraform {
#   backend "gcs" {
#     bucket  = "plexus-terraform-state-prod"
#     prefix  = "environments/prod"
#   }
# }

# To set up remote state:
# 1. Create a GCS bucket for state storage:
#    gsutil mb gs://plexus-terraform-state-prod
#
# 2. Enable versioning:
#    gsutil versioning set on gs://plexus-terraform-state-prod
#
# 3. Uncomment the backend block above
#
# 4. Run: terraform init -migrate-state
#
# IMPORTANT: Never delete the state bucket for production!
