# GKE Helm & Tiller Module

The GKE Helm & Tiller module is used to add Tiller to your GKE cluster in order
to enable making releases using helm.

## How do you use this module?

* See the [root README](/README.md) for instructions on using Terraform modules.
* See the [examples](/examples) folder for example usage.
* See [variables.tf](./variables.tf) for all the variables you can set on this module.
* See [outputs.tf](./outputs.tf) for all the variables that are outputed by this module.

## What is Helm? 

Helm is an alternative to `kubectl` used to make deployments on Kubernetes.

## What is Tiller

Tiller is a cluster-side server that's necessary for Helm to function. Tiller
runs as a sidecar service.
