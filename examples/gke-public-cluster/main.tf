# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A GKE PUBLIC CLUSTER IN GOOGLE CLOUD
# This is an example of how to use the gke-cluster module to deploy a public Kubernetes cluster in GCP with a
# Load Balancer in front of it.
# ---------------------------------------------------------------------------------------------------------------------

# Use Terraform 0.10.x so that we can take advantage of Terraform GCP functionality as a separate provider via
# https://github.com/terraform-providers/terraform-provider-google
terraform {
  required_version = ">= 0.10.3"
}

# ---------------------------------------------------------------------------------------------------------------------
# PREPARE PROVIDERS
# ---------------------------------------------------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A PUBLIC CLUSTER IN GOOGLE CLOUD
# ---------------------------------------------------------------------------------------------------------------------

module "gke_cluster" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-google-gke.git//modules/gke-cluster?ref=v0.0.4"
  source = "../../modules/gke-cluster"

  name = "${var.cluster_name}"

  project    = "${var.project}"
  location   = "${var.location}"
  network    = "${google_compute_network.main.name}"
  subnetwork = "${google_compute_subnetwork.main.self_link}"

  cluster_secondary_range_name = "${google_compute_subnetwork.main.secondary_ip_range.0.range_name}"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A NODE POOL
# ---------------------------------------------------------------------------------------------------------------------

resource "google_container_node_pool" "node_pool" {
  provider = "google-beta"

  name     = "main-pool"
  project  = "${var.project}"
  location = "${var.location}"
  cluster  = "${module.gke_cluster.name}"

  initial_node_count = "1"

  autoscaling {
    min_node_count = "1"
    max_node_count = "5"
  }

  management {
    auto_repair  = "true"
    auto_upgrade = "true"
  }

  node_config {
    image_type   = "COS"
    machine_type = "n1-standard-1"

    labels = {
      all-pools-example = "true"
    }

    tags         = ["main-pool-example"]
    disk_size_gb = "30"
    disk_type    = "pd-standard"
    preemptible  = false

    service_account = "${module.gke_service_account.email}"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  lifecycle {
    ignore_changes = ["initial_node_count"]
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A CUSTOM SERVICE ACCOUNT TO USE WITH THE GKE CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "gke_service_account" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/terraform-google-gke.git//modules/gke-service-account?ref=v0.0.4"
  source = "../../modules/gke-service-account"

  name        = "${var.cluster_service_account_name}"
  project     = "${var.project}"
  description = "${var.cluster_service_account_description}"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A NETWORK TO DEPLOY THE CLUSTER TO
# ---------------------------------------------------------------------------------------------------------------------
# TODO(rileykarson): Add proper VPC network config once we've made a VPC module
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "google_compute_network" "main" {
  name                    = "${var.cluster_name}-network-${random_string.suffix.result}"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "main" {
  name          = "${var.cluster_name}-subnetwork-${random_string.suffix.result}"
  ip_cidr_range = "10.0.0.0/17"
  region        = "${var.region}"
  network       = "${google_compute_network.main.self_link}"

  secondary_ip_range {
    range_name    = "cluster-pods"
    ip_cidr_range = "10.1.0.0/18"
  }
}
