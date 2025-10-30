# Test 1: Verify default machine type
run "verify_machine_type" {
  command = plan

  variables {
    project_id = "test-project-123"
  }

  assert {
    condition     = google_compute_instance.test_vm.machine_type == "e2-micro"
    error_message = "Expected machine type e2-micro, got ${google_compute_instance.test_vm.machine_type}"
  }
}

# Test 2: Verify zone placement
run "verify_zone" {
  command = plan

  variables {
    project_id = "test-project-123"
  }

  assert {
    condition     = google_compute_instance.test_vm.zone == "us-central1-a"
    error_message = "VM must be in us-central1-a zone (default zone)"
  }
}

# Test 3: Verify network tags
run "verify_tags" {
  command = plan

  variables {
    project_id = "test-project-123"
  }

  assert {
    condition     = contains(google_compute_instance.test_vm.tags, "web")
    error_message = "VM must have 'web' tag for firewall rules"
  }

  assert {
    condition     = contains(google_compute_instance.test_vm.tags, "ssh")
    error_message = "VM must have 'ssh' tag for SSH access"
  }

  assert {
    condition     = length(google_compute_instance.test_vm.tags) >= 2
    error_message = "VM must have at least 2 tags"
  }
}

# Test 4: Verify outputs are not empty
run "verify_outputs" {
  command = plan

  variables {
    project_id = "test-project-123"
  }

  assert {
    condition     = output.instance_name != ""
    error_message = "Instance name output must not be empty"
  }

  assert {
    condition     = output.instance_zone != ""
    error_message = "Instance zone output must not be empty"
  }

  assert {
    condition     = output.machine_type == "e2-micro"
    error_message = "Machine type output should match default"
  }
}

# Test 5: Test with custom machine type
run "test_custom_machine_type" {
  command = plan

  variables {
    project_id   = "test-project-123"
    machine_type = "e2-small"
  }

  assert {
    condition     = google_compute_instance.test_vm.machine_type == "e2-small"
    error_message = "Machine type should be e2-small when explicitly set"
  }

  assert {
    condition     = output.machine_type == "e2-small"
    error_message = "Output should reflect custom machine type"
  }
}

# Test 6: Verify boot disk configuration
run "verify_boot_disk" {
  command = plan

  variables {
    project_id = "test-project-123"
  }

  assert {
    condition     = google_compute_instance.test_vm.boot_disk[0].initialize_params[0].image == "debian-cloud/debian-11"
    error_message = "Boot disk must use Debian 11 image"
  }

  assert {
    condition     = google_compute_instance.test_vm.boot_disk[0].initialize_params[0].size == 10
    error_message = "Boot disk must be 10GB"
  }
}

# Test 7: Verify network interface exists
run "verify_network_interface" {
  command = plan

  variables {
    project_id = "test-project-123"
  }

  assert {
    condition     = length(google_compute_instance.test_vm.network_interface) > 0
    error_message = "VM must have at least one network interface"
  }

  assert {
    condition     = google_compute_instance.test_vm.network_interface[0].network == "default"
    error_message = "VM must use default network"
  }
}

# Test 8: Verify labels
run "verify_labels" {
  command = plan

  variables {
    project_id = "test-project-123"
  }

  assert {
    condition     = google_compute_instance.test_vm.labels["environment"] == "test"
    error_message = "Environment label must be 'test'"
  }

  assert {
    condition     = google_compute_instance.test_vm.labels["managed_by"] == "terraform"
    error_message = "managed_by label must be 'terraform'"
  }
}

# Test 9: Test with custom zone
run "test_custom_zone" {
  command = plan

  variables {
    project_id = "test-project-123"
    zone       = "us-west1-a"
  }

  assert {
    condition     = google_compute_instance.test_vm.zone == "us-west1-a"
    error_message = "Zone should be us-west1-a when explicitly set"
  }
}

# Test 10: Test with custom tags
run "test_custom_tags" {
  command = plan

  variables {
    project_id = "test-project-123"
    tags       = ["custom", "test", "demo"]
  }

  assert {
    condition     = contains(google_compute_instance.test_vm.tags, "custom")
    error_message = "Custom tags should be applied"
  }

  assert {
    condition     = length(google_compute_instance.test_vm.tags) == 3
    error_message = "Should have exactly 3 custom tags"
  }
}
