#!/bin/bash

# Deployment script for GCS Signed URL Demo
# This script automates the deployment process

set -e  # Exit on error

echo "🚀 GCS Signed URL Demo - Deployment Script"
echo "=========================================="

# Check prerequisites
echo "📋 Checking prerequisites..."

command -v gcloud >/dev/null 2>&1 || { echo "❌ gcloud CLI is required but not installed."; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "❌ terraform is required but not installed."; exit 1; }

echo "✅ Prerequisites check passed"

# Check if terraform.tfvars exists
if [ ! -f terraform.tfvars ]; then
    echo "❌ terraform.tfvars not found!"
    echo "Please copy terraform.tfvars.example to terraform.tfvars and update with your project ID"
    exit 1
fi

# Initialize and apply Terraform
echo ""
echo "🏗️  Deploying infrastructure with Terraform..."
terraform init
terraform apply -auto-approve

# Get outputs
BUCKET_NAME=$(terraform output -raw bucket_name)
SA_EMAIL=$(terraform output -raw service_account_email)
PROJECT_ID=$(terraform output -raw project_id 2>/dev/null || grep project_id terraform.tfvars | cut -d'"' -f2)

echo ""
echo "📝 Infrastructure deployed:"
echo "   Bucket: $BUCKET_NAME"
echo "   Service Account: $SA_EMAIL"

# Update app.yaml
echo ""
echo "📝 Updating backend configuration..."
cp backend/app.yaml backend/app.yaml.backup
sed "s/YOUR_BUCKET_NAME/$BUCKET_NAME/g" backend/app.yaml.backup | \
    sed "s/YOUR_SERVICE_ACCOUNT_EMAIL/$SA_EMAIL/g" > backend/app.yaml

# Deploy to App Engine
echo ""
echo "🚀 Deploying backend to App Engine..."
cd backend
gcloud app deploy --quiet
cd ..

# Get App Engine URL
APP_URL=$(gcloud app browse --no-launch-browser 2>&1 | grep -o 'https://[^ ]*' || echo "https://$PROJECT_ID.appspot.com")

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📱 Your application is ready:"
echo "   Backend API: $APP_URL"
echo "   Bucket: $BUCKET_NAME"
echo ""
echo "🎯 Next steps:"
echo "   1. Open frontend/index.html in your browser"
echo "   2. Update the 'Backend API URL' to: $APP_URL"
echo "   3. Start uploading files!"
echo ""
echo "💡 To test locally:"
echo "   cd backend && python main.py"
echo "   cd frontend && python -m http.server 8000"
