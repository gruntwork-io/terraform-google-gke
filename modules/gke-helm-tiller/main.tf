provider "helm" {
  tiller_image   = "gcr.io/kubernetes-helm/tiller:latest"
  install_tiller = true

  kubernetes {
    host                   = "${data.template_file.gke_host_endpoint.rendered}"
    token                  = "${data.template_file.access_token.rendered}"
    client_certificate     = "${data.template_file.client_certificate.rendered}"
    client_key             = "${data.template_file.client_key.rendered}"
    cluster_ca_certificate = "${data.template_file.cluster_ca_certificate.rendered}"
  }
}

# Workaround for Terraform limitation where you cannot directly set a depends on directive or interpolate from resources
# in the provider config.
# Specifically, Terraform requires all information for the Terraform provider config to be available at plan time,
# meaning there can be no computed resources. We work around this limitation by creating a template_file data source
# that does the computation.
# See https://github.com/hashicorp/terraform/issues/2430 for more details
data "template_file" "gke_host_endpoint" {
  template = "${var.gke_host_endpoint}"
}

data "template_file" "access_token" {
  template = "${var.access_token}"
}

data "template_file" "client_certificate" {
  template = "${var.client_certificate}"
}

data "template_file" "client_key" {
  template = "${var.client_key}"
}

data "template_file" "cluster_ca_certificate" {
  template = "${var.cluster_ca_certificate}"
}


