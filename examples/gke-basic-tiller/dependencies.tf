# ---------------------------------------------------------------------------------------------------------------------
# INTERPOLATE AND CONSTRUCT KUBERGRUNT HELM DEPLOY COMMAND ARGUMENTS
# ---------------------------------------------------------------------------------------------------------------------

locals {
  tls_config           = "--tls-private-key-algorithm ${var.private_key_algorithm} ${local.tls_algorithm_config} --tls-common-name ${lookup(var.tls_subject, "common_name")} --tls-org ${lookup(var.tls_subject, "org")} ${local.tls_org_unit} ${local.tls_city} ${local.tls_state} ${local.tls_country}"
  tls_algorithm_config = "${var.private_key_algorithm == "ECDSA" ? "--tls-private-key-ecdsa-curve ${var.private_key_ecdsa_curve}" : "--tls-private-key-rsa-bits ${var.private_key_rsa_bits}"}"
  tls_org_unit         = "${lookup(var.tls_subject, "org_unit", "") != "" ? "--tls-org-unit ${lookup(var.tls_subject, "org_unit", "")}" : ""}"
  tls_city             = "${lookup(var.tls_subject, "city", "")     != "" ? "--tls-city ${lookup(var.tls_subject, "city", "")}"         : ""}"
  tls_state            = "${lookup(var.tls_subject, "state", "")    != "" ? "--tls-state ${lookup(var.tls_subject, "state", "")}"       : ""}"
  tls_country          = "${lookup(var.tls_subject, "country", "")  != "" ? "--tls-country ${lookup(var.tls_subject, "country", "")}"   : ""}"

  client_tls_config   = "--client-tls-common-name ${lookup(var.client_tls_subject, "common_name")} --client-tls-org ${lookup(var.client_tls_subject, "org")} ${local.client_tls_org_unit} ${local.client_tls_city} ${local.client_tls_state} ${local.client_tls_country}"
  client_tls_org_unit = "${lookup(var.client_tls_subject, "org_unit", "") != "" ? "--client-tls-org-unit ${lookup(var.client_tls_subject, "org_unit", "")}" : ""}"
  client_tls_city     = "${lookup(var.client_tls_subject, "city", "")     != "" ? "--client-tls-city ${lookup(var.client_tls_subject, "city", "")}"         : ""}"
  client_tls_state    = "${lookup(var.client_tls_subject, "state", "")    != "" ? "--client-tls-state ${lookup(var.client_tls_subject, "state", "")}"       : ""}"
  client_tls_country  = "${lookup(var.client_tls_subject, "country", "")  != "" ? "--client-tls-country ${lookup(var.client_tls_subject, "country", "")}"   : ""}"

  undeploy_args = "${var.force_undeploy ? "--force" : ""} ${var.undeploy_releases ? "--undeploy-releases" : ""}"
}
