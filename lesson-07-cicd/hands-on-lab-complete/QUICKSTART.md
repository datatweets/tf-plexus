# Quick Start Guide

This is a condensed guide to get the pipeline running as quickly as possible. For detailed explanations, see [README.md](README.md).

## Prerequisites

- GCP project with billing enabled
- Azure DevOps organization with project
- `gcloud` CLI installed
- Git installed

## 5-Minute Setup

### 1. Run Setup Script

```bash
cd lesson-07-cicd/hands-on-lab-complete
./setup.sh YOUR-GCP-PROJECT-ID
```

Follow the prompts to create service account and buckets.

### 2. Azure DevOps - Quick Setup

**Upload Key:**
- Pipelines → Library → Secure files → Upload `terraform-pipeline-key.json`

**Create Variables:**
- Pipelines → Library → + Variable group → Name: `terraform-variables`
- Add: `GCP_PROJECT_ID`, `GCP_REGION` (us-central1), `TF_VERSION` (1.9.0)

**Create Environments:**
- Pipelines → Environments → Create 3 environments:
  - `terraform-dev`
  - `terraform-staging`
  - `terraform-prod` (add approval check)

### 3. Push Code

```bash
git init
git remote add origin <YOUR-AZURE-DEVOPS-REPO-URL>
git add .
git commit -m "Add multi-environment Terraform pipeline"
git push -u origin main
```

### 4. Create Pipeline

- Pipelines → New pipeline → Choose repo → Existing YAML → `/azure-pipelines.yml` → Run

## What Happens

1. **Validate** (2 min): Validates all environments
2. **Dev** (3 min): Auto-deploys 1 VM (e2-micro)
3. **Staging** (4 min): Auto-deploys 2 VMs (e2-small)
4. **Production** (5 min): **WAITS FOR YOUR APPROVAL** → Deploys 3 VMs (e2-medium)

## Verify Resources

```bash
# Quick check all environments
export PROJECT_ID="YOUR-PROJECT-ID"

gcloud compute instances list --project=${PROJECT_ID} \
  --filter="labels.managed_by=terraform" \
  --format="table(name,zone,machineType,status)"
```

Expected output:
```
NAME           ZONE           MACHINE_TYPE  STATUS
dev-vm-1       us-central1-a  e2-micro      RUNNING
staging-vm-1   us-central1-a  e2-small      RUNNING
staging-vm-2   us-central1-a  e2-small      RUNNING
prod-vm-1      us-central1-a  e2-medium     RUNNING
prod-vm-2      us-central1-a  e2-medium     RUNNING
prod-vm-3      us-central1-a  e2-medium     RUNNING
```

## Cleanup

```bash
# Quick destroy all
cd terraform/environments
export GOOGLE_APPLICATION_CREDENTIALS=~/terraform-pipeline-key.json

for ENV in prod staging dev; do
  cd $ENV
  terraform init
  terraform destroy -auto-approve
  cd ..
done

# Delete buckets
gsutil -m rm -r gs://${PROJECT_ID}-{dev,staging,prod}-tfstate
```

## Troubleshooting

| Problem | Quick Fix |
|---------|-----------|
| Permission denied | Check service account has Editor role |
| Bucket not found | Run `gsutil ls` to verify buckets exist |
| No approval | Check terraform-prod has Approval check configured |
| Secure file error | Verify file name is exactly `terraform-pipeline-key.json` |

## Next Steps

- See [README.md](README.md) for detailed documentation
- Use [TESTING-CHECKLIST.md](TESTING-CHECKLIST.md) for complete testing
- Test changes by modifying `terraform.tfvars` and pushing

---

**Estimated Total Time**: ~25 minutes (5 min setup + 20 min pipeline execution)
