# Test 1: Networking module creates VPC and subnets
run "networking_infrastructure_created" {
  command = plan
  
  variables {
    project_id  = "test-project"
    vpc_name    = "test-vpc"
    subnets = {
      "subnet-us-central" = {
        cidr   = "10.0.1.0/24"
        region = "us-central1"
      }
      "subnet-us-west" = {
        cidr   = "10.0.2.0/24"
        region = "us-west1"
      }
    }
    primary_subnet_name = "subnet-us-central"
    instances = {
      "web-1" = {
        machine_type = "e2-micro"
        zone         = "us-central1-a"
      }
    }
  }
  
  # Verify VPC creation
  assert {
    condition     = google_compute_network.vpc.name == "test-vpc"
    error_message = "VPC should be created with correct name"
  }
  
  assert {
    condition     = google_compute_network.vpc.auto_create_subnetworks == false
    error_message = "VPC should not auto-create subnets"
  }
  
  # Verify subnets created
  assert {
    condition     = length(google_compute_subnetwork.subnets) == 2
    error_message = "Should create 2 subnets"
  }
  
  assert {
    condition     = google_compute_subnetwork.subnets["subnet-us-central"].ip_cidr_range == "10.0.1.0/24"
    error_message = "Subnet should have correct CIDR"
  }
  
  # Verify firewall rule
  assert {
    condition     = google_compute_firewall.allow_internal.network == "test-vpc"
    error_message = "Firewall should be attached to VPC"
  }
}

# Test 2: Compute instances use networking module outputs
run "compute_uses_networking_outputs" {
  command = plan
  
  variables {
    project_id  = "test-project"
    vpc_name    = "test-vpc"
    subnets = {
      "subnet-central" = {
        cidr   = "10.0.1.0/24"
        region = "us-central1"
      }
    }
    primary_subnet_name = "subnet-central"
    instances = {
      "web-1" = {
        machine_type = "e2-micro"
        zone         = "us-central1-a"
      }
    }
  }
  
  # Verify compute module receives network ID from networking module
  assert {
    condition     = module.compute.network_id == module.networking.vpc_id
    error_message = "Compute should receive VPC ID from networking module"
  }
  
  # Verify instances connected to correct subnet
  assert {
    condition     = module.compute.subnetwork_id == module.networking.subnet_ids["subnet-central"]
    error_message = "Compute should use subnet from networking module"
  }
}

# Test 3: Data flow between modules works correctly
run "data_flows_between_modules" {
  command = plan
  
  variables {
    project_id  = "test-project"
    vpc_name    = "integration-vpc"
    subnets = {
      "app-subnet" = {
        cidr   = "10.10.1.0/24"
        region = "us-central1"
      }
    }
    primary_subnet_name = "app-subnet"
    instances = {
      "app-server" = {
        machine_type = "e2-small"
        zone         = "us-central1-a"
      }
    }
  }
  
  # Verify VM is attached to the VPC created by networking module
  assert {
    condition     = google_compute_instance.instances["app-server"].network_interface[0].network == google_compute_network.vpc.id
    error_message = "Instance should be connected to networking VPC"
  }
  
  # Verify VM is in the correct subnet
  assert {
    condition     = google_compute_instance.instances["app-server"].network_interface[0].subnetwork == google_compute_subnetwork.subnets["app-subnet"].id
    error_message = "Instance should be in correct subnet"
  }
  
  # Verify VM zone matches subnet region
  assert {
    condition     = can(regex("^us-central1", google_compute_instance.instances["app-server"].zone))
    error_message = "Instance zone should match subnet region"
  }
}

# Test 4: Multiple instances across multiple subnets
run "multi_instance_multi_subnet" {
  command = plan
  
  variables {
    project_id  = "test-project"
    vpc_name    = "multi-tier-vpc"
    subnets = {
      "web-subnet" = {
        cidr   = "10.0.1.0/24"
        region = "us-central1"
      }
      "app-subnet" = {
        cidr   = "10.0.2.0/24"
        region = "us-central1"
      }
    }
    primary_subnet_name = "web-subnet"
    instances = {
      "web-1" = {
        machine_type = "e2-micro"
        zone         = "us-central1-a"
      }
      "web-2" = {
        machine_type = "e2-micro"
        zone         = "us-central1-b"
      }
    }
  }
  
  # Verify multiple subnets created
  assert {
    condition     = length(google_compute_subnetwork.subnets) == 2
    error_message = "Should create 2 subnets"
  }
  
  # Verify multiple instances created
  assert {
    condition     = length(google_compute_instance.instances) == 2
    error_message = "Should create 2 instances"
  }
  
  # Verify both instances in same subnet (primary)
  assert {
    condition     = google_compute_instance.instances["web-1"].network_interface[0].subnetwork == google_compute_subnetwork.subnets["web-subnet"].id
    error_message = "web-1 should be in web-subnet"
  }
  
  assert {
    condition     = google_compute_instance.instances["web-2"].network_interface[0].subnetwork == google_compute_subnetwork.subnets["web-subnet"].id
    error_message = "web-2 should be in web-subnet"
  }
}

# Test 5: Module outputs are propagated correctly
run "module_outputs_propagate" {
  command = plan
  
  variables {
    project_id  = "test-project"
    vpc_name    = "output-test-vpc"
    subnets = {
      "main-subnet" = {
        cidr   = "10.0.1.0/24"
        region = "us-central1"
      }
    }
    primary_subnet_name = "main-subnet"
    instances = {
      "test-vm" = {
        machine_type = "e2-micro"
        zone         = "us-central1-a"
      }
    }
  }
  
  # Root outputs should expose networking outputs
  assert {
    condition     = output.vpc_id == module.networking.vpc_id
    error_message = "Root should expose VPC ID"
  }
  
  assert {
    condition     = output.subnet_ids == module.networking.subnet_ids
    error_message = "Root should expose subnet IDs"
  }
  
  # Root outputs should expose compute outputs
  assert {
    condition     = output.instance_ids == module.compute.instance_ids
    error_message = "Root should expose instance IDs"
  }
}

# Test 6: Integration with tags and labels
run "tags_and_labels_integration" {
  command = plan
  
  variables {
    project_id  = "test-project"
    vpc_name    = "labeled-vpc"
    subnets = {
      "labeled-subnet" = {
        cidr   = "10.0.1.0/24"
        region = "us-central1"
      }
    }
    primary_subnet_name = "labeled-subnet"
    instances = {
      "labeled-vm" = {
        machine_type = "e2-micro"
        zone         = "us-central1-a"
        tags         = ["web", "production"]
        labels = {
          environment = "prod"
          tier        = "web"
        }
      }
    }
  }
  
  # Verify tags applied
  assert {
    condition     = contains(google_compute_instance.instances["labeled-vm"].tags, "web")
    error_message = "Instance should have web tag"
  }
  
  assert {
    condition     = contains(google_compute_instance.instances["labeled-vm"].tags, "managed-by-terraform")
    error_message = "Instance should have default terraform tag"
  }
  
  # Verify labels applied
  assert {
    condition     = google_compute_instance.instances["labeled-vm"].labels["environment"] == "prod"
    error_message = "Instance should have environment label"
  }
  
  assert {
    condition     = google_compute_instance.instances["labeled-vm"].labels["managed_by"] == "terraform"
    error_message = "Instance should have default managed_by label"
  }
}

# Test 7: Firewall rule covers all subnet ranges
run "firewall_covers_all_subnets" {
  command = plan
  
  variables {
    project_id  = "test-project"
    vpc_name    = "firewall-test-vpc"
    subnets = {
      "subnet-1" = {
        cidr   = "10.0.1.0/24"
        region = "us-central1"
      }
      "subnet-2" = {
        cidr   = "10.0.2.0/24"
        region = "us-west1"
      }
      "subnet-3" = {
        cidr   = "10.0.3.0/24"
        region = "us-east1"
      }
    }
    primary_subnet_name = "subnet-1"
    instances = {
      "test-vm" = {
        machine_type = "e2-micro"
        zone         = "us-central1-a"
      }
    }
  }
  
  # Verify firewall includes all subnet CIDRs
  assert {
    condition     = contains(google_compute_firewall.allow_internal.source_ranges, "10.0.1.0/24")
    error_message = "Firewall should include subnet-1 CIDR"
  }
  
  assert {
    condition     = contains(google_compute_firewall.allow_internal.source_ranges, "10.0.2.0/24")
    error_message = "Firewall should include subnet-2 CIDR"
  }
  
  assert {
    condition     = contains(google_compute_firewall.allow_internal.source_ranges, "10.0.3.0/24")
    error_message = "Firewall should include subnet-3 CIDR"
  }
  
  assert {
    condition     = length(google_compute_firewall.allow_internal.source_ranges) == 3
    error_message = "Firewall should have exactly 3 source ranges"
  }
}
