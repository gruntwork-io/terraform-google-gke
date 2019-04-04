# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "project" {
  description = "The name of the GCP Project where all resources will be launched."
}

variable "region" {
  description = "The Region in which all GCP resources will be launched."
}

variable "iam_user" {
  description = "The name of the IAM user (email address) that will be granted the ability to create Kubernetes roles."
}

variable "tls_subject" {
  description = "The issuer information that contains the identifying information for the Tiller server. Used to generate the TLS certificate keypairs."
  type        = "map"

  # Expects the following keys
  # - common_name
  # - org
  # - org_unit
  # - city
  # - state
  # - country
}

variable "client_tls_subject" {
  description = "The issuer information that contains the identifying information for the helm client of the operator. Used to generate the TLS certificate keypairs."
  type        = "map"

  # Expects the following keys
  # - common_name
  # - org
  # - org_unit
  # - city
  # - state
  # - country
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "cluster_name" {
  description = "The name of the Kubernetes cluster."
  default     = "example-cluster"
}

variable "cluster_service_account_name" {
  description = "The name of the custom service account used for the GKE cluster. This parameter is limited to a maximum of 28 characters."
  default     = "example-cluster-sa"
}

variable "cluster_service_account_description" {
  description = "A description of the custom service account used for the GKE cluster."
  default     = "Example GKE Cluster Service Account managed by Terraform"
}

# TLS algorithm configuration

variable "private_key_algorithm" {
  description = "The name of the algorithm to use for private keys. Must be one of: RSA or ECDSA."
  default     = "ECDSA"
}

variable "private_key_ecdsa_curve" {
  description = "The name of the elliptic curve to use. Should only be used if var.private_key_algorithm is ECDSA. Must be one of P224, P256, P384 or P521."
  default     = "P256"
}

variable "private_key_rsa_bits" {
  description = "The size of the generated RSA key in bits. Should only be used if var.private_key_algorithm is RSA."
  default     = "2048"
}

# Undeploy options

variable "force_undeploy" {
  description = "If true, will remove the Tiller server resources even if there are releases deployed."
  default     = false
}

variable "undeploy_releases" {
  description = "If true, will delete deployed releases from the Tiller instance before undeploying Tiller."
  default     = false
}
