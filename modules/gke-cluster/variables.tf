# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These parameters must be supplied when consuming this module.
# ---------------------------------------------------------------------------------------------------------------------

variable "project" {
  description = "The project ID to host the cluster in"
}

variable "location" {
  description = "The location (region or zone) to host the cluster in"
}

variable "name" {
  description = "The name of the cluster"
}

variable "network" {
  description = "A reference (self link) to the VPC network to host the cluster in"
}

variable "subnetwork" {
  description = "A reference (self link) to the subnetwork to host the cluster in"
}

variable "cluster_secondary_range_name" {
  description = "The name of the secondary range within the subnetwork for the cluster to use"
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
  description = "The logging service that the cluster should write logs to. Available options include logging.googleapis.com/kubernetes, logging.googleapis.com (legacy), and none"
  default     = "logging.googleapis.com/kubernetes"
}

variable "monitoring_service" {
  description = "The monitoring service that the cluster should write metrics to. Automatically send metrics from pods in the cluster to the Stackdriver Monitoring API. VM metrics will be collected by Google Compute Engine regardless of this setting. Available options include monitoring.googleapis.com/kubernetes, monitoring.googleapis.com (legacy), and none"
  default     = "monitoring.googleapis.com/kubernetes"
}

variable "horizontal_pod_autoscaling" {
  description = "Whether to enable the horizontal pod autoscaling addon"
  default     = true
}

variable "http_load_balancing" {
  description = "Whether to enable the http (L7) load balancing addon"
  default     = true
}

variable "enable_private_nodes" {
  description = "Control whether nodes have internal IP addresses only. If enabled, all nodes are given only RFC 1918 private addresses and communicate with the master via private networking."
  default     = "false"
}

variable "disable_public_endpoint" {
  description = "Control whether the master's internal IP address is used as the cluster endpoint. If set to 'true', the master can only be accessed from internal IP addresses."
  default     = "false"
}

variable "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation to use for the hosted master network. This range will be used for assigning internal IP addresses to the master or set of masters, as well as the ILB VIP. This range must not overlap with any other ranges in use within the cluster's network."
  default     = ""
}

variable "network_project" {
  description = "The project ID of the shared VPC's host (for shared vpc support)"
  default     = ""
}

variable "master_authorized_networks_config" {
  type = list(string)

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
  default = "05:00"
}

variable "stub_domains" {
  type = map(string)
  description = "Map of stub domains and their resolvers to forward DNS queries for a certain domain to an external DNS server"
  default = {}
}

variable "non_masquerade_cidrs" {
  type = list(string)
  description = "List of strings in CIDR notation that specify the IP address ranges that do not use IP masquerading."
  default = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "ip_masq_resync_interval" {
  description = "The interval at which the agent attempts to sync its ConfigMap file from the disk."
  default = "60s"
}

variable "ip_masq_link_local" {
  description = "Whether to masquerade traffic to the link-local prefix (169.254.0.0/16)."
  default = "false"
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS - RECOMMENDED DEFAULTS
# These values shouldn't be changed; they're following the best practices defined at https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster
# ---------------------------------------------------------------------------------------------------------------------

variable "enable_kubernetes_dashboard" {
  description = "Whether to enable the Kubernetes Web UI (Dashboard). The Web UI requires a highly privileged security account."
  default = false
}

variable "enable_legacy_abac" {
  description = "Whether to enable legacy Attribute-Based Access Control (ABAC). RBAC has significant security advantages over ABAC."
  default = false
}

variable "enable_network_policy" {
  description = "Whether to enable Kubernetes NetworkPolicy on the master, which is required to be enabled to be used on Nodes."
  default = true
}

variable "basic_auth_username" {
  description = "The username used for basic auth; set both this and `basic_auth_password` to \"\" to disable basic auth."
  default = ""
}

variable "basic_auth_password" {
  description = "The password used for basic auth; set both this and `basic_auth_username` to \"\" to disable basic auth."
  default = ""
}

variable "enable_client_certificate_authentication" {
  description = "Whether to enable authentication by x509 certificates. With ABAC disabled, these certificates are effectively useless."
  default = false
}
