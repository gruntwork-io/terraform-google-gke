# GKE Private Cluster

This example creates a Private GKE Cluster.

With this example, you can create either a regional or zonal cluster. Generally, using a regional cluster is recommended
over a zonal cluster.

Zonal clusters have nodes in a single zones, and will have an outage if that zone has an outage. Regional GKE Clusters
are high-availability clusters where the cluster master is spread across multiple GCP zones. During a zonal outage, the
Kubernetes control plane and a subset of your nodes will still be available, provided that at least 1 zone that your
cluster is running in is still available. Regional control planes remain accessible during upgrades versus zonal control
planes which do not.

By default, regional clusters will create nodes across 3 zones in a region. If you're interested in how nodes are
distributed in regional clusters, read the GCP docs about [balancing across zones](https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-autoscaler#balancing_across_zones).

Nodes in a private cluster are only granted private IP addresses; they're not accessible from the public internet, as
part of a defense-in-depth strategy. A private cluster can use a GCP HTTP(S) or Network load balancer to accept public
traffic, or an internal load balancer from within your VPC network.

Private clusters use [Private Google Access](https://cloud.google.com/vpc/docs/private-access-options) to access Google
APIs such as Stackdriver, and to pull container images from Google Container Registry. To use other APIs and services
over the internet, you can use a [`gke-public-cluster`](../gke-public-cluster). Private clusters are
recommended for running most apps and services.

## Limitations

When using a regional cluster, no region shares GPU types across all of their zones; you will need to explicitly specify
the zones your cluster's node pools run in in order to use GPUs.

Node Pools cannot be created in zones without a master cluster; you can update the zones of your cluster master provided
your new zones are within the region your cluster is present in.

<!-- TODO(rileykarson): Clarify what this means when we find out- this is pulled
from the GKE docs. -->
Currently, you cannot use a proxy to reach the cluster master of a regional cluster through its private IP address.

## How do you run these examples?

1. Install [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html) v0.14.8 or later.
1. Open `variables.tf` and fill in any required variables that don't have a default.
1. Run `terraform get`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.

#### Optional: Deploy a sample application

1. To setup `kubectl` to access the deployed cluster, run `gcloud beta container clusters get-credentials $CLUSTER_NAME 
--region $REGION --project $PROJECT`, where `CLUSTER_NAME`, `REGION` and `PROJECT` correspond to what you set for the 
input variables.
1. Run `kubectl apply -f example-app/nginx.yml` to create a deployment in your cluster.
1. Run `kubectl get pods` to view the pod status and check that it is ready.
1. Run `kubectl get deployment` to view the deployment status.
1. Run `kubectl port-forward deployment/nginx 8080:80`

Now you should be able to access your `nginx` deployment on http://localhost:8080

#### Destroy the created resources

1. If you deployed the sample application, run `kubectl delete -f example-app/nginx.yml`.
1. Run `terraform destroy`.
