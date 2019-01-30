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

  name = "${var.cluster_name}"

  project    = "${var.project}"
  region     = "${var.region}"
  network    = "${google_compute_network.main.name}"
  subnetwork = "${google_compute_subnetwork.main.name}"
}

# Node Pool

// Node Pool Resource
resource "google_container_node_pool" "node_pool" {
  provider = "google-beta"

  name    = "main-pool"
  project = "${var.project}"
  region  = "${var.region}"
  cluster = "${module.gke_cluster.name}"

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
}

data "google_client_config" "client" {}

data "template_file" "gke_host_endpoint" {
  template = "${module.gke_cluster.endpoint}"
}

data "template_file" "access_token" {
  template = "${data.google_client_config.client.access_token}"
}

data "template_file" "cluster_ca_certificate" {
  template = "${module.gke_cluster.cluster_ca_certificate}"
}


provider "kubernetes" {
    load_config_file = false

    host                   = "${data.template_file.gke_host_endpoint.rendered}"
    token                  = "${data.template_file.access_token.rendered}"
    cluster_ca_certificate = "${base64decode(data.template_file.cluster_ca_certificate.rendered)}"
}

resource "kubernetes_cluster_role_binding" "user" {
  metadata {
    name = "admin-me"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "User"
    name      = "tf-153@graphite-test-rileykarson.iam.gserviceaccount.com"
  }
}

module "namespace" {
  source = "git::git@github.com:gruntwork-io/terraform-kubernetes-helm.git//modules/k8s-namespace?ref=master"
  name = "my-new-namespace"
}
