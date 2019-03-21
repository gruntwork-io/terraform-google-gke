# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These parameters must be supplied when consuming this module.
# ---------------------------------------------------------------------------------------------------------------------

variable "project" {
  description = "The project ID to host the cluster in"
}

variable "region" {
  description = "The region to host the cluster in"
}

variable "name" {
  description = "The name of the cluster"
}

variable "network" {
  description = "The VPC network to host the cluster in"
}

variable "subnetwork" {
  description = "The subnetwork to host the cluster in"
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# Generally, these values won't need to be changed.
# ---------------------------------------------------------------------------------------------------------------------

variable "description" {
  description = "The description of the cluster"
  default     = ""
}

variable "kubernetes_version" {
  description = "The Kubernetes version of the masters. If set to 'latest' it will pull latest available version in the selected region."
  default     = "latest"
}

variable "logging_service" {
  description = "The logging service that the cluster should write logs to. Available options include logging.googleapis.com, logging.googleapis.com/kubernetes (beta), and none"
  default     = "logging.googleapis.com"
}

variable "monitoring_service" {
  description = "The monitoring service that the cluster should write metrics to. Automatically send metrics from pods in the cluster to the Google Cloud Monitoring API. VM metrics will be collected by Google Compute Engine regardless of this setting Available options include monitoring.googleapis.com, monitoring.googleapis.com/kubernetes (beta) and none"
  default     = "monitoring.googleapis.com"
}

variable "horizontal_pod_autoscaling" {
  description = "Whether to enable the horizontal pod autoscaling addon"
  default     = true
}

variable "http_load_balancing" {
  description = "Whether to enable the http (L7) load balancing addon"
  default     = true
}

// TODO(robmorgan): Are we using these values below? We should understand them more fully before adding them to configs.

variable "network_project" {
  description = "The project ID of the shared VPC's host (for shared vpc support)"
  default     = ""
}

variable "master_authorized_networks_config" {
  type = "list"

  description = <<EOF
  The desired configuration options for master authorized networks. Omit the nested cidr_blocks attribute to disallow external access (except the cluster node IPs, which GKE automatically whitelists)
  ### example format ###
  master_authorized_networks_config = [{
    cidr_blocks = [{
      cidr_block   = "10.0.0.0/8"
      display_name = "example_network"
    }],
  }]
  EOF

  default = []
}

variable "maintenance_start_time" {
  description = "Time window specified for daily maintenance operations in RFC3339 format"
  default     = "05:00"
}

variable "stub_domains" {
  type        = "map"
  description = "Map of stub domains and their resolvers to forward DNS queries for a certain domain to an external DNS server"
  default     = {}
}

variable "non_masquerade_cidrs" {
  type        = "list"
  description = "List of strings in CIDR notation that specify the IP address ranges that do not use IP masquerading."
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "ip_masq_resync_interval" {
  description = "The interval at which the agent attempts to sync its ConfigMap file from the disk."
  default     = "60s"
}

variable "ip_masq_link_local" {
  description = "Whether to masquerade traffic to the link-local prefix (169.254.0.0/16)."
  default     = "false"
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS - RECOMMENDED DEFAULTS
# These values shouldn't be changed; they're following the best practices defined at https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster
# ---------------------------------------------------------------------------------------------------------------------

variable "enable_kubernetes_dashboard" {
  description = "Whether to enable the Kubernetes Web UI (Dashboard). The Web UI requires a highly privileged security account."
  default     = false
}

variable "enable_legacy_abac" {
  description = "Whether to enable legacy Attribute-Based Access Control (ABAC). RBAC has significant security advantages over ABAC."
  default     = false
}

variable "enable_network_policy" {
  description = "Whether to enable Kubernetes NetworkPolicy on the master, which is required to be enabled to be used on Nodes."
  default     = true
}

variable "basic_auth_username" {
  description = "The username used for basic auth; set both this and `basic_auth_password` to \"\" to disable basic auth."
  default     = ""
}

variable "basic_auth_password" {
  description = "The password used for basic auth; set both this and `basic_auth_username` to \"\" to disable basic auth."
  default     = ""
}

variable "enable_client_certificate_authentication" {
  description = "Whether to enable authentication by x509 certificates. With ABAC disabled, these certificates are effectively useless."
  default     = false
}
