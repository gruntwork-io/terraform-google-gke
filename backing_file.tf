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
  version = "~> 2.6.0"
  project = "${var.project}"
  region  = "${var.region}"

  scopes = [
    # Default scopes
    "https://www.googleapis.com/auth/compute",

    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    "https://www.googleapis.com/auth/devstorage.full_control",

    # Required for google_client_openid_userinfo
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

provider "google-beta" {
  version = "~> 2.6.0"
  project = "${var.project}"
  region  = "${var.region}"

  scopes = [
    # Default scopes
    "https://www.googleapis.com/auth/compute",

    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    "https://www.googleapis.com/auth/devstorage.full_control",

    # Required for google_client_openid_userinfo
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}
