terraform {
  backend "gcs" {
    bucket = "terraform-prj-476214-staging-tfstate"
    prefix = "terraform/state"
  }
}
