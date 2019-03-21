# GKE Custom Service Account

This example demonstrates how to use a custom, user provided service account

## Why use Service Accounts?

Each node in a container cluster is a Compute Engine instance. Therefore, applications running on a container cluster by
default inherit the scopes of the Compute Engine instances to which they are deployed. 

Google Cloud Platform automatically creates a service account named "Compute Engine default service account" and GKE
associates it with the nodes it creates. Depending on how your project is configured, the default service account may or
may not have permissions to use other Cloud Platform APIs. GKE also assigns some limited access scopes to compute instances.
Updating the default service account's permissions or assigning more access scopes to compute instances is not the
recommended way to authenticate to other Cloud Platform services from Pods running on GKE.

The recommended way to authenticate to Google Cloud Platform services from applications running on GKE is to create your
own service accounts. Ideally you must create a new service account for each application that makes requests to Cloud
Platform APIs.

## How do you run these examples?

1. Install [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html) v0.10.3 or later.
1. Open `variables.tf`,  and fill in any required variables that don't have a
default.
1. Run `terraform get`.
1. Run `terraform plan`.
1. If the plan looks good, run `terraform apply`.
