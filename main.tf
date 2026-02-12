# ============================================================================
# Terraform Configuration
# ============================================================================
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ============================================================================
# Local Variables - Centralize common values
# ============================================================================
locals {
  bucket_name = "${var.project_id}-music-uploads"

  # APIs needed for this project
  required_apis = [
    "storage.googleapis.com",    # Cloud Storage
    "appengine.googleapis.com",  # App Engine
    "cloudbuild.googleapis.com", # For App Engine deployment
    "iam.googleapis.com"         # Service accounts
  ]
}

# ============================================================================
# Enable Required Google Cloud APIs
# ============================================================================
resource "google_project_service" "required_apis" {
  for_each = toset(local.required_apis)

  service            = each.value
  disable_on_destroy = false  # Keep APIs enabled after terraform destroy
}

# ============================================================================
# Cloud Storage Bucket
# ============================================================================
resource "google_storage_bucket" "music_uploads" {
  name     = local.bucket_name
  location = var.region

  # Allow terraform destroy to delete bucket even if it contains files
  force_destroy = true

  # Use uniform access control (recommended)
  uniform_bucket_level_access = true

  # CORS configuration - allows browser uploads from any origin
  # 🔒 SECURITY: In production, replace ["*"] with your specific domain!
  cors {
    origin          = ["*"]
    method          = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    response_header = ["Content-Type", "Content-Range", "Content-Disposition"]
    max_age_seconds = 3600  # Cache CORS response for 1 hour
  }

  # Auto-delete files after 30 days (demo cleanup)
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.required_apis]
}

# ============================================================================
# Service Account for Signing URLs
# ============================================================================
resource "google_service_account" "url_signer" {
  account_id   = "url-signer"
  display_name = "URL Signing Service Account"
  description  = "Generates signed URLs for Cloud Storage uploads"

  depends_on = [google_project_service.required_apis]
}

# Grant permissions to upload/delete files in the bucket
resource "google_storage_bucket_iam_member" "url_signer_admin" {
  bucket = google_storage_bucket.music_uploads.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.url_signer.email}"
}

# ============================================================================
# Service Account Key (for signing URLs)
# ============================================================================
# 🔒 SECURITY NOTE: In production, use Workload Identity instead!
# This creates a key file for learning/development purposes.
resource "google_service_account_key" "url_signer_key" {
  service_account_id = google_service_account.url_signer.name
}

# Save the key to a local file for backend to use
resource "local_file" "service_account_key" {
  content  = base64decode(google_service_account_key.url_signer_key.private_key)
  filename = "${path.module}/service-account-key.json"

  # Sensitive file - restrict permissions
  file_permission = "0600"
}

# ============================================================================
# App Engine Application
# ============================================================================
resource "google_app_engine_application" "app" {
  project     = var.project_id
  location_id = var.app_engine_location

  depends_on = [google_project_service.required_apis]
}
