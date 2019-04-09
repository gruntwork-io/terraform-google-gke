# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY A GKE CLUSTER
# This module deploys a GKE cluster, a managed, production-ready environment for deploying containerized applications.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

resource "google_container_cluster" "cluster" {
  name        = "${var.name}"
  description = "${var.description}"

  project    = "${var.project}"
  location   = "${var.location}"
  network    = "${replace(data.google_compute_network.gke_network.self_link, "https://www.googleapis.com/compute/v1/", "")}"
  subnetwork = "${replace(data.google_compute_subnetwork.gke_subnetwork.self_link, "https://www.googleapis.com/compute/v1/", "")}"

  logging_service    = "${var.logging_service}"
  monitoring_service = "${var.monitoring_service}"
  min_master_version = "${local.kubernetes_version}"

  # We want to make a cluster with no node pools, and manage them all with the
  # fine-grained google_container_node_pool resource. The API requires a node
  # pool or an initial count to be defined; that initial count creates the
  # "default node pool" with that # of nodes.
  #
  # So, we need to set an initial_node_count of 1. This will make a default node
  # pool with server-defined defaults that Terraform will immediately delete as
  # part of Create. This leaves us in our desired state- with a cluster master
  # with no node pools.
  remove_default_node_pool = true

  initial_node_count = 1

  # ip_allocation_policy.use_ip_aliases defaults to true, since we define the block `ip_allocation_policy`
  ip_allocation_policy {
    // Choose the range, but let GCP pick the IPs within the range
    cluster_secondary_range_name  = "${var.cluster_secondary_range_name}"
    services_secondary_range_name = "${var.cluster_secondary_range_name}"
  }

  # We can optionally control access to the cluster
  # See https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters
  private_cluster_config {
    enable_private_endpoint = "${var.disable_public_endpoint}"
    enable_private_nodes    = "${var.enable_private_nodes}"
    master_ipv4_cidr_block  = "${var.master_ipv4_cidr_block}"
  }

  addons_config {
    http_load_balancing {
      disabled = "${var.http_load_balancing ? 0 : 1}"
    }

    horizontal_pod_autoscaling {
      disabled = "${var.horizontal_pod_autoscaling ? 0 : 1}"
    }

    kubernetes_dashboard {
      disabled = "${var.enable_kubernetes_dashboard ? 0 : 1}"
    }

    network_policy_config {
      disabled = "${var.enable_network_policy ? 0 : 1}"
    }
  }

  network_policy {
    enabled = "${var.enable_network_policy}"

    # Tigera (Calico Felix) is the only provider
    provider = "CALICO"
  }

  master_auth {
    username = "${var.basic_auth_username}"
    password = "${var.basic_auth_password}"

    client_certificate_config {
      issue_client_certificate = "${var.enable_kubernetes_dashboard}"
    }
  }

  master_authorized_networks_config = "${var.master_authorized_networks_config}"

  maintenance_policy {
    daily_maintenance_window {
      start_time = "${var.maintenance_start_time}"
    }
  }

  # Version 2.0.0 will set the default timeouts to these values.
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

locals {
  kubernetes_version = "${var.kubernetes_version != "latest" ? var.kubernetes_version : data.google_container_engine_versions.location.latest_node_version}"
  network_project    = "${var.network_project != "" ? var.network_project : var.project}"
}

data "google_compute_network" "gke_network" {
  name    = "${var.network}"
  project = "${local.network_project}"
}

data "google_compute_subnetwork" "gke_subnetwork" {
  self_link = "${var.subnetwork}"
}

// Get available master versions in our location to determine the latest version
data "google_container_engine_versions" "location" {
  location = "${var.location}"
  project  = "${var.project}"
}
