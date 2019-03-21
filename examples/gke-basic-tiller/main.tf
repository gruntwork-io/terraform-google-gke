# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A GKE REGIONAL PUBLIC CLUSTER IN GOOGLE CLOUD
# This is an example of how to use the gke-cluster module to deploy a regional public Kubernetes cluster in GCP with a
# Load Balancer in front of it.
# ---------------------------------------------------------------------------------------------------------------------

# Use Terraform 0.10.x so that we can take advantage of Terraform GCP functionality as a separate provider via
# https://github.com/terraform-providers/terraform-provider-google
terraform {
  required_version = ">= 0.10.3"
}

provider "google" {
  version = "~> 2.2.0"
  project = "${var.project}"
  region  = "${var.region}"
}

provider "google-beta" {
  version = "~> 2.2.0"
  project = "${var.project}"
  region  = "${var.region}"
}

# We use this data provider to expose an access token for communicating with the GKE cluster.
data "google_client_config" "client" {}

provider "kubernetes" {
  load_config_file = false

  host                   = "${data.template_file.gke_host_endpoint.rendered}"
  token                  = "${data.template_file.access_token.rendered}"
  cluster_ca_certificate = "${data.template_file.cluster_ca_certificate.rendered}"
}

provider "helm" {
  # We don't install Tiller automatically, but instead use Kubergrunt as it sets up the TLS certificates much easier.
  install_tiller = false

  # Enable TLS so Helm can communicate with Tiller securely.
  enable_tls = true

  # We can remove the following parameters after Yori's PR is released:
  # https://github.com/terraform-providers/terraform-provider-helm/pull/210
  client_key = "${pathexpand("~/.helm/key.pem")}"

  client_certificate = "${pathexpand("~/.helm/cert.pem")}"
  ca_certificate     = "${pathexpand("~/.helm/ca.pem")}"

  kubernetes {
    host                   = "${data.template_file.gke_host_endpoint.rendered}"
    token                  = "${data.template_file.access_token.rendered}"
    cluster_ca_certificate = "${data.template_file.cluster_ca_certificate.rendered}"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A GKE REGIONAL PUBLIC CLUSTER IN GOOGLE CLOUD
# ---------------------------------------------------------------------------------------------------------------------

module "gke_cluster" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:gruntwork-io/gke-cluster.git//modules/gke-cluster?ref=v0.0.1"
  source = "../../modules/gke-cluster"

  name = "${var.cluster_name}"

  // TODO(rileykarson): Update this when a new version comes out
  kubernetes_version = "1.12.5-gke.5"

  project    = "${var.project}"
  region     = "${var.region}"
  network    = "${google_compute_network.main.name}"
  subnetwork = "${google_compute_subnetwork.main.name}"
}

# Deploy a Node Pool

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

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE KUBECTL AND RBAC ROLE PERMISSIONS
# ---------------------------------------------------------------------------------------------------------------------

# configure kubectl with the credentials of the GKE cluster
resource "null_resource" "configure_kubectl" {
  provisioner "local-exec" {
    command = "gcloud beta container clusters get-credentials ${module.gke_cluster.name} --region ${var.region} --project ${var.project}"
  }

  depends_on = ["google_container_node_pool.node_pool"]
}

resource "kubernetes_cluster_role_binding" "user" {
  metadata {
    name = "admin-user"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "User"
    name      = "${var.iam_user}"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    # this is a workaround for https://github.com/terraform-providers/terraform-provider-kubernetes/issues/204.
    # we have to set an empty api_group or the k8s call will fail. It will be fixed in v1.5.2 of the k8s provider.
    api_group = ""

    kind      = "ServiceAccount"
    name      = "default"
    namespace = "kube-system"
  }

  subject {
    kind      = "Group"
    name      = "system:masters"
    api_group = "rbac.authorization.k8s.io"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY TILLER TO THE GKE CLUSTER USING KUBERGRUNT
# ---------------------------------------------------------------------------------------------------------------------

# We install an older version of Tiller as the provider expects this.
resource "null_resource" "tiller" {
  provisioner "local-exec" {
    command = "kubergrunt helm deploy --service-account default --resource-namespace default --tiller-namespace kube-system ${local.tls_config} ${local.client_tls_config} --helm-home ${pathexpand("~/.helm")} --tiller-version v2.11.0 --rbac-user ${var.iam_user}"
  }

  provisioner "local-exec" {
    command = "kubergrunt helm undeploy --helm-home ${pathexpand("~/.helm")} --tiller-namespace kube-system ${local.undeploy_args}"
    when    = "destroy"
  }

  depends_on = ["null_resource.configure_kubectl", "kubernetes_cluster_role_binding.user"]
}

# ---------------------------------------------------------------------------------------------------------------------
# WORKAROUNDS
# ---------------------------------------------------------------------------------------------------------------------

# This is a workaround for the Kubernetes and Helm providers as Terraform doesn't currently support passing in module
# outputs to providers directly.
data "template_file" "gke_host_endpoint" {
  template = "${module.gke_cluster.endpoint}"
}

data "template_file" "access_token" {
  template = "${data.google_client_config.client.access_token}"
}

data "template_file" "cluster_ca_certificate" {
  template = "${module.gke_cluster.cluster_ca_certificate}"
}
