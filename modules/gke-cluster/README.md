# GKE Cluster Module

The GKE Cluster module is used to administer the [cluster master](https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-architecture)
for a [Google Kubernetes Engine (GKE) Cluster](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-admin-overview).

The cluster master is the "control plane" of the cluster; for example, it runs
the Kubernetes API used by `kubectl`. Worker machines are configured by
attaching [GKE node pools](https://cloud.google.com/kubernetes-engine/docs/concepts/node-pools)
to the cluster module.

## How do you use this module?

* See the [root README](/README.md) for instructions on using Terraform modules.
* See the [examples](/examples) folder for example usage.
* See [variables.tf](./variables.tf) for all the variables you can set on this module.
* See [outputs.tf](./outputs.tf) for all the variables that are outputed by this module.

## What is a GKE Cluster?

The GKE Cluster, or "cluster master", runs the Kubernetes control plane
processes including the Kubernetes API server, scheduler, and core resource
controllers.

The master is the unified endpoint for your cluster; it's the "hub" through
which all other components such as nodes interact. Users can interact with the
cluster via Kubernetes API calls, such as by using `kubectl`. The GKE cluster
is responsible for running workloads on nodes, as well as scaling/upgrading
nodes.

## How do I attach worker machines using a GKE node pool?

A "[node](https://kubernetes.io/docs/concepts/architecture/nodes/)" is
a worker machine in Kubernetes; in GKE, nodes are provisioned as
[Google Compute Engine VM instances](https://cloud.google.com/compute/docs/instances/).

[GKE Node Pools](https://cloud.google.com/kubernetes-engine/docs/concepts/node-pools)
are a group of nodes who share the same configuration, defined as a [NodeConfig](https://cloud.google.com/kubernetes-engine/docs/reference/rest/v1/NodeConfig).
Node pools also control the autoscaling of their nodes, and autoscaling
configuration is done inline, alongside the node config definition. A GKE
Cluster can have multiple node pools defined.

Node pools are configured directly with the
[`google_container_node_pool`](https://www.terraform.io/docs/providers/google/r/container_node_pool.html)
Terraform resource by providing a reference to the cluster you configured with
this module as the `cluster` field.

## What VPC network will this cluster use?

You must explicitly specify the network and subnetwork of your GKE cluster using
the `network` and `subnetwork` fields; this module will not implicitly use the
`default` network with an automatically generated subnetwork.

The modules in the [`terraform-google-network`](https://github.com/gruntwork-io/terraform-google-network)
Gruntwork module are a useful tool for configuring your VPC network and 
subnetworks in GCP.

## What IAM roles does this module configure? (unimplemented)

Given a service account, this module will enable the following IAM roles:

* roles/compute.viewer
* roles/container.clusterAdmin
* roles/container.developer
* roles/iam.serviceAccountUser

## What services does this module enable on my project? (unimplemented)

This module will ensure the following services are active on your project:

* Compute Engine API - compute.googleapis.com
* Kubernetes Engine API - container.googleapis.com
