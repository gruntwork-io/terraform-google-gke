# GKE Basic Helm Example

This example shows how to use Terraform to launch a GKE cluster with Helm configured and installed. We achieve this by
utilizing the [k8s-tiller module in the terraform-kubernetes-helm
repository](https://github.com/gruntwork-io/terraform-kubernetes-helm/tree/master/modules/k8s-tiller).
Note that we utilize our `kubergrunt` utility to securely manage TLS certificate key pairs used by Tiller - the server
component of Helm.

## Background

We strongly recommend reading [our guide on Helm](https://github.com/gruntwork-io/kubergrunt/blob/master/HELM_GUIDE.md)
before continuing with this guide for a background on Helm, Tiller, and the security model backing it.


## Overview

In this guide we will walk through the steps necessary to get up and running with deploying Tiller on GKE using this
module. Here are the steps:

1. [Install the necessary tools](#installing-necessary-tools)
1. [Apply the Terraform code](#apply-the-terraform-code)
1. [Verify the deployment](#verify-tiller-deployment)
1. [Granting access to additional roles](#granting-access-to-additional-users)
1. [Upgrading the deployed Tiller instance](#upgrading-deployed-tiller)

## Installing necessary tools

In addition to `terraform`, this guide relies on the `gcloud` and `kubectl` tools to manage the cluster. In addition
we use `kubergrunt` to manage the TLS certificate key pairs for Tiller. You can read more about the decision behind this
approach in [the Appendix](#appendix-a-why-kubergrunt) of this guide.

This means that your system needs to be configured to be able to find `terraform`, `gcloud`, `kubectl`, `kubergrunt`,
and `helm` client utilities on the system `PATH`. Here are the installation guide for each tool:

1. [`gcloud`](https://cloud.google.com/sdk/gcloud/)
1. [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
1. [`terraform`](https://learn.hashicorp.com/terraform/getting-started/install.html)
1. [`helm` client](https://docs.helm.sh/using_helm/#installing-helm)
1. [`kubergrunt`](https://github.com/gruntwork-io/kubergrunt#installation) (Minimum version: v0.3.8)

Make sure the binaries are discoverable in your `PATH` variable. See [this Stack Overflow
post](https://stackoverflow.com/questions/14637979/how-to-permanently-set-path-on-linux-unix) for instructions on
setting up your `PATH` on Unix, and [this
post](https://stackoverflow.com/questions/1618280/where-can-i-set-path-to-make-exe-on-windows) for instructions on
Windows.

## Apply the Terraform Code

Now that all the prerequisite tools are installed, we are ready to deploy the GKE cluster with Tiller installed!

1. If you haven't already, clone this repo:
    - `git clone https://github.com/gruntwork-io/terraform-google-gke.git`
1. Make sure you are in the `gke-basic-tiller` example folder:
    - `cd examples/gke-basic-tiller`
1. Initialize terraform:
    - `terraform init`
1. Check the terraform plan:
    - `terraform plan`
1. Apply the terraform code:
    - `terraform apply`
    - Fill in the required variables based on your needs. <!-- TODO: show example inputs here -->

**Note:** For simplicity this example installs Tiller into the `kube-system` namespace. However in a production
deployment we strongly recommend you segregate the Tiller resources into a separate namespace.

This Terraform code will:

- Deploy a publicly accessible GKE cluster
- Use `kubergrunt` to:
    - Create a new TLS certificate key pair to use as the CA and upload it to Kubernetes as a `Secret` in the
      `kube-system` namespace.
    - Using the generated CA TLS certificate key pair, create a signed TLS certificate key pair to use to identify the
      Tiller server and upload it to Kubernetes as a `Secret` in `kube-system`.

- Create a new `ServiceAccount` for Tiller in the `kube-system` namespace and bind admin permissions to it.
- Deploy Tiller with the following configurations turned on:
    - TLS verification
    - `Secrets` as the storage engine
    - Provisioned in the `kube-system` namespace using the `default` service account.

- Once Tiller is deployed, once again call out to `kubergrunt` to grant access to the provided RBAC entity and configure
  the local helm client to use those credentials:
    - Using the CA TLS certificate key pair, create a signed TLS certificate key pair to use to identify the client.
    - Upload the certificate key pair to the `kube-system`.
    - Grant the RBAC entity access to:
        - Get the client certificate `Secret` (`kubergrunt helm configure` uses this to install the client certificate
          key pair locally)
        - Get and List pods in `kube-system` namespace (the `helm` client uses this to find the Tiller pod)
        - Create a port forward to the Tiller pod (the `helm` client uses this to make requests to the Tiller pod)

    - Install the client certificate key pair to the helm home directory so the client can use it.

At the end of the `terraform apply`, you should now have a working Tiller deployment with your helm client configured to
access it. So let's verify that in the next step!

## Verify Tiller Deployment

To start using `helm` with the configured credentials, you need to specify the following things:

- enable TLS verification
- use TLS credentials to authenticate
- the namespace where Tiller is deployed

These are specified through command line arguments. If everything is configured correctly, you should be able to access
the Tiller that was deployed with the following args:

```
helm --tls --tls-verify --tiller-namespace NAMESPACE_OF_TILLER version
```

If you have access to Tiller, this should return you both the client version and the server version of Helm.

Note that you need to pass the above CLI argument every time you want to use `helm`. This can be cumbersome, so
`kubergrunt` installs an environment file into your helm home directory that you can dot source to set environment
variables that guide `helm` to use those options:

```
. ~/.helm/env
helm version
```

## Appendix A: Why kubergrunt?

This Terraform example is not idiomatic Terraform code in that it relies on an external binary, `kubergrunt` as opposed
to implementing the functionalities using pure Terraform providers. This approach has some noticeable drawbacks:

- You have to install extra tools to use, so it is not a minimal `terraform init && terraform apply`.
- Portability concerns to setup, as there is no guarantee the tools work cross platform. We make every effort to test
  across the major operating systems (Linux, Mac OSX, and Windows), but we can't possibly test every combination and so
  there are bound to be portability issues.
- You don't have the declarative Terraform features that you come to love, such as `plan`, updates through `apply`, and
  `destroy`.

That said, we decided to use this approach because of limitations in the existing providers to implement the
functionalities here in pure Terraform code:

- The [TLS provider](https://www.terraform.io/docs/providers/tls/index.html) stores the certificate key pairs in plain
  text into the Terraform state.
- The Kubernetes Secret resource in the provider [also stores the value in plain text in the Terraform
  state](https://www.terraform.io/docs/providers/kubernetes/r/secret.html).
- The grant and configure workflows are better suited as CLI tools than in Terraform.

Note that we intend to implement a pure Terraform version of this in the near future, but we plan to continue to
maintain the `kubergrunt` approach for folks who are wary of leaking secrets into Terraform state.
