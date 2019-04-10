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

## What is a VPC-native cluster?

A VPC-native cluster is a GKE Cluster that uses [alias IP ranges](https://cloud.google.com/vpc/docs/alias-ip), in that
it allocates IP addresses from a block known to GCP. When using an alias range, pod addresses are natively routable
within GCP, and VPC networks can ensure that the IP range the cluster uses is reserved.

While using a secondary IP range is recommended [in order to to separate cluster master and pod IPs](https://github.com/gruntwork-io/terraform-google-network/tree/master/modules/vpc-network#how-is-a-secondary-range-connected-to-an-alias-ip-range),
when using a network in the same project as your GKE cluster you can specify a blank range name to draw alias IPs from your subnetwork's primary IP range. If
using a shared VPC network (a network from another GCP project) using an explicit secondary range is required.

See [considerations for cluster sizing](https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips#cluster_sizing)
for more information on sizing secondary ranges for your VPC-native cluster.

## What is a private cluster?

In a private cluster, the nodes have internal IP addresses only, which ensures that their workloads are isolated from the public Internet. 
Private nodes do not have outbound Internet access, but Private Google Access provides private nodes and their workloads with 
limited outbound access to Google Cloud Platform APIs and services over Google's private network.

If you want your cluster nodes to be able to access the Internet, for example pull images from external container registries,
you will have to set up [Cloud NAT](https://cloud.google.com/nat/docs/overview). 
See [Example GKE Setup](https://cloud.google.com/nat/docs/gke-example) for further information.

You can create a private cluster by setting `enable_private_nodes` to `true`. Note that with a private cluster, setting
the master CIDR range with `master_ipv4_cidr_block` is also required.

### How do I control access to the cluster master?

In a private cluster, the master has two endpoints:

* **Private endpoint:** This is the internal IP address of the master, behind an internal load balancer in the master's 
VPC network. Nodes communicate with the master using the private endpoint. Any VM in your VPC network, and in the same 
region as your private cluster, can use the private endpoint.

* **Public endpoint:** This is the external IP address of the master. You can disable access to the public endpoint by setting
`enable_private_endpoint` to `true`.

You can relax the restrictions by authorizing certain address ranges to access the endpoints with the input variable
`master_authorized_networks_config`.
 
### Private cluster restrictions and limitations

Private clusters have the following restrictions and limitations:

* The size of the RFC 1918 block for the cluster master must be /28.
* The nodes in a private cluster must run Kubernetes version 1.8.14-gke.0 or later.
* You cannot convert an existing, non-private cluster to a private cluster.
* Each private cluster you create uses a unique VPC Network Peering.
* Deleting the VPC peering between the cluster master and the cluster nodes, deleting the firewall rules that allow 
ingress traffic from the cluster master to nodes on port 10250, or deleting the default route to the default 
Internet gateway, causes a private cluster to stop functioning.

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
