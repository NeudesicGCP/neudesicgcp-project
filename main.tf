# Define the neudesicgcp project

# Use the Google provider
provider "google" {
  version = "~> 1.20"

  # Use the exsting terraform credentials; comment out if not using this.
  # Note: provider can't use interpolation from local var defined below.
  credentials = "${file("${path.module}/terraform-credentials.json")}"
}

# Use the atum-the-creator project bucket for state
terraform {
  backend "gcs" {
    bucket = "atum-the-creator"
    prefix = "terraform/neudesicgcp"
  }
}

locals {
  terraform_creds = "${path.module}/terraform-credentials.json"
}

# Use Neudesic's project factory to create
module "neudesicgcp" {
  source       = "github.com/NeudesicGCP/terraform-project-factory"
  project_id   = "neudesicgcp"
  display_name = "NeudesicGCP settings"

  # Add the project to the 'foundations' folder
  folder_id = "896328535275"

  # Pass along the terraform credentials
  terraform_credentials = "${local.terraform_creds}"

  # Use existing Neudesic GCP organization
  org_domain_name = "neudesic.com"

  # Use the existing Neudesic GCP billing account
  org_billing_name = "neugcp"

  # APIs to enable
  enable_apis = [
    "compute.googleapis.com", # Compute drives many options
    "dns.googleapis.com",     # Enable DNS
  ]
}
