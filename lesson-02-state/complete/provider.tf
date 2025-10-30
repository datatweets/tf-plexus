# Complete example combining all meta-arguments
# This is the same code from the tutorial's complete example

terraform {
  required_version = ">= 1.9"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
}
