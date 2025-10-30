# Lesson 3: Writing Efficient Terraform Code

Master advanced Terraform patterns for production-ready infrastructure as code.

## 📖 Overview

In Lesson 3, you'll learn essential patterns for writing **efficient, maintainable, and scalable** Terraform code. These concepts are critical for real-world infrastructure projects.

**Prerequisites:** Complete [Lesson 1](../lesson-01/) and [Lesson 2](../lesson-02/) first.

## 🎯 Learning Objectives

By the end of this lesson, you will:

✅ Master all Terraform **data types** (primitives and complex)  
✅ Use **dynamic blocks** to eliminate code repetition  
✅ Implement **conditional expressions** for environment-based logic  
✅ Query existing infrastructure with **data sources**  
✅ Master **Terraform functions** (string, list, map, numeric)  
✅ Create comprehensive **outputs** with splat and for expressions  
✅ Build **production-ready** multi-tier infrastructure  

## 📚 Course Structure

### Part 1: Tutorials (1 hour)

Read these first to understand the concepts:

1. **[Section 1: Types & Expressions](./section-01-types-expressions.md)** (30 min)
   - Primitive types: string, number, bool
   - Collection types: list, map
   - Structural types: object, tuple
   - Dynamic blocks for iteration
   - Conditional expressions (ternary operator)

2. **[Section 2: Functions & Data Sources](./section-02-functions-data.md)** (30 min)
   - String functions: format, join, split, replace
   - Collection functions: length, element, concat, merge
   - Numeric functions: min, max, ceil, floor
   - Data sources for querying existing resources
   - Output values and expressions
   - Development workflow: fmt, validate, console

### Part 2: Hands-On Examples (3-4 hours)

Work through these examples in order:

| Example | Concepts | Time | Difficulty |
|---------|----------|------|------------|
| **[types/](./types/)** | All Terraform types, validation | 30 min | ⭐⭐ |
| **[dynamic-block/](./dynamic-block/)** | Dynamic disk attachments, nested blocks | 30 min | ⭐⭐ |
| **[conditional-expression/](./conditional-expression/)** | Environment-based conditionals | 30 min | ⭐⭐ |
| **[data-source/](./data-source/)** | Zone discovery, image lookup | 30 min | ⭐⭐ |
| **[output/](./output/)** | Splat, for_each, complex outputs | 45 min | ⭐⭐⭐ |
| **[complete/](./complete/)** | Production multi-tier infrastructure | 60 min | ⭐⭐⭐⭐ |

## 🚀 Quick Start

```bash
# Navigate to Lesson 3
cd lesson-03/

# Start with tutorials
open section-01-types-expressions.md
open section-02-functions-data.md

# Then work through examples
cd types/
cp terraform.tfvars.example terraform.tfvars
# Edit project_id in terraform.tfvars
terraform init
terraform apply
```

## 📊 Example Descriptions

### 1. Types Example
**Focus:** Understanding all Terraform data types

- Demonstrates: string, number, bool, list, map, object
- Creates: 1 VM with comprehensive type examples
- Key concept: Type validation and constraints

### 2. Dynamic Block Example
**Focus:** Eliminating code repetition with dynamic blocks

- Demonstrates: Dynamic disk attachments
- Creates: 1 VM with 3 dynamically attached disks
- Key concept: Iteration within resource blocks

### 3. Conditional Expression Example
**Focus:** Environment-based configuration

- Demonstrates: Ternary operator, conditional count
- Creates: Dev (1 small VM) or Prod (2 large VMs)
- Key concept: Single code for multiple environments

### 4. Data Source Example
**Focus:** Querying existing infrastructure

- Demonstrates: Zone discovery, image lookup, project metadata
- Creates: 3 VMs distributed across discovered zones
- Key concept: Dynamic infrastructure discovery

### 5. Output Example
**Focus:** Mastering output expressions

- Demonstrates: Splat `[*]`, for_each, conditional outputs
- Creates: 5 servers (3 web + 2 DB) with comprehensive outputs
- Key concept: All output patterns in one example

### 6. Complete Example (Capstone)
**Focus:** Production-ready multi-tier infrastructure

- Demonstrates: **ALL Lesson 3 concepts combined**
- Creates: Full stack (web + app + DB + LB + monitoring)
- Key concept: Enterprise-grade Terraform patterns

**Architecture:**
```
Load Balancer → Web Tier (3 servers) → App Tier (2 servers) → DB Tier (primary + replica)
```

## 🔑 Key Concepts

### Types
```hcl
# Primitive
variable "name" { type = string }
variable "count" { type = number }
variable "enabled" { type = bool }

# Collection
variable "zones" { type = list(string) }
variable "tags" { type = map(string) }

# Structural
variable "config" {
  type = object({
    name = string
    size = number
  })
}
```

### Dynamic Blocks
```hcl
dynamic "attached_disk" {
  for_each = var.disks
  content {
    source = attached_disk.value.source
  }
}
```

### Conditionals
```hcl
count        = var.environment == "prod" ? 3 : 1
machine_type = var.environment == "prod" ? "e2-medium" : "e2-micro"
```

### Data Sources
```hcl
data "google_compute_zones" "available" {
  region = var.region
}

zone = element(data.google_compute_zones.available.names, 0)
```

### Outputs
```hcl
# Splat expression
output "ips" {
  value = google_compute_instance.servers[*].network_interface[0].network_ip
}

# For expression
output "server_map" {
  value = {
    for key, instance in google_compute_instance.servers :
    key => instance.network_interface[0].network_ip
  }
}
```

## 📈 Learning Path

### Beginner Track
1. Read Section 1 tutorial
2. Complete `types/` example
3. Read Section 2 tutorial
4. Complete `data-source/` example

### Intermediate Track
1. Complete all tutorials
2. Work through all examples in order
3. Modify examples with different values
4. Experiment with terraform console

### Advanced Track
1. Complete everything above
2. Study `complete/` example thoroughly
3. Build your own multi-tier infrastructure
4. Combine with Lesson 2 concepts (count, for_each, lifecycle)

## 💡 Pro Tips

### Testing with Terraform Console
```bash
terraform console

> var.environment
"production"

> var.environment == "production" ? 3 : 1
3

> element(["a", "b", "c"], 1)
"b"
```

### Useful Development Commands
```bash
# Format all files
terraform fmt -recursive

# Validate configuration
terraform validate

# See execution plan
terraform plan -out=plan.tfplan

# Apply specific plan
terraform apply plan.tfplan

# View specific output
terraform output web_servers

# View all outputs as JSON
terraform output -json > outputs.json
```

### Common Patterns

**Count vs For_each:**
- Use `count` for identical resources (e.g., 3 web servers)
- Use `for_each` for distinct resources (e.g., dev, staging, prod)

**When to Use Dynamic Blocks:**
- Multiple similar nested blocks
- Conditional nested blocks
- Avoid for simple single blocks

**Data Sources vs Variables:**
- Variables: User-provided configuration
- Data sources: Query existing infrastructure

## 🧪 Experiments

Try these modifications to deepen understanding:

1. **types/**: Add new object types with validation
2. **dynamic-block/**: Add dynamic network interfaces
3. **conditional-expression/**: Add staging environment
4. **data-source/**: Change region, see different zones
5. **output/**: Add custom output formatting
6. **complete/**: Scale to 5 web servers, 3 DB replicas

## 🎓 Quiz Yourself

After completing this lesson, you should be able to answer:

- When should you use `list(string)` vs `map(string)`?
- How do dynamic blocks reduce code duplication?
- What's the syntax for ternary conditional expressions?
- How do you query existing GCP zones?
- What's the difference between `[*]` and `values()[*]`?
- When should you use count vs for_each?

## 🐛 Troubleshooting

### Common Issues

**"Invalid count value"**
- Ensure count is a number, not a string
- Check conditional returns number: `var.env == "prod" ? 3 : 1`

**"Unknown data source"**
- Run `terraform init` to download providers
- Verify provider version supports the data source

**"No declaration found for var.X"**
- Define variable in `variables.tf`
- Ensure variable name matches exactly

**"Invalid splat expression"**
- Use `[*]` for count-based resources
- Use `values()[*]` for for_each resources

## 📁 Files in This Lesson

```
lesson-03/
├── README.md                          ← You are here
├── section-01-types-expressions.md    ← Tutorial 1
├── section-02-functions-data.md       ← Tutorial 2
├── types/                             ← Example 1
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
├── dynamic-block/                     ← Example 2
├── conditional-expression/            ← Example 3
├── data-source/                       ← Example 4
├── output/                            ← Example 5
└── complete/                          ← Example 6 (Capstone)
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── scripts/
    │   ├── web-startup.sh
    │   └── lb-startup.sh
    └── README.md
```

## 🎯 Next Steps

After completing Lesson 3:

- ✅ **Completed:** Writing efficient Terraform code
- ⏭️ **Next:** [Lesson 4](../lesson-04/) - Modules and Reusable Code
- 🔄 **Review:** [Lesson 2](../lesson-02/) - State Management

## 📚 Additional Resources

- [Terraform Language Documentation](https://www.terraform.io/language)
- [Terraform Functions Reference](https://www.terraform.io/language/functions)
- [GCP Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Type Constraints](https://www.terraform.io/language/expressions/type-constraints)

## ⏱️ Time Estimates

- **Tutorials only:** 1 hour
- **All examples:** 4 hours
- **Complete mastery:** 8-10 hours (with experimentation)

---

**Ready to start?** → Begin with [Section 1: Types & Expressions](./section-01-types-expressions.md)

---

**Questions or stuck?** Review the tutorials, check example READMEs, or experiment with `terraform console`.

**🎉 Good luck with Lesson 3!**
