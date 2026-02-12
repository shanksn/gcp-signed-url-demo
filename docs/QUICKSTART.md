# Quick Start Guide

Get up and running in 5 minutes!

## Prerequisites

```bash
# Install if needed
brew install --cask google-cloud-sdk
brew install terraform
```

## 1. Setup (2 minutes)

```bash
# Clone or navigate to this directory
cd "GCP Projects - Signed URL"

# Copy example config
cp terraform.tfvars.example terraform.tfvars

# Edit with your project ID
# Change: project_id = "your-project-id"
nano terraform.tfvars
```

## 2. Deploy Infrastructure (2 minutes)

```bash
# Login to GCP
gcloud auth login
gcloud auth application-default login

# Deploy
terraform init
terraform apply
# Type 'yes' when prompted
```

## 3. Test Locally (1 minute)

```bash
# Run the demo
./run-local.sh

# Browser will open automatically to http://localhost:8000
```

## 4. Upload a File

1. In the browser, select a file
2. Click "Upload File"
3. Watch it upload directly to Cloud Storage!
4. Check the Cloud Console to see your file

## 5. Deploy to Production (Optional)

```bash
# Deploy backend to App Engine
./deploy.sh

# Use the provided App Engine URL in the frontend
```

## Common Issues

### "Permission denied" errors
```bash
# Make sure you're authenticated
gcloud auth application-default login

# Check your project
gcloud config get-value project
```

### "Bucket already exists"
```bash
# Bucket names are globally unique
# Edit terraform.tfvars and add a unique suffix:
# project_id = "my-project-unique-123"
```

### CORS errors in browser
```bash
# Make sure Terraform applied successfully
terraform apply

# Check bucket CORS config
gsutil cors get gs://$(terraform output -raw bucket_name)
```

## Next Steps

- Read [LEARNING.md](LEARNING.md) for detailed concepts
- Review [README.md](README.md) for full documentation
- Try uploading different file types
- Experiment with resumable uploads for large files

## Cleanup

```bash
# Delete uploaded files
gsutil -m rm -r gs://$(terraform output -raw bucket_name)/uploads/

# Destroy infrastructure
terraform destroy
```

## Test Without GCP (Just Explore Code)

Don't have a GCP account? You can still learn:

1. **Read the code:**
   - [backend/main.py](backend/main.py) - See how signed URLs are generated
   - [frontend/upload.js](frontend/upload.js) - See how browser uploads work

2. **Understand the flow:**
   - Review [LEARNING.md](LEARNING.md) for concepts
   - Study the architecture diagrams

3. **Free trial:**
   - GCP offers $300 credit for 90 days
   - This project costs < $1 to run
   - Sign up at https://cloud.google.com/free

## Support

Having issues? Check:
1. [README.md](README.md) - Full documentation
2. [LEARNING.md](LEARNING.md) - Concept explanations
3. GCP Console Logs - See what's happening
4. Browser DevTools - Check network requests

Happy learning! 🚀
