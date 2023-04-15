resource "google_storage_bucket" "mlflow_artifacts_bucket" {
  name                        = "${var.prefix}-mlflow-${var.env}-${var.region}"
  location                    = substr(var.region, 0, 2) == "eu" ? "EU" : "US"
  storage_class               = "MULTI_REGIONAL"
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "mlflow_artifacts_bucket_iam" {
//  depends_on = [google_app_engine_application.mlflow_app]
  bucket     = google_storage_bucket.mlflow_artifacts_bucket.name
  role       = "roles/storage.objectAdmin"
  for_each   = toset(["serviceAccount:${var.project}@appspot.gserviceaccount.com", "serviceAccount:service-${data.google_project.project.number}@gae-api-prod.google.com.iam.gserviceaccount.com"])
  member     = each.key
}

