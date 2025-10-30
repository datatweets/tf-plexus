terraform {
  backend "gcs" {
    bucket = "terraform-prj-476214-prod-tfstate"
    prefix = "terraform/state"
  }
}
