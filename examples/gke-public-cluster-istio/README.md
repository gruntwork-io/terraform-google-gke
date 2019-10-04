# GKE Public Cluster

This example creates a Public GKE Cluster with istio. 

Full explatantion can be found in [gke-public-cluster](https://github.com/gruntwork-io/terraform-google-gke/blob/master/examples/gke-public-cluster/README.md)

## Istio

Istio on GKE is still in pre-release stage. For detailed documentation please reach [this site](https://cloud.google.com/istio/docs/istio-on-gke/overview)

### Enable

To enable istio please setup `var.enable_istio = true`. By default istio is disabled.

### Istio addon

Please be aware that enabling istio on the cluster disables all cross pod network access by default. Network policies for GKE should be configured separetly.
