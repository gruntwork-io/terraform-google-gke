# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A GKE PUBLIC CLUSTER IN GOOGLE CLOUD
# This is an example of how to use the gke-cluster module to deploy a public Kubernetes cluster in GCP with a
# Load Balancer in front of it.
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A GKE REGIONAL PUBLIC CLUSTER IN GOOGLE CLOUD
# ---------------------------------------------------------------------------------------------------------------------

module "gke_cluster" {
  source = "github.com/gruntwork-io/terraform-google-gke.git//modules/gke-cluster?ref=v0.1.0"

  name = "${var.cluster_name}"

  project  = "${var.project}"
  location = "${var.location}"

  # We're deploying the cluster in the 'public' subnetwork to allow outbound internet access
  # See the network access tier table for full details:
  # https://github.com/gruntwork-io/terraform-google-network/tree/master/modules/vpc-network#access-tier
  network = "${module.vpc_network.network}"

  subnetwork                   = "${module.vpc_network.public_subnetwork}"
  cluster_secondary_range_name = "${module.vpc_network.public_subnetwork_secondary_range_name}"
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

    # Add a public tag to the instances. See the network access tier table for full details:
    # https://github.com/gruntwork-io/terraform-google-network/tree/master/modules/vpc-network#access-tier
    tags = [
      "${module.vpc_network.public}",
      "tiller-example",
    ]

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
  source = "github.com/gruntwork-io/terraform-google-gke.git//modules/gke-service-account?ref=v0.1.0"

  name        = "${var.cluster_service_account_name}"
  project     = "${var.project}"
  description = "${var.cluster_service_account_description}"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A NETWORK TO DEPLOY THE CLUSTER TO
# ---------------------------------------------------------------------------------------------------------------------

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

module "vpc_network" {
  source = "github.com/gruntwork-io/terraform-google-network.git//modules/vpc-network?ref=v0.1.0"

  name_prefix = "${var.cluster_name}-network-${random_string.suffix.result}"
  project     = "${var.project}"
  region      = "${var.region}"

  cidr_block           = "${var.vpc_cidr_block}"
  secondary_cidr_block = "${var.vpc_secondary_cidr_block}"
}

# ---------------------------------------------------------------------------------------------------------------------
# PREPARE KUBERNETES PROVIDERS
# ---------------------------------------------------------------------------------------------------------------------

# We use this data provider to expose an access token for communicating with the GKE cluster.
data "google_client_config" "client" {}

# Use this datasource to access the Terraform account's email for Kubernetes permissions.
data "google_client_openid_userinfo" "terraform_user" {}

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
    name      = "${data.google_client_openid_userinfo.terraform_user.email}"
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
    command = "./kubergrunt helm deploy --service-account default --resource-namespace default --tiller-namespace kube-system ${local.tls_algorithm_config} --tls-subject-json '${jsonencode(var.tls_subject)}' --client-tls-subject-json '${jsonencode(var.client_tls_subject)}' --helm-home ${pathexpand("~/.helm")} --tiller-version v2.11.0 --rbac-user ${data.google_client_openid_userinfo.terraform_user.email}"
  }

  provisioner "local-exec" {
    command = "./kubergrunt helm undeploy --force --helm-home ${pathexpand("~/.helm")} --tiller-namespace kube-system ${local.undeploy_args}"
    when    = "destroy"
  }

  depends_on = ["null_resource.configure_kubectl", "kubernetes_cluster_role_binding.user"]
}

# Interpolate and construct kubergrunt deploy command args
locals {
  tls_algorithm_config = "--tls-private-key-algorithm ${var.private_key_algorithm} ${var.private_key_algorithm == "ECDSA" ? "--tls-private-key-ecdsa-curve ${var.private_key_ecdsa_curve}" : "--tls-private-key-rsa-bits ${var.private_key_rsa_bits}"}"

  undeploy_args = "${var.force_undeploy ? "--force" : ""} ${var.undeploy_releases ? "--undeploy-releases" : ""}"
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
