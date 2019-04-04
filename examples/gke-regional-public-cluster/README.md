# GKE Regional Public Cluster

This example creates a Regional Public GKE Cluster.

Regional GKE Clusters are high-availability clusters where the cluster master is
spread across multiple GCP zones. During a zonal outage, the Kubernetes control
plane and a subset of your nodes will still be available, provided that at least
1 zone that your cluster is running in is still available.

Regional control planes are accessible even during upgrades.

By default, regional clusters will create nodes across 3 zones in a region. If
you're interested in how nodes are distributed in regional clusters, read the
GCP docs about [balancing across zones](https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-autoscaler#balancing_across_zones).

The example follows best-practices and runs nodes using a custom service account to follow the principle of
least privilege. However you will need to ensure that the Identity and Access Management (IAM) API has been
enabled for the given project. This can be enabled in the Google API Console:
https://console.developers.google.com/apis/api/iam.googleapis.com/overview. See "Why use Custom Service
Accounts?" for more information.

**Important:** Nodes in a public cluster are accessible from the public internet; try using a
private cluster such as in [`gke-regional-private-cluster`](../gke-regional-private-cluster)
to limit access to/from your nodes. Private clusters are recommended for running
most apps and services.

## Why use Custom Service Accounts?

Each node in a GKE cluster is a Compute Engine instance. Therefore, applications running on a GKE cluster
by default inherit the scopes of the Compute Engine instances to which they are deployed.

Google Cloud Platform (GCP) automatically creates a service account named "Compute Engine default service account" and GKE
associates it with the nodes it creates. Depending on how your project is configured, the default service account may
or may not have permissions to use other GCP APIs. GKE also assigns some limited access scopes to compute
instances. Updating the default service account's permissions or assigning more access scopes to compute instances is
not the recommended way to authenticate to other Cloud Platform services from Pods running on GKE.

The recommended way to authenticate to GCP services from applications running on GKE is to create
your own service accounts. Ideally you must create a new service account for each application that makes requests to
Cloud Platform APIs.

## Limitations

No region shares GPU types across all of their zones; you will need to
explicitly specify the zones your cluster runs in in order to use GPUs.

Node Pools cannot be created in zones without a master cluster; you can update
the zones of your cluster master provided your new zones are within the
region your cluster is present in.

## How do you run these examples?

1. Install [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html) v0.10.3 or later.
1. Open `variables.tf`, and fill in any required variables that don't have a
   default.
1. Run `terraform get`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.
