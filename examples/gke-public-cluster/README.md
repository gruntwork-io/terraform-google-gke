# GKE Public Cluster

This example creates a Public GKE Cluster.

With this example, you can create either a regional or zonal cluster. Generally, using a regional cluster is recommended
over a zonal cluster.

Zonal clusters have nodes in a single zones, and will have an outage if that zone has an outage. Regional GKE Clusters
are high-availability clusters where the cluster master is spread across multiple GCP zones. During a zonal outage, the
Kubernetes control plane and a subset of your nodes will still be available, provided that at least 1 zone that your
cluster is running in is still available. Regional control planes remain accessible during upgrades versus zonal control
planes which do not.

By default, regional clusters will create nodes across 3 zones in a region. If you're interested in how nodes are
distributed in regional clusters, read the GCP docs about [balancing across zones](https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-autoscaler#balancing_across_zones).

Nodes in a public cluster are accessible from the public internet; try using a private cluster such as in
[`gke-private-cluster`](../gke-private-cluster) to limit access to/from your nodes. Private clusters are recommended for
running most apps and services.

## Limitations

When using a regional cluster, no region shares GPU types across all of their zones; you will need to explicitly specify
the zones your cluster's node pools run in in order to use GPUs.

Node Pools cannot be created in zones without a master cluster; you can update the zones of your cluster master provided
your new zones are within the region your cluster is present in.

## How do you run these examples?

1. Install [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html) v0.10.3 or later.
1. Open `variables.tf`,  and fill in any required variables that don't have a
default.
1. Run `terraform get`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.
