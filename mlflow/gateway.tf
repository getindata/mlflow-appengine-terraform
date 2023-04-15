resource "google_project_service" "project" {
  project = var.project
  service = "apigateway.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_dependent_services = true
}


resource "google_api_gateway_api" "api" {
  depends_on = [google_project_service.project]
  project = var.project
  provider = google-beta
  api_id = "${var.prefix}-mlflow-${var.env}"
}

data "template_file" "openapi" {
  template = "${file("resources/openapi-gcp.yml.tftpl")}"
  vars = {
    app_url = local.app_url
    env = var.env
    iap_client_id = data.google_secret_manager_secret_version.oauth_client_id.secret_data
    prefix = var.prefix
  }
}

resource "google_api_gateway_api_config" "api_cfg" {
  provider = google-beta
  project = var.project
  api = google_api_gateway_api.api.api_id
  api_config_id = "api-config"

  openapi_documents {
    document {
      path = "spec.yaml"
      contents = base64encode(data.template_file.openapi.rendered)
    }
  }
  lifecycle {
    create_before_destroy = false
  }
}

resource "google_api_gateway_gateway" "api_gw" {
  provider = google-beta
  project = var.project
  region = var.region
  api_config = google_api_gateway_api_config.api_cfg.id
  gateway_id = "${var.prefix}-mlflow-gateway-${var.env}"
  lifecycle {
    create_before_destroy = false
  }
}