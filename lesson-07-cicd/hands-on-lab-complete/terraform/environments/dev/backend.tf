terraform {
  backend "gcs" {
    bucket = "terraform-prj-476214-dev-tfstate"
    prefix = "terraform/state"
  }
}
