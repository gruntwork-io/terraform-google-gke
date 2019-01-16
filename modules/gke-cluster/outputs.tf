output "name" {
  description = "Cluster name"
  value       = "${local.cluster_name}"
}

output "type" {
  description = "Cluster type (regional / zonal)"
  value       = "${local.cluster_type}"
}

output "location" {
  description = "Cluster location (region if regional cluster, zone if zonal cluster)"
  value       = "${local.cluster_location}"
}

output "region" {
  description = "Cluster region"
  value       = "${local.cluster_region}"
}

output "endpoint" {
  sensitive   = true
  description = "Cluster endpoint"
  value       = "${local.cluster_endpoint}"
}

output "min_master_version" {
  description = "Minimum master kubernetes version"
  value       = "${local.cluster_min_master_version}"
}

output "logging_service" {
  description = "Logging service used"
  value       = "${local.cluster_logging_service}"
}

output "monitoring_service" {
  description = "Monitoring service used"
  value       = "${local.cluster_monitoring_service}"
}

output "master_authorized_networks_config" {
  description = "Networks from which access to master is permitted"
  value       = "${var.master_authorized_networks_config}"
}

output "kubernetes_dashboard_enabled" {
  description = "Whether kubernetes dashboard enabled"
  value       = "${element(concat(google_container_cluster.cluster.*.addons_config.0.kubernetes_dashboard.0.disabled, list("")), 0)}"
}
