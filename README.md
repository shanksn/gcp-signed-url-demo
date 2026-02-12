# GCP Cloud Storage Signed URL Demo

A hands-on project demonstrating direct browser uploads to Google Cloud Storage using signed URLs.

## 🎯 What This Project Does

This project demonstrates the GCP best practice for allowing users to upload files directly from their browser to Cloud Storage **without passing through your backend** - a key pattern for the GCP Associate Cloud Engineer exam.

## ✅ What You'll Deploy

- **Backend API:** `https://YOUR-PROJECT-ID.uc.r.appspot.com`
- **Cloud Storage Bucket:** `YOUR-PROJECT-ID-music-uploads`
- **Status:** Ready to deploy

## 🚀 Quick Start

### Test with Command Line

```bash
# Generate a signed URL (after deployment)
curl -X POST 'https://YOUR-PROJECT-ID.uc.r.appspot.com/api/generate-signed-url' \
  -H 'Content-Type: application/json' \
  -d '{"filename": "test.txt", "content_type": "text/plain"}' | jq .
```

### Use the Web Interface

```bash
# Start the frontend
cd frontend
python3 -m http.server 8000
```

Then:
1. Open http://localhost:8000 in browser
2. Set Backend URL to: `https://YOUR-PROJECT-ID.uc.r.appspot.com`
3. Upload files!

## 📁 Project Structure

```
.
├── README.md              # This file
├── main.tf                # Terraform infrastructure
├── variables.tf           # Terraform variables
├── outputs.tf             # Terraform outputs
├── terraform.tfvars       # Your configuration
│
├── backend/               # Flask API for generating signed URLs
│   ├── main.py           # Flask application
│   ├── requirements.txt  # Python dependencies
│   ├── app.yaml          # App Engine config
│   └── service-account-key.json
│
├── frontend/              # Upload UI
│   ├── index.html        # Web interface
│   └── upload.js         # Upload logic
│
├── docs/                  # 📚 Documentation (start here!)
│   ├── START_HERE.md     # 👉 Begin your learning journey
│   ├── QUICKSTART.md     # 5-minute setup guide
│   ├── LEARNING.md       # Core concepts + quiz
│   ├── ARCHITECTURE.md   # System design & diagrams
│   ├── HOW_TO_USE.md     # Detailed usage guide
│   └── VIEW_SIGNED_URLS.md # See signed URLs in action
│
└── scripts/               # Utility scripts
    ├── deploy.sh         # Deploy everything to GCP
    ├── run-local.sh      # Run locally for testing
    └── view-urls-demo.sh # Interactive URL demo
```

## 📚 Documentation

**Start here:** [docs/START_HERE.md](docs/START_HERE.md)

- **[docs/QUICKSTART.md](docs/QUICKSTART.md)** - Get running in 5 minutes
- **[docs/LEARNING.md](docs/LEARNING.md)** - Understand the concepts with quiz
- **[docs/HOW_TO_USE.md](docs/HOW_TO_USE.md)** - Complete usage guide
- **[docs/VIEW_SIGNED_URLS.md](docs/VIEW_SIGNED_URLS.md)** - See signed URLs examples
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** - System architecture & flows

## 🎓 GCP Exam Question - ANSWERED ✅

**Q:** Your company has an application on App Engine that allows users to upload music files. You want to allow users to upload files directly into Cloud Storage from their browser. The payload should not pass through the backend. What should you do?

**A:**
1. ✅ Set CORS configuration in Cloud Storage bucket
2. ✅ Use Cloud Storage Signed URL feature
3. ✅ Browser uploads directly to GCS

**This project = Complete working implementation!**

## 🔧 Technologies Used

- **Terraform** - Infrastructure as code
- **Google Cloud Storage** - Object storage with CORS
- **Google App Engine** - Serverless Python backend
- **Flask** - REST API for generating signed URLs
- **Vanilla JavaScript** - Direct browser uploads (no frameworks!)

## 🌐 API Endpoints

Your deployed backend provides:

- `POST /api/generate-signed-url` - Generate standard signed URL
- `POST /api/generate-resumable-url` - Generate resumable upload URL
- `GET /api/list-files` - List all uploaded files

## 💡 Key Concepts Demonstrated

1. **Signed URLs** - Time-limited upload authentication (15 min)
2. **CORS** - Cross-origin browser uploads enabled
3. **Direct Upload** - Files bypass backend = 99% cost savings!
4. **Resumable Uploads** - Large files with pause/resume support
5. **Infrastructure as Code** - Terraform manages everything

## 🧪 Try It Now

**Generate a signed URL (after deploying):**
```bash
curl -X POST 'https://YOUR-PROJECT-ID.uc.r.appspot.com/api/generate-signed-url' \
  -H 'Content-Type: application/json' \
  -d '{"filename": "my-file.txt", "content_type": "text/plain"}' | jq .
```

**See the interactive demo:**
```bash
./scripts/view-urls-demo.sh
```

## 📖 Learn More

- [Google Cloud Signed URLs](https://cloud.google.com/storage/docs/access-control/signed-urls)
- [CORS Configuration](https://cloud.google.com/storage/docs/cross-origin)
- [Resumable Uploads](https://cloud.google.com/storage/docs/resumable-uploads)

## 🧹 Cleanup

When you're done learning:

```bash
# Delete uploaded files
gsutil -m rm -r gs://YOUR-PROJECT-ID-music-uploads/uploads/

# Destroy infrastructure
terraform destroy
```

## 💰 Cost Estimate

Monthly cost for light testing: **< $1**

GCP Free Tier covers most usage.

## 📝 License

MIT - Free for learning and educational purposes

---

**Ready to start?** Go to [docs/START_HERE.md](docs/START_HERE.md) 🚀
