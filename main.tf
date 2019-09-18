# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A GKE PRIVATE CLUSTER W/ TILLER IN GOOGLE CLOUD PLATFORM
# This is an example of how to use the gke-cluster module to deploy a private Kubernetes cluster in GCP
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  # The modules used in this example have been updated with 0.12 syntax, additionally we depend on a bug fixed in
  # version 0.12.7.
  required_version = ">= 0.12.7"
}

# ---------------------------------------------------------------------------------------------------------------------
# PREPARE PROVIDERS
# ---------------------------------------------------------------------------------------------------------------------

provider "google" {
  version = "~> 2.9.0"
  project = var.project
  region  = var.region

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
  version = "~> 2.9.0"
  project = var.project
  region  = var.region

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

# We use this data provider to expose an access token for communicating with the GKE cluster.
data "google_client_config" "client" {}

# Use this datasource to access the Terraform account's email for Kubernetes permissions.
data "google_client_openid_userinfo" "terraform_user" {}

provider "kubernetes" {
  version = "~> 1.7.0"

  load_config_file       = false
  host                   = data.template_file.gke_host_endpoint.rendered
  token                  = data.template_file.access_token.rendered
  cluster_ca_certificate = data.template_file.cluster_ca_certificate.rendered
}

provider "helm" {
  # We don't install Tiller automatically, but instead use Kubergrunt as it sets up the TLS certificates much easier.
  install_tiller = false

  # Enable TLS so Helm can communicate with Tiller securely.
  enable_tls = true

  kubernetes {
    host                   = data.template_file.gke_host_endpoint.rendered
    token                  = data.template_file.access_token.rendered
    cluster_ca_certificate = data.template_file.cluster_ca_certificate.rendered
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A PRIVATE CLUSTER IN GOOGLE CLOUD PLATFORM
# ---------------------------------------------------------------------------------------------------------------------

module "gke_cluster" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "github.com/gruntwork-io/terraform-google-gke.git//modules/gke-cluster?ref=v0.2.0"
  source = "./modules/gke-cluster"

  name = var.cluster_name

  project  = var.project
  location = var.location
  network  = module.vpc_network.network

  # We're deploying the cluster in the 'public' subnetwork to allow outbound internet access
  # See the network access tier table for full details:
  # https://github.com/gruntwork-io/terraform-google-network/tree/master/modules/vpc-network#access-tier
  subnetwork = module.vpc_network.public_subnetwork

  # When creating a private cluster, the 'master_ipv4_cidr_block' has to be defined and the size must be /28
  master_ipv4_cidr_block = var.master_ipv4_cidr_block

  # This setting will make the cluster private
  enable_private_nodes = "true"

  # To make testing easier, we keep the public endpoint available. In production, we highly recommend restricting access to only within the network boundary, requiring your users to use a bastion host or VPN.
  disable_public_endpoint = "false"

  # With a private cluster, it is highly recommended to restrict access to the cluster master
  # However, for testing purposes we will allow all inbound traffic.
  master_authorized_networks_config = [
    {
      cidr_blocks = [
        {
          cidr_block   = "0.0.0.0/0"
          display_name = "all-for-testing"
        },
      ]
    },
  ]

  cluster_secondary_range_name = module.vpc_network.public_subnetwork_secondary_range_name
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A NODE POOL
# ---------------------------------------------------------------------------------------------------------------------

resource "google_container_node_pool" "node_pool" {
  provider = google-beta

  name     = "private-pool"
  project  = var.project
  location = var.location
  cluster  = module.gke_cluster.name

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
      private-pools-example = "true"
    }

    # Add a private tag to the instances. See the network access tier table for full details:
    # https://github.com/gruntwork-io/terraform-google-network/tree/master/modules/vpc-network#access-tier
    tags = [
      module.vpc_network.private,
      "private-pool-example",
    ]

    disk_size_gb = "30"
    disk_type    = "pd-standard"
    preemptible  = false

    service_account = module.gke_service_account.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  lifecycle {
    ignore_changes = [initial_node_count]
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
  # source = "github.com/gruntwork-io/terraform-google-gke.git//modules/gke-service-account?ref=v0.2.0"
  source = "./modules/gke-service-account"

  name        = var.cluster_service_account_name
  project     = var.project
  description = var.cluster_service_account_description
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
  source = "github.com/gruntwork-io/terraform-google-network.git//modules/vpc-network?ref=v0.2.1"

  name_prefix = "${var.cluster_name}-network-${random_string.suffix.result}"
  project     = var.project
  region      = var.region

  cidr_block           = var.vpc_cidr_block
  secondary_cidr_block = var.vpc_secondary_cidr_block
}

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE KUBECTL AND RBAC ROLE PERMISSIONS
# ---------------------------------------------------------------------------------------------------------------------

# configure kubectl with the credentials of the GKE cluster
resource "null_resource" "configure_kubectl" {
  provisioner "local-exec" {
    command = "gcloud beta container clusters get-credentials ${module.gke_cluster.name} --region ${var.region} --project ${var.project}"

    # Use environment variables to allow custom kubectl config paths
    environment = {
      KUBECONFIG = var.kubectl_config_path != "" ? var.kubectl_config_path : ""
    }
  }

  depends_on = [google_container_node_pool.node_pool]
}

# Create a ServiceAccount for Tiller
resource "kubernetes_service_account" "tiller" {
  metadata {
    name      = "tiller"
    namespace = local.tiller_namespace
  }
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
    name      = data.google_client_openid_userinfo.terraform_user.email
    api_group = "rbac.authorization.k8s.io"
  }

  # We give the Tiller ServiceAccount cluster admin status so that we can deploy anything in any namespace using this
  # Tiller instance for testing purposes. In production, you might want to use a more restricted role.
  subject {
    # this is a workaround for https://github.com/terraform-providers/terraform-provider-kubernetes/issues/204.
    # we have to set an empty api_group or the k8s call will fail. It will be fixed in v1.5.2 of the k8s provider.
    api_group = ""

    kind      = "ServiceAccount"
    name      = kubernetes_service_account.tiller.metadata[0].name
    namespace = local.tiller_namespace
  }

  subject {
    kind      = "Group"
    name      = "system:masters"
    api_group = "rbac.authorization.k8s.io"
  }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# GENERATE TLS CERTIFICATES FOR USE WITH TILLER
# This will use kubergrunt to generate TLS certificates, and upload them as Kubernetes Secrets that can then be used by
# Tiller.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

resource "null_resource" "tiller_tls_certs" {
  provisioner "local-exec" {
    command = <<-EOF
      kubergrunt tls gen --ca --namespace kube-system --secret-name ${local.tls_ca_secret_name} --secret-label gruntwork.io/tiller-namespace=${local.tiller_namespace} --secret-label gruntwork.io/tiller-credentials=true --secret-label gruntwork.io/tiller-credentials-type=ca --tls-subject-json '${jsonencode(var.tls_subject)}' ${local.tls_algorithm_config} ${local.kubectl_auth_config}

      kubergrunt tls gen --namespace ${local.tiller_namespace} --ca-secret-name ${local.tls_ca_secret_name} --ca-namespace kube-system --secret-name ${local.tls_secret_name} --secret-label gruntwork.io/tiller-namespace=${local.tiller_namespace} --secret-label gruntwork.io/tiller-credentials=true --secret-label gruntwork.io/tiller-credentials-type=server --tls-subject-json '${jsonencode(var.tls_subject)}' ${local.tls_algorithm_config} ${local.kubectl_auth_config}
    EOF

    # Use environment variables for Kubernetes credentials to avoid leaking into the logs
    environment = {
      KUBECTL_SERVER_ENDPOINT = data.template_file.gke_host_endpoint.rendered
      KUBECTL_CA_DATA         = base64encode(data.template_file.cluster_ca_certificate.rendered)
      KUBECTL_TOKEN           = data.template_file.access_token.rendered
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY TILLER TO THE GKE CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "tiller" {
  source = "github.com/gruntwork-io/terraform-kubernetes-helm.git//modules/k8s-tiller?ref=v0.5.0"

  tiller_tls_gen_method                    = "none"
  tiller_service_account_name              = kubernetes_service_account.tiller.metadata[0].name
  tiller_service_account_token_secret_name = kubernetes_service_account.tiller.default_secret_name
  tiller_tls_secret_name                   = local.tls_secret_name
  namespace                                = local.tiller_namespace
  tiller_image_version                     = local.tiller_version

  # Kubergrunt will store the private key under the key "tls.pem" in the corresponding Secret resource, which will be
  # accessed as a file when mounted into the container.
  tiller_tls_key_file_name = "tls.pem"

  dependencies = [null_resource.tiller_tls_certs.id, kubernetes_cluster_role_binding.user.id]
}

# The Deployment resources created in the module call to `k8s-tiller` will be complete creation before the rollout is
# complete. We use kubergrunt here to wait for the deployment to complete, so that when this resource is done creating,
# any resources that depend on this can assume Tiller is successfully deployed and up at that point.
resource "null_resource" "wait_for_tiller" {
  provisioner "local-exec" {
    command = "kubergrunt helm wait-for-tiller --tiller-namespace ${local.tiller_namespace} --tiller-deployment-name ${module.tiller.deployment_name} --expected-tiller-version ${local.tiller_version} ${local.kubectl_auth_config}"

    # Use environment variables for Kubernetes credentials to avoid leaking into the logs
    environment = {
      KUBECTL_SERVER_ENDPOINT = data.template_file.gke_host_endpoint.rendered
      KUBECTL_CA_DATA         = base64encode(data.template_file.cluster_ca_certificate.rendered)
      KUBECTL_TOKEN           = data.template_file.access_token.rendered
    }
  }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CONFIGURE OPERATOR HELM CLIENT
# To allow usage of the helm client immediately, we grant access to the admin RBAC user and configure the local helm
# client.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

resource "null_resource" "grant_and_configure_helm" {
  provisioner "local-exec" {
    command = <<-EOF
    kubergrunt helm grant --tiller-namespace ${local.tiller_namespace} --tls-subject-json '${jsonencode(var.client_tls_subject)}' --rbac-user ${data.google_client_openid_userinfo.terraform_user.email} ${local.kubectl_auth_config}

    kubergrunt helm configure --helm-home ${pathexpand("~/.helm")} --tiller-namespace ${local.tiller_namespace} --resource-namespace ${local.resource_namespace} --rbac-user ${data.google_client_openid_userinfo.terraform_user.email} ${local.kubectl_auth_config}
    EOF

    # Use environment variables for Kubernetes credentials to avoid leaking into the logs
    environment = {
      KUBECTL_SERVER_ENDPOINT = data.template_file.gke_host_endpoint.rendered
      KUBECTL_CA_DATA         = base64encode(data.template_file.cluster_ca_certificate.rendered)
      KUBECTL_TOKEN           = data.template_file.access_token.rendered
    }
  }

  depends_on = [null_resource.wait_for_tiller]
}

# ---------------------------------------------------------------------------------------------------------------------
# COMPUTATIONS
# These locals set constants and compute various useful information used throughout this Terraform module.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # For this example, we hardcode our tiller namespace to kube-system. In production, you might want to consider using a
  # different Namespace.
  tiller_namespace = "kube-system"

  # For this example, we setup Tiller to manage the default Namespace.
  resource_namespace = "default"

  # We install an older version of Tiller to match the Helm library version used in the Terraform helm provider.
  tiller_version = "v2.11.0"

  # We store the CA Secret in the kube-system Namespace, given that only cluster admins should access these.
  tls_ca_secret_namespace = "kube-system"

  # We name the TLS Secrets to be compatible with the `kubergrunt helm grant` command
  tls_ca_secret_name   = "${local.tiller_namespace}-namespace-tiller-ca-certs"
  tls_secret_name      = "tiller-certs"
  tls_algorithm_config = "--tls-private-key-algorithm ${var.private_key_algorithm} ${var.private_key_algorithm == "ECDSA" ? "--tls-private-key-ecdsa-curve ${var.private_key_ecdsa_curve}" : "--tls-private-key-rsa-bits ${var.private_key_rsa_bits}"}"

  # These will be filled in by the shell environment
  kubectl_auth_config = "--kubectl-server-endpoint \"$KUBECTL_SERVER_ENDPOINT\" --kubectl-certificate-authority \"$KUBECTL_CA_DATA\" --kubectl-token \"$KUBECTL_TOKEN\""
}

# ---------------------------------------------------------------------------------------------------------------------
# WORKAROUNDS
# ---------------------------------------------------------------------------------------------------------------------

# This is a workaround for the Kubernetes and Helm providers as Terraform doesn't currently support passing in module
# outputs to providers directly.
data "template_file" "gke_host_endpoint" {
  template = module.gke_cluster.endpoint
}

data "template_file" "access_token" {
  template = data.google_client_config.client.access_token
}

data "template_file" "cluster_ca_certificate" {
  template = module.gke_cluster.cluster_ca_certificate
}
