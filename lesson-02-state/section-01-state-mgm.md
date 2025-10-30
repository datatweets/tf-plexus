# Lesson Two | SECTION 1: Understanding Terraform State and Team Collaboration
  
**Learning Objectives:**

- Understand what Terraform state is and why it's critical
- Learn how to inspect and interact with state
- Master destructive vs non-destructive changes
- Set up backend state for team collaboration
- Implement state locking to prevent conflicts

---

## Part 1: The Heart of Terraform - Understanding State

### What is State? The Foundation of Everything

Imagine you're managing a house. You need to know:

- What furniture do I currently have?
- What furniture do I want?
- What do I need to add, remove, or change?

**Terraform state is exactly that** - it's Terraform's memory of what infrastructure currently exists.

### The Desired State vs Current State Concept

**Let's understand this with a simple analogy:**

**Your Desired State (Your Wish List):**

```hcl
# main.tf - What you WANT
resource "google_compute_instance" "webserver" {
  name         = "my-web-server"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
}
```

This says: "I want a compute instance named 'my-web-server' with these specifications."

**Terraform's Job:**

1. Check what currently exists (Current State)
2. Compare it to what you want (Desired State)
3. Make changes to bridge the gap

### Let's See State in Action

**Initial Setup**

Let's start with a simple compute instance. Create a file called `main.tf`:

```hcl
# This is what we WANT to exist
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "YOUR-PROJECT-ID"  # Replace this!
  region  = "us-central1"
  zone    = "us-central1-a"
}

resource "google_compute_instance" "this" {
  name         = "state-file"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  
  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }
  
  metadata_startup_script = "echo 'Hello from Terraform!' > /tmp/hello.txt"
  
  tags = ["http-server"]
}
```

**Step 1: Initialize and Create Infrastructure**

```bash
$ terraform init
Initializing the backend...
Initializing provider plugins...
- Installing hashicorp/google v5.0.0...

Terraform has been successfully initialized!

$ terraform apply
# Review the plan, type 'yes'
...
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

**What Just Happened?**

1. **Before apply:**
   - Current State: Nothing exists
   - Desired State: One compute instance
   - Action: CREATE the instance

2. **After apply:**
   - Current State: One compute instance exists
   - Terraform saved this information in a file

### The State File - Terraform's Memory

After running `terraform apply`, look in your directory:

```bash
$ ls
main.tf
terraform.tfstate          # ← This is the state file!
terraform.tfstate.backup   # ← Previous version (backup)
.terraform/                # Provider plugins
.terraform.lock.hcl        # Lock file
```

**Let's Look at the State File:**

```bash
$ cat terraform.tfstate
```

You'll see something like this (simplified):

```json
{
  "version": 4,
  "terraform_version": "1.9.0",
  "serial": 1,
  "lineage": "abc-123-def-456",
  "outputs": {},
  "resources": [
    {
      "mode": "managed",
      "type": "google_compute_instance",
      "name": "this",
      "provider": "provider[\"registry.terraform.io/hashicorp/google\"]",
      "instances": [
        {
          "schema_version": 6,
          "attributes": {
            "id": "projects/my-project/zones/us-central1-a/instances/state-file",
            "name": "state-file",
            "machine_type": "e2-micro",
            "zone": "us-central1-a",
            "cpu_platform": "Intel Broadwell",
            "current_status": "RUNNING",
            "instance_id": "497903608900010349",
            "network_interface": [
              {
                "network_ip": "10.128.0.2",
                "access_config": [
                  {
                    "nat_ip": "34.123.45.67"
                  }
                ]
              }
            ]
            // ... over 100 more lines of attributes!
          }
        }
      ]
    }
  ]
}
```

**What's in the State File?**

- **Metadata:** Terraform version, state version
- **Resources:** Every resource Terraform manages
- **Attributes:** Complete details about each resource
  - IDs assigned by Google Cloud
  - IP addresses
  - Configuration details
  - Everything Google Cloud knows about the resource

**⚠️ CRITICAL UNDERSTANDING:**

The state file is:

- ✅ **The single source of truth** about what exists
- ✅ **Auto-generated** - Never edit it manually!
- ✅ **Contains sensitive data** - IPs, possibly passwords
- ✅ **Over 100 lines** for just ONE resource!
- ❌ **Not meant for human reading** - Use Terraform commands instead

### The Magic of Idempotency - Run Terraform Again

**Now, run terraform apply again** (without changing anything):

```bash
$ terraform apply

google_compute_instance.this: Refreshing state... [id=projects/...]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and
found no differences, so no changes are needed.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

**What Just Happened?**

1. **Terraform checked the state file** → "I created one instance last time"
2. **Terraform checked Google Cloud** → "That instance still exists"
3. **Terraform compared** → "Current State = Desired State"
4. **Result** → "No action needed!"

**This is idempotency in action!**

You can run Terraform 100 times, and it will only create the instance once. It's smart enough to know when things are already correct.

---

### Working with State - The Essential Commands

Since state files are huge and complex, Terraform provides commands to inspect them easily.

#### Command 1: `terraform state list` - What Resources Exist?

```bash
$ terraform state list
google_compute_instance.this
```

**What this shows:**

- A list of all resources Terraform is managing
- Format: `resource_type.resource_name`

**If you had more resources:**

```bash
$ terraform state list
google_compute_instance.this
google_storage_bucket.data
google_compute_network.main
google_compute_subnetwork.subnet1
google_compute_subnetwork.subnet2
```

#### Command 2: `terraform state show` - Detailed Resource Information

```bash
$ terraform state show google_compute_instance.this

# google_compute_instance.this:
resource "google_compute_instance" "this" {
    can_ip_forward          = false
    cpu_platform            = "Intel Broadwell"
    current_status          = "RUNNING"
    deletion_protection     = false
    enable_display          = false
    guest_accelerator       = []
    id                      = "projects/my-project/zones/us-central1-a/instances/state-file"
    instance_id             = "497903608900010349"
    label_fingerprint       = "42WmSpB8rSM="
    machine_type            = "e2-micro"
    metadata_fingerprint    = "nb0qL5x7PbM="
    name                    = "state-file"
    project                 = "my-project"
    self_link               = "https://www.googleapis.com/compute/v1/projects/..."
    zone                    = "us-central1-a"
    
    boot_disk {
        auto_delete = true
        device_name = "persistent-disk-0"
        mode        = "READ_WRITE"
        source      = "https://www.googleapis.com/compute/v1/projects/..."
        
        initialize_params {
            image  = "https://www.googleapis.com/compute/v1/projects/debian-cloud/..."
            labels = {}
            size   = 10
            type   = "pd-standard"
        }
    }
    
    network_interface {
        name               = "nic0"
        network            = "https://www.googleapis.com/compute/v1/projects/..."
        network_ip         = "10.128.0.2"
        queue_count        = 0
        stack_type         = "IPV4_ONLY"
        subnetwork         = "https://www.googleapis.com/compute/v1/projects/..."
        subnetwork_project = "my-project"
        
        access_config {
            nat_ip       = "34.123.45.67"
            network_tier = "PREMIUM"
        }
    }
    
    scheduling {
        automatic_restart   = true
        on_host_maintenance = "MIGRATE"
        preemptible         = false
        provisioning_model  = "STANDARD"
    }
}
```

**This is much more readable than the JSON state file!**

Shows:

- Every attribute of the resource
- Nested blocks clearly formatted
- Easy to understand structure

#### Command 3: `terraform console` - Interactive State Exploration

This is incredibly useful for exploring state interactively!

```bash
$ terraform console
> 
```

You now have an interactive console. Try these:

**Example 1: Get the instance name**

```
> google_compute_instance.this.name
"state-file"
```

**Example 2: Get the external IP**

```
> google_compute_instance.this.network_interface[0].access_config[0].nat_ip
"34.123.45.67"
```

**Example 3: Get machine type**

```
> google_compute_instance.this.machine_type
"e2-micro"
```

**Example 4: Explore nested structures**

```
> google_compute_instance.this.network_interface
[
  {
    "access_config" = [
      {
        "nat_ip" = "34.123.45.67"
        "network_tier" = "PREMIUM"
      },
    ]
    "network_ip" = "10.128.0.2"
    "name" = "nic0"
  },
]
```

**Why is this useful?**

When you want to reference an attribute in your Terraform code, use `terraform console` to find the exact syntax!

**Example Use Case:**

Let's say you want to output the IP address. You're not sure of the exact syntax. Use the console:

```
> google_compute_instance.this.network_interface
# See it's a list with [0]

> google_compute_instance.this.network_interface[0]
# See there's an access_config

> google_compute_instance.this.network_interface[0].access_config
# It's also a list!

> google_compute_instance.this.network_interface[0].access_config[0].nat_ip
"34.123.45.67"  # ← Perfect! This is the syntax!
```

Now you know how to add it to your outputs:

```hcl
output "instance_ip" {
  value = google_compute_instance.this.network_interface[0].access_config[0].nat_ip
}
```

**Exit the console:**

```
> exit
```

### Understanding Resource Addresses

**Resource Address Format:**

```
resource_type.resource_name[instance_index]
```

**Examples:**

```
google_compute_instance.this
└─────────┬────────┘    └┬─┘
     Resource Type      Name

google_compute_instance.webserver[0]
  └─────────┬────────┘  └───┬───┘└┬┘
      Resource Type        Name  Index (for count or for_each)

google_storage_bucket.data
└───────┬──────────┘  └─┬┘
   Resource Type       Name
```

**Why are resource addresses important?**

- Terraform uses them to uniquely identify resources
- You use them to reference resources
- State commands need them
- Dependencies are based on them

---

## Part 2: Destructive vs Non-Destructive Changes

This is **CRITICAL** to understand. Some changes can be made safely, others will destroy and recreate your resources!

### Non-Destructive Changes (Update In-Place)

These changes update the resource without replacing it.

**Example: Adding a Label**

**Step 1: Use the Google Cloud Console**

1. Go to Compute Engine → VM Instances
2. Click on your instance "state-file"
3. Click "Edit"
4. Scroll to "Labels"
5. Add label: `environment = sandbox`
6. Click "Save" (TWICE!)

**Step 2: Run terraform plan**

```bash
$ terraform plan

google_compute_instance.this: Refreshing state... [id=projects/...]

Terraform will perform the following actions:

  # google_compute_instance.this will be updated in-place
  ~ resource "google_compute_instance" "this" {
        id                      = "projects/.../zones/us-central1-a/instances/state-file"
      ~ labels                  = {
          - "environment" = "sandbox" -> null
        }
        name                    = "state-file"
        tags                    = [
            "http-server",
        ]
        # (17 unchanged attributes hidden)
        # (4 unchanged blocks hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

**Understanding the Plan:**

- **`~` symbol** = Update in-place (non-destructive)
- **`labels`** will be changed
- **`-` symbol** = Remove this value
- **`-> null`** = Change to nothing (remove the label)
- **`Plan: 0 to add, 1 to change, 0 to destroy`**
  - Not destroying anything
  - Just updating

**Step 3: Apply the change**

```bash
$ terraform apply
# Type 'yes'

google_compute_instance.this: Modifying... [id=projects/...]
google_compute_instance.this: Modifications complete after 5s

Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```

**What Happened:**

1. You added a label manually in the console
2. Terraform's desired state didn't include that label
3. Terraform removed the label to match desired state
4. **The instance stayed running the whole time** (non-destructive)
5. **The IP address didn't change**
6. **No downtime occurred**

**Key Point:** Labels can be changed without recreating the resource.

### Destructive Changes (Replace)

These changes require destroying and recreating the resource.

**Example: Removing the Startup Script**

**Step 1: Use the Google Cloud Console**

1. Go to Compute Engine → VM Instances
2. Click on your instance "state-file"
3. Click "Edit"
4. Scroll to "Automation" → "Startup script"
5. Delete the startup script content
6. Click "Save"
7. **Note the current external IP address!** (e.g., 34.123.45.67)

**Step 2: Run terraform plan**

```bash
$ terraform plan

google_compute_instance.this: Refreshing state... [id=projects/...]

Terraform will perform the following actions:

  # google_compute_instance.this must be replaced
-/+ resource "google_compute_instance" "this" {
      ~ cpu_platform            = "Intel Broadwell" -> (known after apply)
      ~ current_status          = "RUNNING" -> (known after apply)
      ~ guest_accelerator       = [] -> (known after apply)
      ~ id                      = "projects/.../state-file" -> (known after apply)
      ~ instance_id             = "497903608900010349" -> (known after apply)
      ~ label_fingerprint       = "42WmSpB8rSM=" -> (known after apply)
      ~ metadata_fingerprint    = "nb0qL5x7PbM=" -> (known after apply)
      ~ metadata_startup_script = "" -> "echo 'Hello from Terraform!' > /tmp/hello.txt" # forces replacement
        name                    = "state-file"
      ~ self_link               = "https://www.googleapis.com/compute/v1/..." -> (known after apply)
        tags                    = [
            "http-server",
        ]
        # (10 unchanged attributes hidden)

      ~ network_interface {
          ~ name               = "nic0" -> (known after apply)
          ~ network_ip         = "10.128.0.2" -> (known after apply)
          ~ queue_count        = 0 -> (known after apply)
          ~ stack_type         = "IPV4_ONLY" -> (known after apply)
          ~ subnetwork         = "https://www.googleapis.com/compute/v1/..." -> (known after apply)
          ~ subnetwork_project = "my-project" -> (known after apply)

          ~ access_config {
              ~ nat_ip       = "34.123.45.67" -> (known after apply)
              ~ network_tier = "PREMIUM" -> (known after apply)
            }
        }

        # (3 unchanged blocks hidden)
    }

Plan: 1 to add, 0 to change, 1 to destroy.
```

**Understanding the Plan:**

- **`-/+` symbol** = Destroy and then create (REPLACE)
- **`must be replaced`** = DESTRUCTIVE CHANGE
- **`# forces replacement`** = This specific change requires replacement
- **`(known after apply)`** = Value will be assigned during creation
- **`nat_ip = "34.123.45.67" -> (known after apply)`** = IP WILL CHANGE!
- **`Plan: 1 to add, 0 to change, 1 to destroy`**
  - Will destroy the old instance
  - Will create a new instance

**Step 3: Apply the change (carefully!)**

```bash
$ terraform apply
# Type 'yes'

google_compute_instance.this: Destroying... [id=projects/...]
google_compute_instance.this: Still destroying... [10s elapsed]
google_compute_instance.this: Destruction complete after 12s
google_compute_instance.this: Creating...
google_compute_instance.this: Still creating... [10s elapsed]
google_compute_instance.this: Creation complete after 15s [id=projects/...]

Apply complete! Resources: 1 added, 0 changed, 1 destroyed.
```

**What Happened:**

1. Terraform **destroyed** the old instance
2. Terraform **created** a new instance
3. **The IP address changed!** (old: 34.123.45.67, new: might be 35.123.45.68)
4. **Downtime occurred!** (while destroying and recreating)
5. **Any data on the instance was lost!**

**Check the new IP:**

```bash
$ terraform state show google_compute_instance.this | grep nat_ip
nat_ip = "35.123.45.68"  # Different IP!
```

### Which Changes are Destructive?

**Non-Destructive (Update In-Place):**

- Adding/removing labels
- Adding/removing tags
- Changing metadata (usually)
- Enabling/disabling deletion protection
- Some scheduling options

**Destructive (Force Replacement):**

- Changing instance name
- Changing machine type
- Changing boot disk
- Changing startup script (in some cases)
- Changing zone
- Many network configuration changes

**How to Know?**

- **Always run `terraform plan` first!**
- Look for:
  - **`~` = Safe** (update in-place)
  - **`-/+` = DANGER!** (destructive change)
  - **`# forces replacement`** = Destructive change

**Pro Tip:** The more you work with Terraform, the more you'll learn which changes are destructive. But ALWAYS check the plan!

---

## Part 3: Team Collaboration with Backend State 

### The Problem: Local State Doesn't Scale

**Scenario: Two Developers, One Nightmare**

**Developer Sarah:**

```bash
# On Sarah's laptop
$ terraform apply
# Creates infrastructure
# State saved in sarah_laptop/terraform.tfstate
```

**Developer Tom:**

```bash
# On Tom's laptop
$ terraform apply
# Creates the SAME infrastructure again!
# State saved in tom_laptop/terraform.tfstate
# Now we have DUPLICATE resources!
```

**The Problem:**

- Each person has their own state file
- Terraform doesn't know what the other person did
- Results in:
  - Duplicate resources
  - Conflicts
  - Confusion
  - Potential data loss
  - Complete chaos!

**Real-World Disaster Example:**

1. Sarah creates 10 servers (her state file knows about them)
2. Tom runs `terraform apply` (his state file is empty)
3. Tom's Terraform tries to create the same 10 servers again
4. Some succeed (now 20 servers!), some fail (naming conflicts)
5. Tom runs `terraform destroy` to clean up
6. Terraform deletes the 10 servers it knows about (in his state)
7. Sarah's 10 servers are now orphaned (not in any state file)
8. No one knows what's running!
9. Cloud bill doubles because of orphaned resources!

### The Solution: Remote Backend State

Store the state file in a central location where everyone can access it!

**The Setup:**

```
Before (Local State):
Sarah's Laptop → terraform.tfstate
Tom's Laptop   → terraform.tfstate (different!)

After (Remote State):
Sarah's Laptop ↘
                Google Cloud Storage Bucket → terraform.tfstate
Tom's Laptop   ↗

Both read and write to the SAME state file!
```

### Step-by-Step: Setting Up Remote Backend

**Step 1: Create a Cloud Storage Bucket**

This bucket will store your state file.

```bash
# Create a bucket (must be globally unique name!)
$ gsutil mb -p YOUR-PROJECT-ID -l us-central1 gs://YOUR-UNIQUE-BUCKET-NAME-terraform-state/

# Example:
$ gsutil mb -p my-project -l us-central1 gs://mycompany-terraform-state-prod/

Creating gs://mycompany-terraform-state-prod/...
```

**Best Practices for the State Bucket:**

```bash
# Enable versioning (keep history of state files)
$ gsutil versioning set on gs://mycompany-terraform-state-prod/

# Enable encryption (state files contain sensitive data!)
# Already enabled by default in Google Cloud Storage

# Restrict access (only Terraform admins should access)
# Set up IAM permissions appropriately
```

**Step 2: Configure Backend in Terraform**

Create or modify your Terraform configuration:

```hcl
# backend.tf

terraform {
  required_version = ">= 1.9"
  
  # Backend configuration - where to store state
  backend "gcs" {
    bucket = "mycompany-terraform-state-prod"
    prefix = "terraform/state"
  }
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "YOUR-PROJECT-ID"
  region  = "us-central1"
}
```

**Understanding the Backend Configuration:**

```hcl
backend "gcs" {
  bucket = "mycompany-terraform-state-prod"
  # Which bucket to use
  
  prefix = "terraform/state"
  # Path within the bucket
  # Actual file: gs://bucket-name/terraform/state/default.tfstate
}
```

**Step 3: Initialize with Backend**

```bash
$ terraform init

Initializing the backend...

Successfully configured the backend "gcs"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
...

Terraform has been successfully initialized!
```

**What Just Happened:**

1. Terraform detected the backend configuration
2. It set up a connection to Google Cloud Storage
3. Future state will be stored remotely

**If you had an existing local state:**

```bash
$ terraform init

Initializing the backend...
Acquiring state lock. This may take a few moments...

Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to
  the newly configured "gcs" backend. No existing state was found in the newly
  configured "gcs" backend. Do you want to copy this state to the new "gcs"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes

Successfully configured the backend "gcs"!
```

Terraform automatically migrates your local state to the remote backend!

**Step 4: Verify Remote State**

```bash
# Check the bucket
$ gsutil ls gs://mycompany-terraform-state-prod/terraform/state/

gs://mycompany-terraform-state-prod/terraform/state/default.tfstate

# Your state is now in the cloud!
```

**Step 5: Test Team Collaboration**

**Sarah's laptop:**

```bash
$ cd terraform-project
$ terraform init  # Connects to remote state
$ terraform apply
# Creates infrastructure
# State saved to Google Cloud Storage
```

**Tom's laptop:**

```bash
$ cd terraform-project
$ terraform init  # Connects to same remote state
$ terraform plan
# Sees infrastructure Sarah created!
# No duplicate resources!
```

### State Locking - Preventing Conflicts

**The Problem: Simultaneous Changes**

```
10:00 AM - Sarah runs terraform apply (takes 5 minutes)
10:01 AM - Tom runs terraform apply (takes 5 minutes)

Both are modifying infrastructure at the same time!
State file gets corrupted!
```

**The Solution: State Locking**

Good news! Google Cloud Storage backend includes automatic state locking!

**How It Works:**

1. **Sarah starts `terraform apply`**
   - Terraform creates a lock on the state file
   - Lock file: `default.tflock`

2. **Tom tries to run `terraform apply`**
   - Terraform tries to create a lock
   - Fails because Sarah has the lock
   - Shows error message:

```bash
$ terraform apply

Error: Error acquiring the state lock

Error message: resource temporarily unavailable
Lock Info:
  ID:        1a2b3c4d-5e6f-7g8h-9i0j-1k2l3m4n5o6p
  Path:      mycompany-terraform-state-prod/terraform/state/default.tflock
  Operation: OperationTypeApply
  Who:       sarah@company.com
  Version:   1.9.0
  Created:   2025-10-26 10:00:15.123456789 +0000 UTC
  Info:      

Terraform acquires a state lock to protect the state from being written
by multiple users at the same time. Please resolve the issue above and try
again. For most commands, you can disable locking with the "-lock=false"
flag, but this is not recommended.
```

3. **Tom waits** for Sarah to finish

4. **Sarah's apply completes**
   - Lock is released
   - State file is updated

5. **Tom tries again**
   - Gets the lock
   - Sees Sarah's changes
   - Applies his changes

**State Locking Prevents:**

- Simultaneous modifications
- State file corruption
- Race conditions
- Lost changes
- Infrastructure conflicts

**Force Unlock (Emergency Only!):**

If someone's process crashes and leaves a lock:

```bash
# Get the Lock ID from the error message
$ terraform force-unlock 1a2b3c4d-5e6f-7g8h-9i0j-1k2l3m4n5o6p

Do you really want to force-unlock?
  Terraform will remove the lock on the remote state.
  This will allow other Terraform processes to acquire the lock.
  Locking is important to prevent state corruption.

  Only 'yes' will be accepted to confirm.

  Enter a value: yes

Terraform state has been successfully unlocked!
```

**⚠️ WARNING:** Only force-unlock if you're absolutely sure no one else is running Terraform!

### Backend State Best Practices

#### 1. Always Use Remote Backend (Even Solo Projects!)

**Why?**

- State file never gets lost
- Easy to share when the team grows
- Versioning provides history
- Automatic backups

#### 2. Enable Versioning on State Bucket

```bash
$ gsutil versioning set on gs://mycompany-terraform-state-prod/

# If you accidentally break state, recover old version:
$ gsutil ls -a gs://mycompany-terraform-state-prod/terraform/state/default.tfstate

gs://mycompany-terraform-state-prod/terraform/state/default.tfstate#1698765432123456
gs://mycompany-terraform-state-prod/terraform/state/default.tfstate#1698765431987654

# Restore older version:
$ gsutil cp gs://mycompany-terraform-state-prod/terraform/state/default.tfstate#1698765431987654 \
             gs://mycompany-terraform-state-prod/terraform/state/default.tfstate
```

#### 3. Restrict Access to State Bucket

State files contain:

- IP addresses
- Resource IDs
- Potentially passwords or keys
- Complete infrastructure details

**Set up IAM:**

```bash
# Only Terraform admins should have access
# Roles needed:
# - roles/storage.objectViewer (read state)
# - roles/storage.objectCreator (write state)
# - roles/storage.legacyBucketReader (list objects)
```

#### 4. Use Separate Backends for Environments

```
Development Environment:
- Bucket: mycompany-terraform-state-dev
- State: terraform/dev/default.tfstate

Staging Environment:
- Bucket: mycompany-terraform-state-staging
- State: terraform/staging/default.tfstate

Production Environment:
- Bucket: mycompany-terraform-state-prod
- State: terraform/prod/default.tfstate
```

This prevents accidentally modifying production when working on dev!

#### 5. Never Commit State Files to Git

**.gitignore:**

```bash
# Never commit these!
*.tfstate
*.tfstate.backup
*.tfstate.lock.info
.terraform/
```

State files contain sensitive information and can be large. Always use remote backend instead.

---

## Summary: Section 1 Key Takeaways

### What is Terraform State?

✅ **State is Terraform's memory** of what infrastructure exists  
✅ **Stored in JSON format** by default in `terraform.tfstate`  
✅ **Contains complete details** of every resource  
✅ **Enables idempotency** - run Terraform multiple times safely  
✅ **Never edit manually** - use Terraform commands

### Essential State Commands

✅ **`terraform state list`** - List all resources  
✅ **`terraform state show`** - Show resource details  
✅ **`terraform console`** - Interactive exploration  
✅ **`terraform show`** - Display entire state

### Destructive vs Non-Destructive Changes

✅ **Non-Destructive (`~`)** - Updates in-place, no downtime  
✅ **Destructive (`-/+`)** - Destroys and recreates resource  
✅ **Always check the plan** before applying!  
✅ **Look for "forces replacement"** indicator

### Backend State for Team Collaboration

✅ **Remote backend solves team conflicts**  
✅ **Store state in Google Cloud Storage**  
✅ **Automatic state locking prevents corruption**  
✅ **Enable versioning for state history**  
✅ **Restrict access for security**

### Critical Best Practices

✅ Use remote backend even for solo projects  
✅ Never commit state files to Git  
✅ Always run `terraform plan` before `apply`  
✅ Enable versioning on state bucket  
✅ Restrict access to state files  

###### ✅ Use separate backends for different environments