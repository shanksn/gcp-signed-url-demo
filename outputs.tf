# ============================================================================
# Terraform Outputs - Important values after deployment
# ============================================================================

output "bucket_name" {
  description = "Cloud Storage bucket name for uploads"
  value       = google_storage_bucket.music_uploads.name
}

output "bucket_url" {
  description = "Cloud Storage bucket gs:// URL"
  value       = google_storage_bucket.music_uploads.url
}

output "bucket_console_url" {
  description = "GCP Console URL to view the bucket"
  value       = "https://console.cloud.google.com/storage/browser/${google_storage_bucket.music_uploads.name}"
}

output "service_account_email" {
  description = "Service account email for signing URLs"
  value       = google_service_account.url_signer.email
}

output "app_engine_url" {
  description = "Backend API URL (after deploying with 'gcloud app deploy')"
  value       = "https://${var.project_id}.uc.r.appspot.com"
}

output "service_account_key_path" {
  description = "Local path to service account key file"
  value       = local_file.service_account_key.filename
  sensitive   = true
}

# ============================================================================
# Next Steps Output - Helpful instructions
# ============================================================================

output "next_steps" {
  description = "What to do next"
  value       = <<-EOT

  ✅ Infrastructure deployed successfully!

  📋 Next steps:

  1. Deploy backend to App Engine:
     cd backend && gcloud app deploy

  2. Test the API:
     curl ${format("https://%s.uc.r.appspot.com", var.project_id)}

  3. Use the frontend:
     cd frontend && python3 -m http.server 8000

  📖 View bucket: https://console.cloud.google.com/storage/browser/${google_storage_bucket.music_uploads.name}

  EOT
}
