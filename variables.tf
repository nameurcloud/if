variable "project_id" {}
variable "region" {}
variable "service_name" {}
variable "container_image" {}
variable "service_name_b" {}
variable "container_image_b" {}
variable "enabled_apis" {
  type    = list(string)
  default = [
    "run.googleapis.com",
    "iam.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ]
}


