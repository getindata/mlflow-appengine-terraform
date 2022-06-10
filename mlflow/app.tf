data "google_secret_manager_secret_version" "oauth_client_id" {
  secret = var.secret_for_oauth_client_id
}

data "google_secret_manager_secret_version" "oauth_client_secret" {
  secret = var.secret_for_oauth_client_secret
}

locals {
  gae_sa = [
    "serviceAccount:service-${data.google_project.project.number}@gae-api-prod.google.com.iam.gserviceaccount.com",
    "serviceAccount:${var.project}@appspot.gserviceaccount.com"
  ]

  gae_roles = [
    "roles/compute.networkUser",
    "roles/storage.objectViewer",
    "roles/logging.logWriter",
    "roles/cloudsql.client",
    "roles/monitoring.metricWriter",
    "roles/artifactregistry.reader"
  ]

  gae_sa_iam = distinct(flatten([
    for sa in local.gae_sa : [
      for role in local.gae_roles : {
        sa   = sa
        role = role
      }
    ]
  ]))
}

resource "google_app_engine_application" "mlflow_app" {
  project     = var.project
  location_id = var.app_engine_region
  iap {
    enabled              = true
    oauth2_client_id     = data.google_secret_manager_secret_version.oauth_client_id.secret_data
    oauth2_client_secret = data.google_secret_manager_secret_version.oauth_client_secret.secret_data
  }
}

resource "google_project_iam_member" "mlflow_gae_iam" {
  depends_on = [google_app_engine_application.mlflow_app]
  for_each   = { for entry in local.gae_sa_iam : "${entry.sa}.${entry.role}" => entry }
  project    = var.project
  role       = each.value.role
  member     = each.value.sa
}


resource "google_app_engine_flexible_app_version" "mlflow_default_app" {
  project    = var.project
  service    = "default"
  version_id = "v1"
  runtime    = "custom"

  deployment {
    container {
      image = var.docker_image
    }
  }

  liveness_check {
    path = "/"
  }

  readiness_check {
    path = "/"
  }

  beta_settings = {
    cloud_sql_instances = google_sql_database_instance.mlflow_cloudsql_instance.connection_name
  }

  env_variables = {
    GCP_PROJECT                 = var.project
    DB_PASSWORD_SECRET_NAME     = google_secret_manager_secret.mlflow_db_password_secret.secret_id,
    DB_USERNAME                 = google_sql_user.mlflow_db_user.name
    DB_NAME                     = google_sql_database.mlflow_cloudsql_database.name
    DB_INSTANCE_CONNECTION_NAME = google_sql_database_instance.mlflow_cloudsql_instance.connection_name
    GCS_BACKEND                 = google_storage_bucket.mlflow_artifacts_bucket.url
  }

  automatic_scaling {
    cpu_utilization {
      target_utilization = 0.75
    }

    min_total_instances = 1
    max_total_instances = 4
  }

  resources {
    cpu       = 1
    memory_gb = 2
  }

  delete_service_on_destroy = true
  noop_on_destroy           = false

  timeouts {
    create = "20m"
  }

  depends_on = [
    google_secret_manager_secret_iam_member.mlflow_db_password_secret_iam,
    google_project_iam_member.mlflow_gae_iam
  ]

  inbound_services = []
}
