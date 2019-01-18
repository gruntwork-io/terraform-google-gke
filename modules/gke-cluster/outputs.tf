output "name" {
  description = "Cluster name"
  value       = "${google_container_cluster.cluster.name}"
}

output "region" {
  description = "Cluster region"
  value       = "${google_container_cluster.cluster.region}"
}

output "endpoint" {
  sensitive   = true
  description = "Cluster endpoint"
  value       = "${google_container_cluster.cluster.endpoint}"
}

output "min_master_version" {
  description = "Minimum master kubernetes version"
  value       = "${google_container_cluster.cluster.min_master_version}"
}

output "logging_service" {
  description = "Logging service used"
  value       = "${google_container_cluster.cluster.logging_service}"
}

output "monitoring_service" {
  description = "Monitoring service used"
  value       = "${google_container_cluster.cluster.monitoring_service}"
}

output "master_authorized_networks_config" {
  description = "Networks from which access to master is permitted"
  value       = "${var.master_authorized_networks_config}"
}

output "kubernetes_dashboard_enabled" {
  description = "Whether kubernetes dashboard enabled"
  value       = "${element(concat(google_container_cluster.cluster.*.addons_config.0.kubernetes_dashboard.0.disabled, list("")), 0)}"
}
