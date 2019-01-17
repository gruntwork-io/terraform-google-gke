resource "google_container_cluster" "cluster" {
  name        = "${var.name}"
  description = "${var.description}"
  project     = "${var.project}"

  region           = "${var.region}"
  additional_zones = ["${coalescelist(compact(var.zones), sort(random_shuffle.available_zones.result))}"]

  network            = "${replace(data.google_compute_network.gke_network.self_link, "https://www.googleapis.com/compute/v1/", "")}"
  subnetwork         = "${replace(data.google_compute_subnetwork.gke_subnetwork.self_link, "https://www.googleapis.com/compute/v1/", "")}"
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

  logging_service    = "${var.logging_service}"
  monitoring_service = "${var.monitoring_service}"

  master_authorized_networks_config = "${var.master_authorized_networks_config}"

  addons_config {
    http_load_balancing {
      disabled = "${var.http_load_balancing ? 0 : 1}"
    }

    horizontal_pod_autoscaling {
      disabled = "${var.horizontal_pod_autoscaling ? 0 : 1}"
    }

    kubernetes_dashboard {
      disabled = "${var.kubernetes_dashboard ? 0 : 1}"
    }

    network_policy_config {
      disabled = "${var.network_policy ? 0 : 1}"
    }
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "${var.ip_range_pods}"
    services_secondary_range_name = "${var.ip_range_services}"
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "${var.maintenance_start_time}"
    }
  }

  lifecycle {
    ignore_changes = ["node_pool"]
  }

  # Version 2.0.0 will set the default timeouts to these values.
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

// TODO
// Add Data Source to get the latest k8s version
// Use this is k8s version is not set.

locals {
  kubernetes_version = "${var.kubernetes_version != "latest" ? var.kubernetes_version : data.google_container_engine_versions.region.latest_node_version}"
  node_version       = "${var.node_version != "" ? var.node_version : local.kubernetes_version}"
  network_project    = "${var.network_project != "" ? var.network_project : var.project}"

  cluster_master_auth_map = "${concat(google_container_cluster.cluster.*.master_auth, list())}"

  # cluster locals
  cluster_type               = "regional"
  cluster_name               = "${element(concat(google_container_cluster.cluster.*.name, list("")), 0)}"
  cluster_location           = "${element(concat(google_container_cluster.cluster.*.region, list("")), 0)}"
  cluster_region             = "${element(concat(google_container_cluster.cluster.*.region, list("")), 0)}"
  cluster_endpoint           = "${element(concat(google_container_cluster.cluster.*.endpoint, list("")), 0)}"
  cluster_master_version     = "${element(concat(google_container_cluster.cluster.*.master_version, list("")), 0)}"
  cluster_min_master_version = "${element(concat(google_container_cluster.cluster.*.min_master_version, list("")), 0)}"
  cluster_logging_service    = "${element(concat(google_container_cluster.cluster.*.logging_service, list("")), 0)}"
  cluster_monitoring_service = "${element(concat(google_container_cluster.cluster.*.monitoring_service, list("")), 0)}"
}

data "google_compute_zones" "available" {
  project = "${var.project}"
  region  = "${var.region}"
}

data "google_compute_network" "gke_network" {
  name    = "${var.network}"
  project = "${local.network_project}"
}

data "google_compute_subnetwork" "gke_subnetwork" {
  name    = "${var.subnetwork}"
  region  = "${var.region}"
  project = "${local.network_project}"
}

resource "random_shuffle" "available_zones" {
  input        = ["${data.google_compute_zones.available.names}"]
  result_count = 3
}

/******************************************
  Get available container engine versions
 *****************************************/
data "google_container_engine_versions" "region" {
  region  = "${var.region}"
  project = "${var.project}"
}
