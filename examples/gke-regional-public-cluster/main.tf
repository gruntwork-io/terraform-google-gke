# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A GKE REGIONAL PUBLIC CLUSTER IN GOOGLE CLOUD
# This is an example of how to use the gke-cluster module to deploy a regional public Kubernetes cluster in GCP with a
# Load Balancer in front of it.
# ---------------------------------------------------------------------------------------------------------------------

provider "google-beta" {
  project = "${var.project}"
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

  project = "${var.project}"
  region  = "${var.region}"
  name    = "${var.cluster_name}"

  network           = "${google_compute_network.main.name}"
  subnetwork        = "${google_compute_subnetwork.main.name}"
  ip_range_pods     = "${google_compute_subnetwork.main.secondary_ip_range.0.range_name}"
  ip_range_services = "${google_compute_subnetwork.main.secondary_ip_range.1.range_name}"

  #service_account   = "${var.compute_engine_service_account}"
}

# Node Pool

// Node Pool Resource
resource "google_container_node_pool" "node_pool" {
  name               = "main-pool"
  project            = "${var.project}"
  region             = "${var.region}"
  cluster            = "${var.cluster_name}"
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

    # for custom shutdown scripts etc
    # metadata = ""


    #[DEPRECATED] This field is in beta and will be removed from this provider. Use it in the the google-beta provider instead.
    # See https://terraform.io/docs/providers/google/provider_versions.html for more details.
    #taint = {
    #  key    = "main-pool-example"
    #  value  = "true"
    #  effect = "PREFER_NO_SCHEDULE"
    #}

    tags         = ["main-pool-example"]
    disk_size_gb = "30"
    disk_type    = "pd-standard"
    #service_account = "${lookup(var.node_pools[count.index], "service_account", var.service_account)}"
    preemptible = false
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
