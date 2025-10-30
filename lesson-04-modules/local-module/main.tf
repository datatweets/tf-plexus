# Local Module Example - Root Module
# This demonstrates using a local child module

# Use local compute-instance module
module "web_server" {
  source = "./modules/compute-instance"

  project_id   = var.project_id
  name         = "web-server-1"
  zone         = var.zone
  machine_type = "e2-micro"
  
  boot_disk_size = 20
  boot_disk_type = "pd-standard"
  
  network = "default"
  
  tags = ["web-server", "http-server"]
  
  labels = {
    environment = "demo"
    managed_by  = "terraform"
    role        = "web"
  }
}

# Create another instance using the same module
module "app_server" {
  source = "./modules/compute-instance"

  project_id   = var.project_id
  name         = "app-server-1"
  zone         = var.zone
  machine_type = "e2-small"
  
  boot_disk_size = 30
  boot_disk_type = "pd-standard"
  
  network = "default"
  
  tags = ["app-server"]
  
  labels = {
    environment = "demo"
    managed_by  = "terraform"
    role        = "application"
  }
}

# Create multiple instances using count
module "worker_servers" {
  source = "./modules/compute-instance"
  count  = var.worker_count

  project_id   = var.project_id
  name         = "worker-${count.index}"
  zone         = var.zone
  machine_type = "e2-micro"
  
  boot_disk_size = 20
  boot_disk_type = "pd-standard"
  
  network = "default"
  
  tags = ["worker"]
  
  labels = {
    environment = "demo"
    managed_by  = "terraform"
    role        = "worker"
    index       = tostring(count.index)
  }
}
