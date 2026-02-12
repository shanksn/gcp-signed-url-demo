# Project Summary

## What This Project Does

This is a complete, hands-on learning project that demonstrates **how to upload files directly from a browser to Google Cloud Storage using signed URLs** - a common pattern tested in GCP certification exams.

## The GCP Exam Question

**Q: Your company has an application running on App Engine that allows users to upload music files. You want to allow users to upload files directly into Cloud Storage from their browser session. The payload should not be passed through the backend. What should you do?**

**A: ✅ This project demonstrates the exact solution:**
1. Set CORS configuration in Cloud Storage bucket
2. Use Cloud Storage Signed URL feature to generate upload URLs
3. Browser uploads directly to GCS (bypassing backend)

## What's Included

### 📚 Documentation (Start Here!)
- **[QUICKSTART.md](QUICKSTART.md)** - Get running in 5 minutes
- **[LEARNING.md](LEARNING.md)** - Deep dive into concepts with quiz
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Visual diagrams and flow charts
- **[README.md](README.md)** - Complete reference guide

### 🏗️ Infrastructure (Terraform)
- **[main.tf](main.tf)** - Complete infrastructure as code
- **[main.tf.simple](main.tf.simple)** - Simplified version for learning
- **[variables.tf](variables.tf)** - Configurable parameters
- **[outputs.tf](outputs.tf)** - Useful information after deployment

Creates:
- Cloud Storage bucket with CORS
- Service account for signing URLs
- IAM permissions
- App Engine application (optional)

### 🔧 Backend (Python/Flask)
- **[backend/main.py](backend/main.py)** - Flask API with 3 endpoints:
  - `/api/generate-signed-url` - Standard upload
  - `/api/generate-resumable-url` - Large file upload
  - `/api/list-files` - View uploaded files
- **[backend/requirements.txt](backend/requirements.txt)** - Dependencies
- **[backend/app.yaml](backend/app.yaml)** - App Engine config

### 🎨 Frontend (HTML/JavaScript)
- **[frontend/index.html](frontend/index.html)** - Beautiful upload UI
- **[frontend/upload.js](frontend/upload.js)** - Upload logic
  - Standard signed URL upload
  - Resumable upload with pause/resume
  - Progress tracking
  - Error handling

### 🚀 Automation Scripts
- **[deploy.sh](deploy.sh)** - One-click deployment to GCP
- **[run-local.sh](run-local.sh)** - Local development environment
- **[.gitignore](.gitignore)** - Keep secrets safe

## Learning Path

### Level 1: Understand the Concept (15 min)
1. Read [LEARNING.md](LEARNING.md)
2. Review [ARCHITECTURE.md](ARCHITECTURE.md)
3. Take the quiz in LEARNING.md

### Level 2: See It Working (15 min)
1. Follow [QUICKSTART.md](QUICKSTART.md)
2. Deploy infrastructure: `terraform apply`
3. Run locally: `./run-local.sh`
4. Upload a file and watch it work!

### Level 3: Understand the Code (30 min)
1. Read [backend/main.py](backend/main.py) - See how URLs are generated
2. Read [frontend/upload.js](frontend/upload.js) - See how browsers upload
3. Review [main.tf.simple](main.tf.simple) - Understand infrastructure

### Level 4: Deploy to Production (15 min)
1. Run `./deploy.sh`
2. Access your App Engine URL
3. Upload from anywhere in the world!

## Key Learning Outcomes

After completing this project, you'll understand:

✅ **What signed URLs are** and how they work
✅ **Why CORS is needed** for browser uploads
✅ **How to generate signed URLs** using service accounts
✅ **The difference** between standard and resumable uploads
✅ **Cost benefits** of direct uploads vs. backend uploads
✅ **Security implications** of time-limited URLs
✅ **Terraform** for GCP infrastructure as code
✅ **App Engine** for serverless Python APIs

## Technology Stack

### Infrastructure
- **Terraform** - Infrastructure as code
- **Google Cloud Storage** - Object storage
- **Google App Engine** - Serverless compute
- **Google IAM** - Service accounts and permissions

### Backend
- **Python 3.12** - Runtime
- **Flask** - Web framework
- **google-cloud-storage** - GCS SDK
- **Gunicorn** - WSGI server

### Frontend
- **HTML5** - Structure
- **JavaScript (ES6+)** - Upload logic
- **CSS3** - Modern UI
- **XMLHttpRequest** - File uploads

## Project Statistics

- **Total Files:** 17
- **Lines of Code:** ~1,200
- **Documentation:** 4 comprehensive guides
- **Examples:** 2 upload methods
- **Estimated Learning Time:** 1-2 hours
- **Estimated Cost to Run:** < $1/month

## Real-World Applications

This pattern is used by:
- **Music sharing platforms** (SoundCloud, Spotify uploads)
- **Photo services** (Instagram, Google Photos)
- **Video platforms** (YouTube, Vimeo)
- **File storage** (Dropbox, Google Drive)
- **Document management** (DocuSign, HelloSign)

Any application where users upload files can benefit from this approach!

## Prerequisites

### Required
- GCP account (free tier works!)
- Basic understanding of:
  - HTTP requests (GET, POST, PUT)
  - JSON
  - Command line basics

### Helpful but Not Required
- Python knowledge (to understand backend)
- JavaScript knowledge (to understand frontend)
- Terraform experience (infrastructure concepts)

## Quick Commands Reference

```bash
# Deploy infrastructure
terraform init
terraform apply

# Run locally
./run-local.sh

# Deploy to production
./deploy.sh

# Clean up
terraform destroy
```

## File Upload Methods Explained

### 1. Standard Signed URL (PUT)
**When to use:** Files < 100MB, simple uploads

**How it works:**
1. Browser asks backend for signed URL
2. Backend generates URL (valid 15 min)
3. Browser uploads directly to GCS

**Pros:** Simple, fast, works everywhere
**Cons:** No pause/resume, restart on failure

### 2. Resumable Upload
**When to use:** Files > 100MB, unreliable networks

**How it works:**
1. Browser asks backend for resumable URL
2. Backend creates upload session (valid 1 hour)
3. Browser uploads in chunks
4. Can pause/resume anytime

**Pros:** Handles interruptions, good for large files
**Cons:** More complex, requires chunking logic

## Cost Comparison

### Traditional Upload (Through Backend)
```
User → Backend → Cloud Storage
```
- Backend bandwidth: $60/month (for 500GB)
- Backend compute: $5/month (processing)
- **Total: $65/month** 💸

### Direct Upload (Signed URLs)
```
User → Backend (URL only) → User → Cloud Storage
```
- Backend bandwidth: ~$0/month (tiny URLs)
- Backend compute: ~$0/month (minimal)
- **Total: ~$0/month** 💰

**Savings: 100%** of backend costs!

## Security Features

✅ **Time-limited URLs** - Expire after 15 minutes
✅ **Operation-specific** - Can only upload, not delete
✅ **Path-specific** - Can only access specific file
✅ **Signed cryptographically** - Cannot be forged
✅ **CORS restricted** - Can limit to specific domains
✅ **Service account** - No user credentials exposed

## What You Can Customize

- **File size limits** - Adjust in backend validation
- **Expiration time** - Change from 15 minutes
- **Allowed file types** - Add validation logic
- **Upload location** - Organize by user/date/category
- **UI styling** - Customize frontend appearance
- **CORS origins** - Restrict to your domain
- **Lifecycle rules** - Auto-delete old files

## Common Modifications

### Allow only audio files
```python
ALLOWED_TYPES = ['audio/mpeg', 'audio/wav', 'audio/ogg']
if content_type not in ALLOWED_TYPES:
    return error('Invalid file type')
```

### Organize by user
```python
user_id = get_current_user()
filename = f"uploads/{user_id}/{timestamp}_{filename}"
```

### Restrict CORS to your domain
```terraform
cors {
  origin = ["https://yourdomain.com"]
  # ...
}
```

## Troubleshooting Tips

1. **Check Terraform state:** `terraform show`
2. **View bucket CORS:** `gsutil cors get gs://BUCKET_NAME`
3. **Test backend locally:** `python backend/main.py`
4. **Browser dev tools:** Network tab shows requests
5. **App Engine logs:** `gcloud app logs tail -s default`

## Next Steps After Learning

1. **Add authentication** - Require login before generating URLs
2. **Add file validation** - Check file type and size limits
3. **Add virus scanning** - Integrate Cloud Functions
4. **Add notifications** - Alert when upload completes
5. **Add metadata** - Store uploader info, tags
6. **Add thumbnails** - Auto-generate for images
7. **Add CDN** - Serve files via Cloud CDN

## Resources for Further Learning

### Official Documentation
- [Cloud Storage Signed URLs](https://cloud.google.com/storage/docs/access-control/signed-urls)
- [CORS Configuration](https://cloud.google.com/storage/docs/cross-origin)
- [App Engine Python](https://cloud.google.com/appengine/docs/standard/python3)

### Related GCP Services
- **Cloud Functions** - Event-driven processing
- **Cloud CDN** - Content delivery
- **Cloud Armor** - DDoS protection
- **Cloud Monitoring** - Usage tracking

## Success Criteria

You've mastered this project when you can:

✅ Explain why signed URLs are better than backend uploads
✅ Configure CORS on a Cloud Storage bucket
✅ Generate signed URLs using a service account
✅ Upload files directly from browser to GCS
✅ Choose between standard and resumable uploads
✅ Deploy infrastructure with Terraform
✅ Troubleshoot common CORS and auth issues

## Support

**Questions?** Check the documentation in this order:
1. [QUICKSTART.md](QUICKSTART.md) - Getting started
2. [LEARNING.md](LEARNING.md) - Concepts and quiz
3. [ARCHITECTURE.md](ARCHITECTURE.md) - How it works
4. [README.md](README.md) - Complete reference

**Still stuck?** Review:
- Browser DevTools (Network tab)
- `gcloud app logs tail`
- Terraform output
- GCP Console

## Credits

Built for learning GCP concepts, specifically for Associate Cloud Engineer certification.

**Inspired by:** Real-world applications like SoundCloud, YouTube, and Google Drive that use direct uploads for better performance and cost efficiency.

---

**Ready to learn?** Start with [QUICKSTART.md](QUICKSTART.md)! 🚀
