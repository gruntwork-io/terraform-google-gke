# ---------------------------------------------------------------------------------------------------------------------
# This file has some scaffolding to make sure that names are unique and that a region and zone are selected when you try
# to create your Terraform resources.
# ---------------------------------------------------------------------------------------------------------------------

# Use Terraform 0.10.x so that we can take advantage of Terraform GCP functionality as a separate provider via
# https://github.com/terraform-providers/terraform-provider-google
terraform {
  required_version = ">= 0.10.3"
}

provider "google" {
  version = "~> 2.3.0"
  project = "${var.project}"
  region  = "${var.region}"
}

provider "google-beta" {
  version = "~> 2.3.0"
  project = "${var.project}"
  region  = "${var.region}"
}
