# GKE Regional Private Cluster

This example creates a Regional Private GKE Cluster.

Regional GKE Clusters are high-availability clusters where the cluster master is
spread across multiple GCP zones. During a zonal outage, the Kubernetes control
plane and a subset of your nodes will still be available, provided that at least
1 zone that your cluster is running in is still available.

Regional control planes are accessible even during upgrades.

By default, regional clusters will create nodes across 3 zones in a region. If
you're interested in how nodes are distributed in regional clusters, read the
GCP docs about [balancing across zones](https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-autoscaler#balancing_across_zones).

Nodes in a private cluster are only granted private IP addresses; they're not
accessible from the public internet, as part of a defense-in-depth strategy. A
private cluster can use a GCP HTTP(S) or Network load balancer to accept public
traffic, or an internal load balancer from within your VPC network.

Private clusters use [Private Google Access](https://cloud.google.com/vpc/docs/private-access-options)
to access Google APIs such as Stackdriver, and to pull container images from
Google Container Registry. To use other APIs and services over the internet, you
can use a [`gke-regional-public-cluster`](../gke-regional-public-cluster).
Private clusters are recommended for running most apps and services.

## Limitations

No region shares GPU types across all of their zones; you will need to
explicitly specify the zones your cluster runs in in order to use GPUs.

Node Pools cannot be created in zones without a master cluster; you can update
the zones of your cluster master provided your new zones are within the
region your cluster is present in.

Currently, you cannot use a proxy to reach the cluster master of a regional
cluster through its private IP address.

## How do you run these examples?

1. Install [Terraform](https://www.terraform.io/).
1. Make sure you have Python installed (version 2.x) and in your `PATH`.
1. Open `variables.tf`,  and fill in any required variables that don't have a
default.
1. Run `terraform get`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.
