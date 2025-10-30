# Test 1: Module works with only required variables
run "module_with_minimal_config" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "test-vm"
  }
  
  # Should use default values
  assert {
    condition     = google_compute_instance.vm.machine_type == "e2-micro"
    error_message = "Default machine type should be e2-micro"
  }
  
  assert {
    condition     = google_compute_instance.vm.zone == "us-central1-a"
    error_message = "Default zone should be us-central1-a"
  }
  
  assert {
    condition     = google_compute_instance.vm.boot_disk[0].initialize_params[0].size == 10
    error_message = "Default disk size should be 10 GB"
  }
  
  assert {
    condition     = google_compute_instance.vm.boot_disk[0].initialize_params[0].type == "pd-standard"
    error_message = "Default disk type should be pd-standard"
  }
}

# Test 2: Module accepts custom machine type
run "module_with_custom_machine_type" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "test-vm"
    machine_type  = "n2-standard-2"
  }
  
  assert {
    condition     = google_compute_instance.vm.machine_type == "n2-standard-2"
    error_message = "Should use provided machine type"
  }
}

# Test 3: Module accepts custom disk configuration
run "module_with_custom_disk" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "test-vm"
    disk_size_gb  = 50
    disk_type     = "pd-ssd"
  }
  
  assert {
    condition     = google_compute_instance.vm.boot_disk[0].initialize_params[0].size == 50
    error_message = "Should use provided disk size"
  }
  
  assert {
    condition     = google_compute_instance.vm.boot_disk[0].initialize_params[0].type == "pd-ssd"
    error_message = "Should use provided disk type"
  }
}

# Test 4: Module applies tags correctly
run "module_applies_tags" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "test-vm"
    tags          = ["web", "production", "http-server"]
  }
  
  assert {
    condition     = length(google_compute_instance.vm.tags) == 3
    error_message = "Should apply 3 tags"
  }
  
  assert {
    condition     = contains(google_compute_instance.vm.tags, "web")
    error_message = "Should include 'web' tag"
  }
  
  assert {
    condition     = contains(google_compute_instance.vm.tags, "production")
    error_message = "Should include 'production' tag"
  }
}

# Test 5: Module applies labels correctly including default labels
run "module_applies_labels" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "test-vm"
    labels = {
      environment = "dev"
      team        = "platform"
    }
  }
  
  # Check custom labels
  assert {
    condition     = google_compute_instance.vm.labels["environment"] == "dev"
    error_message = "Should apply custom environment label"
  }
  
  assert {
    condition     = google_compute_instance.vm.labels["team"] == "platform"
    error_message = "Should apply custom team label"
  }
  
  # Check default labels added by module
  assert {
    condition     = google_compute_instance.vm.labels["managed_by"] == "terraform"
    error_message = "Should add managed_by label"
  }
  
  assert {
    condition     = google_compute_instance.vm.labels["module"] == "compute"
    error_message = "Should add module label"
  }
}

# Test 6: External IP is conditional
run "module_without_external_ip" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name       = "test-vm"
    assign_external_ip  = false
  }
  
  assert {
    condition     = length(google_compute_instance.vm.network_interface[0].access_config) == 0
    error_message = "Should not have external IP when disabled"
  }
}

run "module_with_external_ip" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name      = "test-vm"
    assign_external_ip = true
  }
  
  assert {
    condition     = length(google_compute_instance.vm.network_interface[0].access_config) == 1
    error_message = "Should have external IP when enabled"
  }
}

# Test 7: Module exports all required outputs
run "module_exports_outputs" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "test-vm"
  }
  
  assert {
    condition     = output.instance_id != null
    error_message = "Module must export instance_id"
  }
  
  assert {
    condition     = output.instance_name == "test-vm"
    error_message = "Module must export instance_name"
  }
  
  assert {
    condition     = output.instance_self_link != null
    error_message = "Module must export instance_self_link"
  }
  
  assert {
    condition     = output.internal_ip != null
    error_message = "Module must export internal_ip"
  }
  
  assert {
    condition     = output.zone == "us-central1-a"
    error_message = "Module must export zone"
  }
  
  assert {
    condition     = output.machine_type == "e2-micro"
    error_message = "Module must export machine_type"
  }
}

# Test 8: Validation - Invalid instance name
run "invalid_instance_name_rejected" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "Test-VM-123"  # Capital letters not allowed
  }
  
  expect_failures = [
    var.instance_name
  ]
}

# Test 9: Validation - Disk size too small
run "disk_size_too_small_rejected" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "test-vm"
    disk_size_gb  = 5  # Below minimum
  }
  
  expect_failures = [
    var.disk_size_gb
  ]
}

# Test 10: Validation - Invalid disk type
run "invalid_disk_type_rejected" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "test-vm"
    disk_type     = "pd-extreme"  # Not in allowed list
  }
  
  expect_failures = [
    var.disk_type
  ]
}

# Test 11: Development environment configuration
run "dev_environment_config" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "dev-vm"
    machine_type  = "e2-micro"
    disk_size_gb  = 10
    disk_type     = "pd-standard"
    tags          = ["dev", "web"]
    labels = {
      environment = "dev"
    }
  }
  
  assert {
    condition     = google_compute_instance.vm.machine_type == "e2-micro"
    error_message = "Dev should use e2-micro"
  }
  
  assert {
    condition     = google_compute_instance.vm.boot_disk[0].initialize_params[0].type == "pd-standard"
    error_message = "Dev should use standard disk"
  }
}

# Test 12: Production environment configuration
run "prod_environment_config" {
  command = plan
  
  module {
    source = "./modules/compute"
  }
  
  variables {
    instance_name = "prod-vm"
    machine_type  = "n2-standard-4"
    disk_size_gb  = 100
    disk_type     = "pd-ssd"
    tags          = ["prod", "web", "https-server"]
    labels = {
      environment = "prod"
      criticality = "high"
    }
  }
  
  assert {
    condition     = google_compute_instance.vm.machine_type == "n2-standard-4"
    error_message = "Prod should use n2-standard-4"
  }
  
  assert {
    condition     = google_compute_instance.vm.boot_disk[0].initialize_params[0].size == 100
    error_message = "Prod should use 100 GB disk"
  }
  
  assert {
    condition     = google_compute_instance.vm.boot_disk[0].initialize_params[0].type == "pd-ssd"
    error_message = "Prod should use SSD disk"
  }
  
  assert {
    condition     = length(google_compute_instance.vm.tags) == 3
    error_message = "Prod should have 3 tags"
  }
}
