variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "app_engine_location" {
  description = "The location for App Engine application (must be a region)"
  type        = string
  default     = "us-central"
}
