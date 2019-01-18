output "cluster_endpoint" {
  #sensitive   = true
  description = "Cluster endpoint"
  value       = "${module.gke_cluster.endpoint}"
}
