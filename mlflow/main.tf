terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.61.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.1.2"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}
