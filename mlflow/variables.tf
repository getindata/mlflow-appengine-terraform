variable "project" {
}

variable "env" {
}

variable "prefix" {
}

variable "region" {
}

variable "app_engine_region" {
}

variable "docker_image" {

}

variable "machine_type" {
  type    = string
  default = "db-g1-small"
}

variable "secret_for_oauth_client_secret" {
  type = string
}

variable "secret_for_oauth_client_id" {
  type = string
}

variable "availability_type" {
  type    = string
  default = "ZONAL"
}

variable "snowflake_service_account" {
  type = string
}

