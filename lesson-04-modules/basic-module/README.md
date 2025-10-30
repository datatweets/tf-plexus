# Basic Module Example

This example demonstrates the fundamental concepts of Terraform modules as described in **Lesson 4, Section 1: Module Basics**.

## What This Example Demonstrates

This is a basic module tutorial that teaches:

1. **Module Structure**: Standard three-file layout (main.tf, variables.tf, outputs.tf)
2. **Conditional Resources**: Creating resources based on boolean variables
3. **Dynamic Blocks**: Using dynamic blocks for conditional configuration
4. **path.module**: Proper file referencing within modules
5. **Module Reusability**: Calling the same module multiple times with different configurations

## Project Structure

```
basic-module/
├── main.tf                 # Root module - calls server module 3 times
├── variables.tf            # Root module variables
├── outputs.tf              # Root module outputs
├── terraform.tfvars.example
└── modules/
    └── server/             # Reusable server module
        ├── main.tf         # Module resources
        ├── variables.tf    # Module inputs
        ├── outputs.tf      # Module outputs
        └── startup.sh      # Startup script
```

## Key Learning Points

### 1. Conditional Resource Creation

The module demonstrates conditional creation of a static IP:

```hcl
resource "google_compute_address" "static" {
  count = var.static_ip ? 1 : 0
  name  = "${var.name}-ipv4-address"
}
```

- When `static_ip = true`: Creates 1 static IP
- When `static_ip = false`: Creates 0 static IPs (resource not created)

### 2. Dynamic Blocks for Conditional Configuration

The access_config block is conditionally added:

```hcl
dynamic "access_config" {
  for_each = google_compute_address.static
  content {
    nat_ip = access_config.value["address"]
  }
}
```

**Result:**
- If static IP exists: Instance gets the static IP
- If static IP doesn't exist: Instance has NO external IP at all (not even ephemeral)

### 3. The path.module Variable

The startup script uses `path.module` for proper file referencing:

```hcl
metadata_startup_script = file("${path.module}/startup.sh")
```

**Why not use `./`?**
- `./` resolves to where `terraform apply` runs (root module)
- `${path.module}` resolves to where the module files are located
- **Always use `${path.module}` for files within modules!**

### 4. Module Reusability

The same module is called three times with different configurations:

```hcl
# Server 1: Uses default machine type + static IP
module "server1" {
  source    = "./modules/server"
  name      = "demo-server-1"
  static_ip = true
}

# Server 2: Same as server1 BUT no static IP
module "server2" {
  source    = "./modules/server"
  name      = "demo-server-2"
  static_ip = false
}

# Server 3: Larger machine type + static IP
module "server3" {
  source       = "./modules/server"
  name         = "demo-server-3"
  machine_type = "e2-small"
  static_ip    = true
}
```

## What Gets Created

When you run `terraform apply`, this creates:

1. **Server 1**:
   - e2-micro instance
   - Static external IP (34.x.x.x)
   - Nginx web server
   - Private IP (10.x.x.x)

2. **Server 2**:
   - e2-micro instance
   - NO external IP
   - Nginx web server
   - Private IP only (10.x.x.x)

3. **Server 3**:
   - e2-small instance (larger)
   - Static external IP (35.x.x.x)
   - Nginx web server
   - Private IP (10.x.x.x)

## Usage

### Step 1: Set Up Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and add your project_id
```

### Step 2: Initialize

```bash
terraform init
```

This downloads the Google Cloud provider and initializes the modules.

### Step 3: Plan

```bash
terraform plan
```

Review what will be created:
- 3 compute instances
- 2 static IP addresses (server1 and server3)
- Total of 5 resources

### Step 4: Apply

```bash
terraform apply
```

Type `yes` when prompted.

### Step 5: View Outputs

After successful apply:

```
Outputs:

server1_ip = "34.168.123.45"
server2_ip = null
server3_ip = "35.123.45.67"

all_server_ips = {
  "server1" = "34.168.123.45"
  "server2" = null
  "server3" = "35.123.45.67"
}
```

**Notice:**
- server1 and server3 have public IPs (static_ip = true)
- server2 has null (static_ip = false, no external IP)

### Step 6: Test Web Servers

```bash
# Test server1 (has external IP)
curl http://$(terraform output -raw server1_ip)

# Test server3 (has external IP)
curl http://$(terraform output -raw server3_ip)

# server2 cannot be accessed from internet (no external IP)
```

### Step 7: Clean Up

```bash
terraform destroy
```

## Module Outputs

The server module exposes these outputs:

- **public_ip_address**: External IP (null if no static IP)
- **private_ip_address**: Internal IP (always present)
- **self_link**: Full resource URI for references
- **instance_id**: Unique instance identifier

These can be referenced in the root module as:

```hcl
module.server1.public_ip_address
module.server1.private_ip_address
module.server1.self_link
module.server1.instance_id
```

## Module Variables

The server module accepts these inputs:

### Required Variables

- **name** (string): Server name - MUST be provided

### Optional Variables

- **machine_type** (string): Default = "e2-micro"
- **zone** (string): Default = "us-central1-a"
- **static_ip** (bool): Default = false

## Comparison with local-module Example

This `basic-module` example is **simpler and more educational** than the `local-module`:

| Feature | basic-module | local-module |
|---------|-------------|--------------|
| Purpose | Teaching fundamentals | Production-ready |
| Static IP | ✅ Demonstrates conditional creation | ❌ Not included |
| Startup Script | ✅ Shows path.module usage | ❌ Not included |
| Complexity | Low - easy to understand | Higher - more features |
| Variables | 4 simple variables | 15+ variables |
| Focus | Learning module concepts | Real-world usage |

## What You Learn

After completing this example, you understand:

✅ How to structure a Terraform module  
✅ How to define module variables (required vs optional)  
✅ How to create resources conditionally  
✅ How to use dynamic blocks  
✅ How to properly reference files with path.module  
✅ How to expose module outputs  
✅ How to call modules from root configuration  
✅ How to pass different values to the same module  

## Next Steps

After mastering this basic example:

1. **Explore local-module**: More complete, production-ready module
2. **Try flexible-module**: Advanced patterns with variable validation
3. **Use registry-module**: Consuming public modules
4. **Study complete**: Full multi-tier application with modules

## Common Issues

**Issue**: "Error: Invalid count argument"
```
count = var.static_ip ? 1 : 0
```
**Solution**: Ensure `static_ip` is boolean, not string

**Issue**: "startup.sh not found"
**Solution**: Use `${path.module}/startup.sh`, not `./startup.sh`

**Issue**: "Module not found"
**Solution**: Run `terraform init` after creating/modifying modules

**Issue**: server2 has no IP
**Solution**: This is expected! `static_ip = false` means NO external IP

## Additional Resources

- [Terraform Module Documentation](https://developer.hashicorp.com/terraform/language/modules)
- [Module Sources](https://developer.hashicorp.com/terraform/language/modules/sources)
- [path.module Reference](https://developer.hashicorp.com/terraform/language/expressions/references#filesystem-and-workspace-info)
- [Dynamic Blocks](https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks)
