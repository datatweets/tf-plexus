terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "REPLACE-WITH-YOUR-BUCKET"
    prefix = "lesson-05/directory-structure/prod"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
