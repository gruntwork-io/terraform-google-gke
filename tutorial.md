# Deploying a production-grade Helm release on GKE with Terraform

## Introduction

<walkthrough-author name="rileykarson@google.com" analyticsId="UA-125550242-1" tutorialName="gruntwork_google_gke" repositoryUrl="https://github.com/gruntwork-io/terraform-google-gke"></walkthrough-author>

To get started with deploying this module, let us know what GCP project you'd like to use.

<walkthrough-project-billing-setup></walkthrough-project-billing-setup>

This example provisions real GCP resources, so anything you create in this session will be billed against that project.

## Setup

To use {{project-id}} with the module, you can click the Cloud Shell icon below to copy the command
to your shell, and then run it from the shell by pressing Enter/Return. Terraform will pick up
the project name from the environment variable provided. Alternatively, you can enter it in `variables.tf` by hand.

```bash
export TF_VAR_project={{project-id}}
```

Next, install [`kubergrunt`](https://github.com/gruntwork-io/kubergrunt), a collection of helper scripts:

```bash
./install_kubergrunt.sh
```

After that, run the following to prepare the Terraform providers.

```bash
terraform init
```

And then apply the config.

```bash
terraform apply
```

Terraform will show you what it plans to do, and prompt you to accept. Type "yes" to accept the plan.

```bash
yes
```

Terraform will deploy the GKE cluster and configure Helm's server component, Tiller, on it.

## Releasing a Chart

Now that the cluster has been provisioned and Tiller installed, you can install a Helm chart.

```bash
helm --tls --tls-verify --tiller-namespace kube-system install stable/nginx-ingress
```

With that command, you've instructed Helm to securely deploy the
`stable/nginx-ingress` chart into the cluster's tiller instance, which will then
apply the chart.

After waiting a minute or two for that to be deployed, you can run

```bash
kubectl get services
```

And pull the `EXTERNAL-IP` value from the service with the `nginx-ingress-controller` suffix.

Using that value, you can visit the `/healthz` endpoint to see that nginx is returning
a 200 status. For example, using curl;

```bash
curl -v {{YOUR-EXTERNAL-IP}}/healthz
```

## Cleanup

When done, run the following to remove the resources Terraform provisioned:

```bash
terraform destroy
```
```bash
yes
```
