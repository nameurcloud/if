provider "google" {
  project = var.project_id
  region  = var.region
}


# Backend Service Account
resource "google_service_account" "backend_sa" {
  account_id   = "backend-service-account"
  display_name = "Backend Service Account"
  
}

# Frontend Service Account
resource "google_service_account" "frontend_sa" {
  account_id   = "frontend-service-account"
  display_name = "Frontend Service Account"
  
}

# API Service Account
resource "google_service_account" "api_sa" {
  account_id   = "api-service-account"
  display_name = "api Service Account"
  
}

# Backend Cloud Run (private)
resource "google_cloud_run_v2_service" "cloud_run_backend" {
  name     = var.service_name_b
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false
  custom_audiences = ["be.nameurcloud.com", "https://be.nameurcloud.com","api.nameurcloud.com", "https://api.nameurcloud.com" ]

  template {
    service_account = google_service_account.backend_sa.email

    containers {
      image = var.container_image_b
       env {
          name  = "JWT_SECRET"
          value = "dummyvalue"
        }

        env {
          name  = "MONGO_URI"
          value = "dummyvalue"
        }
    }
    
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }

  labels = {
    "managed-by" = "terraform"
  }

   lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      template[0].containers[0].env
    ]
  }
}


# API Cloud Run (Public)
resource "google_cloud_run_service" "cloud_run_api" {
  name     = var.service_name_api
  location = var.region


  template {
    spec {
    service_account_name = google_service_account.api_sa.email

    containers {
      image = var.container_image_api
       env {
          name  = "JWT_SECRET"
          value = "dummyvalue"
        }

        env {
          name  = "MONGO_URI"
          value = "dummyvalue"
        }

        env{
          name = "env"
          value = "dummyvalue"
        }
        env {
          name = "BACKEND_URL"
          value = "dummyvalue"
        }
    }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

   lifecycle {
    ignore_changes = [
      template[0].spec[0].containers[0].image
    ]
  }
}


# Frontend Cloud Run (public)
resource "google_cloud_run_service" "cloud_run_frontend" {
  name     = var.service_name
  location = var.region

  template {
    spec {
      service_account_name = google_service_account.frontend_sa.email

      containers {
        image = var.container_image
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
    lifecycle {
    ignore_changes = [
      template[0].spec[0].containers[0].image
    ]
  }
}

# Allow public access to frontend
resource "google_cloud_run_service_iam_member" "cloud_run_public_access_frontend" {
  location = var.region
  project  = var.project_id
  service  = google_cloud_run_service.cloud_run_frontend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Allow public access to API
resource "google_cloud_run_service_iam_member" "cloud_run_public_access_api" {
  location = var.region
  project  = var.project_id
  service  = google_cloud_run_service.cloud_run_api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Allow frontend service account to invoke backend Cloud Run
resource "google_cloud_run_service_iam_member" "frontend_can_invoke_backend" {
  location = var.region
  project  = var.project_id
  service  = google_cloud_run_v2_service.cloud_run_backend.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.frontend_sa.email}"
}

# Allow API service account to invoke backend Cloud Run
resource "google_cloud_run_service_iam_member" "api_can_invoke_backend" {
  location = var.region
  project  = var.project_id
  service  = google_cloud_run_v2_service.cloud_run_backend.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.api_sa.email}"
  
}


# Optional: Grant logging/monitoring roles to the service accounts (recommended)
resource "google_project_iam_member" "frontend_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.frontend_sa.email}"
  
}

resource "google_project_iam_member" "backend_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.backend_sa.email}"
  
}

resource "google_project_iam_member" "api_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.api_sa.email}"
  
}

# Domain mapping for frontend
resource "google_cloud_run_domain_mapping" "connect_to_www_domain_frontend" {
  name     = "www.nameurcloud.com"
  location = var.region

  metadata {
    namespace = var.project_id
  }

  spec {
    route_name = google_cloud_run_service.cloud_run_frontend.name
  }
  
}

resource "google_cloud_run_domain_mapping" "connect_to_root_domain_frontend" {
  name     = "nameurcloud.com"
  location = var.region

  metadata {
    namespace = var.project_id
  }

  spec {
    route_name = google_cloud_run_service.cloud_run_frontend.name
  }
  
}

resource "google_cloud_run_domain_mapping" "backend_domain_mapping" {
  name     = "be.nameurcloud.com"
  location = var.region

  metadata {
    namespace = var.project_id
  }

  spec {
    route_name = google_cloud_run_v2_service.cloud_run_backend.name
  }
  
}

resource "google_cloud_run_domain_mapping" "api_domain_mapping" {
  name     = "api.nameurcloud.com"
  location = var.region

  metadata {
    namespace = var.project_id
  }

  spec {
    route_name = google_cloud_run_service.cloud_run_api.name
  }
  
}

resource "google_artifact_registry_repository" "docker_repo" {
  provider = google
  location = var.region
  repository_id = "production"
  description   = "Docker repo for Nameurcloud project"
  format        = "DOCKER"
  
}
