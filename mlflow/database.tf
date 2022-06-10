data "google_project" "project" {
  project_id = var.project
}

resource "random_password" "mlflow_db_password" {
  length  = 32
  special = false
}

resource "random_id" "db_name_suffix" {
  byte_length = 3
}

resource "google_sql_database_instance" "mlflow_cloudsql_instance" {
  project = var.project

  name             = "${var.prefix}-mlflow-${var.env}-${var.region}-${random_id.db_name_suffix.hex}"
  database_version = "MYSQL_8_0"
  region           = var.region

  settings {
    tier              = var.machine_type
    availability_type = var.availability_type

    disk_size       = 10
    disk_autoresize = true

    ip_configuration {
      ipv4_enabled = true
    }

    maintenance_window {
      day          = 7
      hour         = 3
      update_track = "stable"
    }

    backup_configuration {
      enabled            = true
      binary_log_enabled = true
    }

  }
  deletion_protection = false
}

resource "google_sql_database" "mlflow_cloudsql_database" {
  project  = var.project
  name     = "mlflow"
  instance = google_sql_database_instance.mlflow_cloudsql_instance.name
}

resource "google_sql_user" "mlflow_db_user" {
  project    = var.project
  name       = "mlflow"
  instance   = google_sql_database_instance.mlflow_cloudsql_instance.name
  password   = random_password.mlflow_db_password.result
  depends_on = [google_sql_database.mlflow_cloudsql_database]
}

resource "google_secret_manager_secret" "mlflow_db_password_secret" {
  project   = var.project
  secret_id = "${var.prefix}-mlflow-db-password-${var.env}-${var.region}"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "mlflow_db_password_secret" {
  secret      = google_secret_manager_secret.mlflow_db_password_secret.id
  secret_data = random_password.mlflow_db_password.result
}

resource "google_secret_manager_secret_iam_member" "mlflow_db_password_secret_iam" {
  depends_on = [google_secret_manager_secret.mlflow_db_password_secret, google_app_engine_application.mlflow_app]
  secret_id  = google_secret_manager_secret.mlflow_db_password_secret.id
  role       = "roles/secretmanager.secretAccessor"
  for_each = toset(["serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com",
    "serviceAccount:${var.project}@appspot.gserviceaccount.com",
    "serviceAccount:service-${data.google_project.project.number}@gae-api-prod.google.com.iam.gserviceaccount.com"
  ])
  member = each.key
}
