# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module uses terraform 0.12 syntax and features that are available only since version 0.12.6, however
# we now depend on a bug fix released in 0.12.7.
# ----------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 0.12.7"
}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE SERVICE ACCOUNT
# ----------------------------------------------------------------------------------------------------------------------
resource "google_service_account" "service_account" {
  project      = var.project
  account_id   = var.name
  display_name = var.description
}

# ----------------------------------------------------------------------------------------------------------------------
# ADD ROLES TO SERVICE ACCOUNT
# Grant the service account the minimum necessary roles and permissions in order to run the GKE cluster
# plus any other roles added through the 'service_account_roles' variable
# ----------------------------------------------------------------------------------------------------------------------
locals {
  all_service_account_roles = concat(var.service_account_roles, [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer"
  ])
}

resource "google_project_iam_member" "service_account-roles" {
  for_each = toset(local.all_service_account_roles)

  project = var.project
  role    = each.value
  member  = "serviceAccount:${google_service_account.service_account.email}"
}
