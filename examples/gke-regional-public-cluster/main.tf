# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A GKE REGIONAL PUBLIC CLUSTER IN GOOGLE CLOUD
# This is an example of how to use the gke-cluster module to deploy a regional public Kubernetes cluster in GCP with a
# Load Balancer in front of it.
# ---------------------------------------------------------------------------------------------------------------------

provider "google" {
  project = "${var.project_id}"
  region  = "${var.region}"
}

# Use Terraform 0.10.x so that we can take advantage of Terraform GCP functionality as a separate provider via
# https://github.com/terraform-providers/terraform-provider-google
terraform {
  required_version = ">= 0.10.3"
}

module "gke_cluster" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/gke-cluster.git//modules/gke-cluster?ref=v0.0.1"
  source = "../../modules/gke-cluster"

  project_id = "${var.project_id}"
  region     = "${var.region}"
  name       = "example-cluster"

  network           = "${google_compute_network.main.name}"
  subnetwork        = "${google_compute_subnetwork.main.name}"
  ip_range_pods     = "${var.ip_range_pods}"
  ip_range_services = "${var.ip_range_services}"
  service_account   = "${var.compute_engine_service_account}"
}

# Network

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "google_compute_network" "main" {
  name                    = "cft-gke-test-${random_string.suffix.result}"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "main" {
  name          = "cft-gke-test-${random_string.suffix.result}"
  ip_cidr_range = "10.0.0.0/17"
  region        = "${var.region}"
  network       = "${google_compute_network.main.self_link}"

  secondary_ip_range {
    range_name    = "cft-gke-test-pods-${random_string.suffix.result}"
    ip_cidr_range = "192.168.0.0/18"
  }

  secondary_ip_range {
    range_name    = "cft-gke-test-services-${random_string.suffix.result}"
    ip_cidr_range = "192.168.64.0/18"
  }
}
