# Setup Instructions for New Users

This guide helps you set up this GCP Cloud Storage Signed URL demo project in your own GCP account.

## Prerequisites

- Google Cloud Platform account
- `gcloud` CLI installed and authenticated
- `terraform` installed
- Python 3.8+

## Step 1: Clone the Repository

```bash
git clone <your-repo-url>
cd GCP-Projects-Signed-URL
```

## Step 2: Configure GCP Project

1. **Create terraform.tfvars:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars:**
   ```hcl
   project_id = "your-actual-gcp-project-id"
   region     = "us-central1"
   ```

## Step 3: Deploy Infrastructure with Terraform

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy infrastructure
terraform apply
```

This creates:
- Cloud Storage bucket
- Service account with signing permissions
- Service account key (saved locally - DO NOT COMMIT!)
- App Engine application

## Step 4: Configure Firebase Authentication

1. **Go to Firebase Console:**
   ```
   https://console.firebase.google.com
   ```

2. **Add your GCP project to Firebase** (if not already added)

3. **Enable Authentication:**
   - Click "Build" → "Authentication"
   - Click "Get started" to activate
   - Go to "Sign-in method" tab
   - Enable "Google" provider
   - Select your support email
   - Save

4. **Register your web app:**
   - Go to Project Settings (gear icon)
   - Scroll to "Your apps"
   - Click "Add app" → "Web" (</> icon)
   - Register app with a nickname
   - Copy the Firebase config object

5. **Create frontend/firebase-config.js:**
   ```bash
   cp frontend/firebase-config.example.js frontend/firebase-config.js
   ```

6. **Edit frontend/firebase-config.js** with your actual Firebase config from step 4

## Step 5: Deploy Backend to App Engine

```bash
cd backend
gcloud app deploy --project=your-project-id
```

## Step 6: Test Locally

**Terminal 1 - Backend:**
```bash
cd backend
export BUCKET_NAME=your-project-id-music-uploads
export SERVICE_ACCOUNT_EMAIL=url-signer@your-project-id.iam.gserviceaccount.com
python3 -m pip install -r requirements.txt
python3 main.py
```

**Terminal 2 - Frontend:**
```bash
cd frontend
python3 -m http.server 8001
```

**Open in browser:**
```
http://localhost:8001/index-with-auth.html
```

## Step 7: Test Authentication

1. Click "Sign in with Google"
2. Select your Google account
3. Upload a test file
4. Check your GCS bucket for the uploaded file

## Important Files (DO NOT COMMIT)

These files contain sensitive information and are already in `.gitignore`:

- `service-account-key.json` - Service account private key
- `backend/service-account-key.json` - Copy of service account key
- `terraform.tfvars` - Your GCP project ID
- `terraform.tfstate` - Terraform state (may contain sensitive data)
- `.terraform.lock.hcl` - Terraform lock file
- `frontend/firebase-config.js` - Your Firebase credentials

## Security Notes

1. **Service Account Key:** The private key is required for signing URLs. Keep it secure and never commit to version control.

2. **Firebase Config:** The `apiKey` in firebase-config.js is safe to expose publicly (it's not a secret). However, ensure you've configured Firebase Security Rules properly.

3. **CORS Configuration:** In production, update the CORS configuration in Cloud Storage to allow only your specific domain instead of "*".

## Troubleshooting

**Error: "Firebase: Error (auth/configuration-not-found)"**
- Solution: Enable Google Sign-In in Firebase Console (Step 4)

**Error: "ModuleNotFoundError: No module named 'flask_cors'"**
- Solution: Install Python dependencies: `pip3 install -r backend/requirements.txt`

**Error: "Permission denied"**
- Solution: Ensure your service account has the correct IAM roles

## Additional Resources

- [Firebase Authentication Docs](https://firebase.google.com/docs/auth)
- [Cloud Storage Signed URLs](https://cloud.google.com/storage/docs/access-control/signed-urls)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

## Questions?

See the documentation in the `docs/` folder for more detailed guides.
