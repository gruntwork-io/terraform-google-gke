resource "google_container_cluster" "cluster" {
  name        = "${var.name}"
  description = "${var.description}"
  project     = "${var.project}"

  region           = "${var.region}"
  additional_zones = ["${coalescelist(compact(var.zones), sort(random_shuffle.available_zones.result))}"]

  network            = "${replace(data.google_compute_network.gke_network.self_link, "https://www.googleapis.com/compute/v1/", "")}"
  subnetwork         = "${replace(data.google_compute_subnetwork.gke_subnetwork.self_link, "https://www.googleapis.com/compute/v1/", "")}"
  min_master_version = "${local.kubernetes_version}"

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

  remove_default_node_pool = true
}

// Node Pool Resource
resource "google_container_node_pool" "pools" {
  count              = "${length(var.node_pools)}"
  name               = "${lookup(var.node_pools[count.index], "name")}"
  project            = "${var.project}"
  region             = "${var.region}"
  cluster            = "${var.name}"
  version            = "${lookup(var.node_pools[count.index], "auto_upgrade", false) ? "" : lookup(var.node_pools[count.index], "version", local.node_version)}"
  initial_node_count = "${lookup(var.node_pools[count.index], "initial_node_count", lookup(var.node_pools[count.index], "min_count", 1))}"

  autoscaling {
    min_node_count = "${lookup(var.node_pools[count.index], "min_count", 1)}"
    max_node_count = "${lookup(var.node_pools[count.index], "max_count", 100)}"
  }

  management {
    auto_repair  = "${lookup(var.node_pools[count.index], "auto_repair", true)}"
    auto_upgrade = "${lookup(var.node_pools[count.index], "auto_upgrade", true)}"
  }

  node_config {
    image_type   = "${lookup(var.node_pools[count.index], "image_type", "COS")}"
    machine_type = "${lookup(var.node_pools[count.index], "machine_type", "n1-standard-2")}"
    labels       = "${merge(map("cluster_name", var.name), map("node_pool", lookup(var.node_pools[count.index], "name")), var.node_pools_labels["all"], var.node_pools_labels[lookup(var.node_pools[count.index], "name")])}"
    metadata     = "${merge(map("cluster_name", var.name), map("node_pool", lookup(var.node_pools[count.index], "name")), var.node_pools_metadata["all"], var.node_pools_metadata[lookup(var.node_pools[count.index], "name")])}"
    taint        = "${concat(var.node_pools_taints["all"], var.node_pools_taints[lookup(var.node_pools[count.index], "name")])}"
    tags         = ["${concat(list("gke-${var.name}"), list("gke-${var.name}-${lookup(var.node_pools[count.index], "name")}"), var.node_pools_tags["all"], var.node_pools_tags[lookup(var.node_pools[count.index], "name")])}"]

    disk_size_gb    = "${lookup(var.node_pools[count.index], "disk_size_gb", 100)}"
    disk_type       = "${lookup(var.node_pools[count.index], "disk_type", "pd-standard")}"
    service_account = "${lookup(var.node_pools[count.index], "service_account", var.service_account)}"
    preemptible     = "${lookup(var.node_pools[count.index], "preemptible", false)}"

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

  depends_on = ["google_container_cluster.cluster"]
}

// TODO
// Add Data Source to get the latest k8s version
// Use this is k8s version is not set.

locals {
  kubernetes_version = "${var.kubernetes_version != "latest" ? var.kubernetes_version : data.google_container_engine_versions.region.latest_node_version}"
  node_version       = "${var.node_version != "" ? var.node_version : local.kubernetes_version}"
  network_project    = "${var.network_project != "" ? var.network_project : var.project}"
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
  zone    = "${data.google_compute_zones.available.names[0]}"
  project = "${var.project}"
}
