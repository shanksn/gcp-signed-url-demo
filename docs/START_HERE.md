# 🚀 START HERE

Welcome to the **GCP Cloud Storage Signed URL Demo**!

This project teaches you how to upload files directly from a browser to Google Cloud Storage - a key pattern for the GCP Associate Cloud Engineer exam.

## 🎯 What You'll Learn

By completing this project, you'll master:

1. **Cloud Storage Signed URLs** - Time-limited authentication
2. **CORS Configuration** - Enable browser uploads
3. **Direct Browser Uploads** - Bypass backend for better performance
4. **Terraform Infrastructure** - Infrastructure as code
5. **App Engine Deployment** - Serverless Python APIs

## ⚡ Quick Start (5 Minutes)

### Option 1: Just Want to Learn the Concepts?

**Read these in order:**
1. [LEARNING.md](LEARNING.md) - Core concepts explained simply
2. [ARCHITECTURE.md](ARCHITECTURE.md) - Visual diagrams and flows
3. Take the quiz in LEARNING.md to test your knowledge

**Time:** 20 minutes | **Cost:** $0 (no GCP needed)

### Option 2: Want to See It Working?

**Follow this guide:**
1. [QUICKSTART.md](QUICKSTART.md) - Deploy and run locally

**What you'll do:**
```bash
# 1. Configure your project
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your GCP project ID

# 2. Deploy infrastructure
terraform init
terraform apply

# 3. Run locally and see it work!
./run-local.sh
```

**Time:** 15 minutes | **Cost:** < $1/month

### Option 3: Want to Deploy to Production?

**Full deployment:**
```bash
# One command deploys everything!
./deploy.sh
```

Then access your app at `https://YOUR-PROJECT.appspot.com`

**Time:** 20 minutes | **Cost:** < $1/month

## 📚 Documentation Guide

Choose your path:

| Document | What It's For | Read If... |
|----------|---------------|------------|
| **[QUICKSTART.md](QUICKSTART.md)** | Get running fast | You want to deploy quickly |
| **[LEARNING.md](LEARNING.md)** | Deep concepts | You want to understand how it works |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | Visual diagrams | You're a visual learner |
| **[README.md](README.md)** | Complete reference | You need detailed documentation |
| **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** | Overview | You want to see what's included |

## 🎓 Recommended Learning Path

### Beginner Path (1 hour)
1. Read [LEARNING.md](LEARNING.md) (15 min)
2. Follow [QUICKSTART.md](QUICKSTART.md) (15 min)
3. Review [backend/main.py](backend/main.py) (15 min)
4. Review [frontend/upload.js](frontend/upload.js) (15 min)

### Advanced Path (2 hours)
1. Complete Beginner Path (1 hour)
2. Study [ARCHITECTURE.md](ARCHITECTURE.md) (20 min)
3. Review [main.tf.simple](main.tf.simple) (20 min)
4. Deploy to production with [deploy.sh](deploy.sh) (20 min)

### Exam Prep Path (30 min)
1. Read [LEARNING.md](LEARNING.md) - Focus on "Exam Tips" section
2. Review [ARCHITECTURE.md](ARCHITECTURE.md) - Study the flow diagrams
3. Take the quiz in LEARNING.md
4. Review the GCP exam question at the top of this file

## 🎯 The GCP Exam Question

**Q:** Your company has an application running on App Engine that allows users to upload music files. You want to allow users to upload files directly into Cloud Storage from their browser session. **The payload should not be passed through the backend.** What should you do?

**A:**
1. ✅ Set a CORS configuration in the Cloud Storage bucket
2. ✅ Use Cloud Storage Signed URL feature to generate upload URLs
3. ✅ Browser uploads directly to GCS (bypassing backend)

**This entire project demonstrates the answer!**

## 🔍 What's in This Project?

### Infrastructure (Terraform)
- Cloud Storage bucket with CORS
- Service account for signing URLs
- IAM permissions
- App Engine application

### Backend (Python/Flask)
- Generate standard signed URLs
- Generate resumable upload URLs
- List uploaded files
- RESTful API

### Frontend (HTML/JavaScript)
- Beautiful upload UI
- Drag-and-drop support
- Progress tracking
- Two upload methods (standard + resumable)

### Documentation
- 5 comprehensive guides
- Code comments
- Architecture diagrams
- Quiz and learning resources

## 💡 Key Concepts Preview

### What is a Signed URL?
A time-limited URL that grants temporary access to upload a file:

```
https://storage.googleapis.com/bucket/file.mp3?
  X-Goog-Signature=abc123...     ← Proves this is authorized
  X-Goog-Expires=900             ← Valid for 15 minutes
  X-Goog-Algorithm=RSA-SHA256    ← How it's signed
```

### How the Flow Works

```
1. User selects file (song.mp3)
        ↓
2. Browser asks backend: "Give me upload URL"
        ↓
3. Backend generates signed URL (valid 15 min)
        ↓
4. Browser uploads directly to Cloud Storage
        ↓
5. Done! File is in GCS, backend never saw the file data
```

### Why This Matters

**Traditional approach:**
- User → Backend → Cloud Storage
- Backend handles large files (expensive!)
- Slower for users

**Signed URL approach:**
- User → Backend (tiny URL request)
- User → Cloud Storage (direct upload)
- Backend only generates URLs (cheap!)
- Faster for users

**Result:** 99% cost reduction + better performance! 🎉

## 🛠️ Prerequisites

### Required
- Google Cloud Platform account ([free tier](https://cloud.google.com/free))
- `gcloud` CLI ([install](https://cloud.google.com/sdk/docs/install))
- Terraform ([install](https://terraform.io/downloads))
- Python 3.12+ (for local testing)

### Knowledge
- Basic HTTP concepts (GET, POST, PUT)
- Basic JSON understanding
- Command line basics

**No prior GCP experience needed!** This project teaches you.

## 🚀 Choose Your Adventure

### I want to understand the concept first
👉 Start with [LEARNING.md](LEARNING.md)

### I want to see it working now
👉 Jump to [QUICKSTART.md](QUICKSTART.md)

### I want to see code examples
👉 Check [backend/main.py](backend/main.py) and [frontend/upload.js](frontend/upload.js)

### I want to understand the architecture
👉 Read [ARCHITECTURE.md](ARCHITECTURE.md)

### I want complete documentation
👉 Read [README.md](README.md)

### I'm studying for GCP certification
👉 Read [LEARNING.md](LEARNING.md) and focus on "Exam Tips"

## 💰 Cost Estimate

Running this project costs approximately:

- **Local testing:** $0
- **Infrastructure (Terraform):** ~$0.01/month
- **Light production use:** < $1/month
- **GCP Free Tier:** Covers most usage

**This is a learning project - it won't break the bank!**

## 🎓 After Completing This Project

You'll be able to:

✅ Explain signed URLs to others
✅ Configure CORS on GCS buckets
✅ Generate signed URLs with service accounts
✅ Build direct-upload UIs in JavaScript
✅ Deploy infrastructure with Terraform
✅ Answer GCP exam questions about direct uploads

## 📊 Project Stats

- **Total Files:** 18
- **Lines of Code:** ~1,500
- **Documentation Pages:** 6
- **Upload Methods:** 2 (standard + resumable)
- **Learning Time:** 1-2 hours
- **Deployment Time:** 5 minutes

## 🤝 Need Help?

1. **Read the docs** - Check the table above
2. **Check logs** - `gcloud app logs tail`
3. **Browser console** - F12 → Network tab
4. **Terraform output** - `terraform show`

## ✨ Ready to Start?

Pick your path and dive in! Here's what to do next:

1. **If you haven't already:** Clone or open this project
2. **Choose your learning path** from above
3. **Start with the recommended document**
4. **Have fun learning!** 🎉

---

**Quick Links:**
- [QUICKSTART.md](QUICKSTART.md) - Get running in 5 minutes
- [LEARNING.md](LEARNING.md) - Understand the concepts
- [ARCHITECTURE.md](ARCHITECTURE.md) - See how it works
- [README.md](README.md) - Complete reference

**Let's learn GCP together!** 🚀
