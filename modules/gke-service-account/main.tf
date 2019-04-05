resource "google_service_account" "service_account" {
  project      = "${var.project}"
  account_id   = "${var.name}"
  display_name = "${var.description}"
}

# Grant the service account the minimum necessary roles and permissions in order to run the GKE cluster
resource "google_project_iam_member" "service_account-log_writer" {
  project = "${google_service_account.service_account.project}"
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "service_account-metric_writer" {
  project = "${google_project_iam_member.service_account-log_writer.project}"
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "service_account-monitoring_viewer" {
  project = "${google_project_iam_member.service_account-metric_writer.project}"
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}
