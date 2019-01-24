output "name" {
  # This may seem redundant with the `name` input, but it serves an important
  # purpose. Terraform won't establish a dependency graph without this to interpolate on.
  description = "The name of the cluster master. This output is used for interpolation with node pools, other modules."
  value       = "${google_container_cluster.cluster.name}"
}


output "master_version" {
  description = "The Kubernetes master version."
  value       = "${google_container_cluster.cluster.master_version}"
}

output "endpoint" {
  description = "The IP address of the cluster master."
  sensitive   = true
  value       = "${google_container_cluster.cluster.endpoint}"
}

output "cluster_ca_certificate" {
  description = "The public certificate that is the root of trust for the cluster. Encoded as base64."
  sensitive   = true
  value       = "${google_container_cluster.cluster.master_auth.0.cluster_ca_certificate}"
}

// TODO(robmorgan): Is this a useful output?
output "master_authorized_networks_config" {
  description = "Networks from which access to master is permitted"
  value       = "${var.master_authorized_networks_config}"
}
