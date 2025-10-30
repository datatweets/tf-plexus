# Storage Module - Main Resources

# ══════════════════════════════════════════════════════════════════════════════
# TODO #19: Create Storage Buckets with Dynamic Lifecycle Rules
# ══════════════════════════════════════════════════════════════════════════════
# LEARNING OBJECTIVES:
# - Use for_each with complex map objects
# - Implement dynamic blocks for lifecycle rules
# - Generate unique names with random_id
# 
# STEPS:
# 1. Create random_id resource for unique suffix
# 2. Create google_storage_bucket with for_each
# 3. Use dynamic "lifecycle_rule" blocks
# ══════════════════════════════════════════════════════════════════════════════

resource "random_id" "bucket_suffix" {
  # YOUR CODE: byte_length = 4
}

resource "google_storage_bucket" "buckets" {
  # YOUR CODE HERE
  # Use for_each = var.buckets
  # name = "${each.key}-${var.environment}-${random_id.bucket_suffix.hex}"
  # location = each.value.location
  # storage_class = each.value.storage_class
  # force_destroy = var.force_destroy
  # 
  # versioning {
  #   enabled = each.value.versioning
  # }
  # 
  # uniform_bucket_level_access = true
  # public_access_prevention = "enforced"
  # 
  # dynamic "lifecycle_rule" {
  #   for_each = each.value.lifecycle_rules
  #   content {
  #     action {
  #       type = lifecycle_rule.value.action_type
  #     }
  #     condition {
  #       age                = lifecycle_rule.value.age
  #       num_newer_versions = lifecycle_rule.value.num_newer_versions
  #     }
  #   }
  # }
  # 
  # labels = {
  #   environment = var.environment
  #   managed_by  = "terraform"
  # }
}

# ══════════════════════════════════════════════════════════════════════════════
# CHECKPOINT: Storage Module Complete!
# ══════════════════════════════════════════════════════════════════════════════
