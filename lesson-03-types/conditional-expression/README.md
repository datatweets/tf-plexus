# Conditional Expressions - Hands-On Example

Use Terraform's ternary operator for flexible infrastructure that adapts to different environments.

## What You'll Learn

- ✅ Ternary operator syntax: `condition ? true_value : false_value`
- ✅ Conditional resource creation with `count`
- ✅ Environment-specific configurations (dev vs prod)
- ✅ Conditional blocks with dynamic
- ✅ Complex conditional logic

## What Gets Created

**Development Environment (`environment = "dev"`):**
- 1 VM (e2-micro, 20GB standard disk)
- Ephemeral external IP
- 0 replicas
- HTTP allowed from anywhere

**Production Environment (`environment = "prod"`):**
- 1 VM (e2-standard-4, 100GB SSD disk)
- Static IP (optional)
- 2 replica instances
- HTTP allowed from specific IPs only
- Deletion protection enabled

## Quick Start

```bash
cd lesson-03/conditional-expression/
cp terraform.tfvars.example terraform.tfvars
# Edit project_id in terraform.tfvars
terraform init
terraform apply
```

## Test Different Scenarios

### Scenario 1: Development (Default)
```hcl
environment = "dev"
```
Result: Small instance, no replicas, ephemeral IP

### Scenario 2: Production
```hcl
environment = "prod"
```
Result: Large instance, 2 replicas, deletion protection

### Scenario 3: No External IP
```hcl
assign_external_ip = false
```
Result: Private instance only

### Scenario 4: Static IP
```hcl
assign_static_ip = true
assign_external_ip = true
```
Result: Instance with static IP address

## Key Concepts

### Ternary Operator
```hcl
machine_type = var.environment == "prod" ? "e2-standard-4" : "e2-micro"
```

### Conditional Creation
```hcl
count = var.assign_static_ip ? 1 : 0
```

### Nested Conditionals
```hcl
disk_type = var.environment == "prod" ? "pd-ssd" : "pd-standard"
```

## Cleanup

```bash
terraform destroy
```

## Next Steps

- ⏭️ [data-source/](../data-source/) - Query existing resources
- ⏭️ [output/](../output/) - Master output expressions
- ⏭️ [complete/](../complete/) - Production-ready example
