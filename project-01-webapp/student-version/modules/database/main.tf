# Database Module - Main Resources

# ══════════════════════════════════════════════════════════════════════════════
# TODO #16: Create Cloud SQL Instance with Conditional Configuration
# ══════════════════════════════════════════════════════════════════════════════
# LEARNING OBJECTIVES:
# - Configure Cloud SQL PostgreSQL
# - Use conditional expressions in settings
# - Implement lifecycle rules for data protection
# - Use dynamic blocks for authorized networks
# 
# KEY CONCEPTS:
# 1. Settings block with conditional backup configuration
# 2. Lifecycle: prevent_destroy for production safety
# 3. Dynamic blocks for authorized_networks
# 4. Timeouts for long-running operations
# ══════════════════════════════════════════════════════════════════════════════

resource "google_sql_database_instance" "main" {
  # YOUR CODE HERE
  # Implement Cloud SQL instance with:
  # - name, database_version, region, project
  # - deletion_protection = var.deletion_protection
  # 
  # settings block with:
  #   - tier = var.database_tier
  #   - disk_size = var.database_disk_size
  #   - availability_type = var.environment == "prod" ? "REGIONAL" : "ZONAL"
  #   
  #   backup_configuration (conditional):
  #     enabled = var.enable_backups
  #     start_time = var.backup_start_time
  #     point_in_time_recovery_enabled = var.enable_backups
  #   
  #   ip_configuration:
  #     ipv4_enabled = var.enable_public_ip
  #     
  #     dynamic "authorized_networks" {
  #       for_each = var.authorized_networks
  #       content {
  #         name  = authorized_networks.value.name
  #         value = authorized_networks.value.value
  #       }
  #     }
  # 
  # lifecycle:
  #   prevent_destroy = var.deletion_protection
  #   ignore_changes = [settings[0].disk_size]
  # 
  # timeouts:
  #   create = "30m"
  #   update = "30m"
  #   delete = "30m"
}

# TODO #17: Create Database
resource "google_sql_database" "database" {
  # YOUR CODE HERE
  # name, instance, project
}

# TODO #18: Create Database User
resource "google_sql_user" "user" {
  # YOUR CODE HERE
  # name, instance, password, project
}

# ══════════════════════════════════════════════════════════════════════════════
# CHECKPOINT: Database Module Complete!
# ══════════════════════════════════════════════════════════════════════════════
