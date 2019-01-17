# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator
# ---------------------------------------------------------------------------------------------------------------------

variable "gke_host_endpoint" {
  description = "The endpoint of your GKE cluster"
}

variable "access_token" {
  description = "The GCP access token used by your Google provider"
}

variable "client_certificate" {
  description = "TODO"
}

variable "client_key" {
  description = "TODO"
}

variable "cluster_ca_certificate" {
  description = "TODO"
}
