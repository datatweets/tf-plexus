# Development Environment
# Simple 2-server setup

module "web_server" {
  source = "../modules/server"

  name        = "dev-web"
  size        = "micro"
  environment = "dev"
  tier        = "web"
  zone        = var.zone
  region      = var.region

  enable_external_ip = true
  startup_script     = "${path.module}/../modules/server/startup.sh.tftpl"

  custom_labels = {
    team    = "development"
    project = var.project_name
  }
}

module "app_server" {
  source = "../modules/server"

  name        = "dev-app"
  size        = "small"
  environment = "dev"
  tier        = "app"
  zone        = var.zone
  region      = var.region

  enable_external_ip = false
  startup_script     = "${path.module}/../modules/server/startup.sh.tftpl"

  custom_labels = {
    team    = "development"
    project = var.project_name
  }
}
