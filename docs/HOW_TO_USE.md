# 🚀 How to Use Your Application

Your GCP Cloud Storage Signed URL application is now **fully deployed and working**!

## ✅ What's Running

**Backend API:** https://biotechproject-483505.uc.r.appspot.com
**Cloud Storage Bucket:** biotechproject-483505-music-uploads
**Status:** 🟢 All systems operational

## 🎯 Quick Test (30 seconds)

Try uploading a file right now using the frontend:

### Option 1: Open Frontend in Browser (Easiest)

```bash
cd "/Users/shankar/Documents/GCP Projects - Signed URL/frontend"
python3 -m http.server 8000
```

Then:
1. Open http://localhost:8000 in your browser
2. **Change Backend URL** to: `https://biotechproject-483505.uc.r.appspot.com`
3. Click or drag a file to upload
4. Watch it upload directly to Google Cloud Storage!

### Option 2: Test with Command Line

```bash
# Run the test script
cd "/Users/shankar/Documents/GCP Projects - Signed URL"
./complete-test.sh
```

## 📱 Using the Web Interface

### Standard Signed URL Upload

1. **Open the frontend** at http://localhost:8000 (after starting python server)
2. **Update Backend URL** in the text box at the top:
   - Change from: `http://localhost:8080`
   - Change to: `https://biotechproject-483505.uc.r.appspot.com`
3. Click the **"Standard Signed URL"** tab
4. **Select a file** (or drag and drop)
5. Click **"Upload File"**
6. Watch the progress bar!

**Best for:** Regular files under 100MB

### Resumable Upload

1. Switch to the **"Resumable Upload"** tab
2. Select a larger file (> 10MB recommended)
3. Click **"Upload File"**
4. Try clicking **"Pause"** during upload
5. Click **"Resume"** to continue

**Best for:** Large files, unreliable networks

## 🔍 View Your Uploads

### In the GCP Console

Visit: https://console.cloud.google.com/storage/browser/biotechproject-483505-music-uploads

You'll see all your uploaded files in the `uploads/` folder!

### Using the API

```bash
curl https://biotechproject-483505.uc.r.appspot.com/api/list-files | jq .
```

### Using gsutil

```bash
gsutil ls gs://biotechproject-483505-music-uploads/uploads/
```

## 🧪 API Examples

### Generate a Signed URL

```bash
curl -X POST 'https://biotechproject-483505.uc.r.appspot.com/api/generate-signed-url' \
  -H 'Content-Type: application/json' \
  -d '{
    "filename": "my-song.mp3",
    "content_type": "audio/mpeg"
  }' | jq .
```

### Upload Using Signed URL

```bash
# Step 1: Get signed URL
SIGNED_URL=$(curl -s -X POST 'https://biotechproject-483505.uc.r.appspot.com/api/generate-signed-url' \
  -H 'Content-Type: application/json' \
  -d '{"filename": "test.txt", "content_type": "text/plain"}' | jq -r '.signed_url')

# Step 2: Upload file
curl -X PUT "$SIGNED_URL" \
  -H 'Content-Type: text/plain' \
  --data-binary @yourfile.txt

# Step 3: Verify
curl https://biotechproject-483505.uc.r.appspot.com/api/list-files | jq .
```

### Generate Resumable Upload URL

```bash
curl -X POST 'https://biotechproject-483505.uc.r.appspot.com/api/generate-resumable-url' \
  -H 'Content-Type: application/json' \
  -d '{
    "filename": "large-file.zip",
    "content_type": "application/zip"
  }' | jq .
```

## 📊 What You've Learned

By deploying this application, you now understand:

### 1. **Signed URLs** ✅
- Time-limited access tokens for Cloud Storage
- No need for users to have GCP credentials
- Cryptographically secure

### 2. **CORS Configuration** ✅
- Allows browsers to upload cross-origin
- Configured on the Cloud Storage bucket
- Essential for direct browser uploads

### 3. **Direct Browser Uploads** ✅
- Files never touch your backend
- Reduces server load by 99%
- Faster for users
- Lower costs

### 4. **Infrastructure as Code** ✅
- Terraform manages all GCP resources
- Repeatable deployments
- Version controlled

### 5. **Serverless Deployment** ✅
- App Engine auto-scales
- Pay only for what you use
- No server management

## 🎓 This Answers the GCP Exam Question!

**Q:** Allow users to upload files directly to Cloud Storage from browser. Payload should NOT pass through backend.

**Your Solution:**
1. ✅ Set CORS on bucket (in [main.tf](main.tf))
2. ✅ Use Signed URLs (in [backend/main.py](backend/main.py))
3. ✅ Direct browser upload (in [frontend/upload.js](frontend/upload.js))

## 💡 Real-World Use Cases

This pattern is used by:
- **Music platforms** - SoundCloud, Spotify
- **Video platforms** - YouTube, Vimeo
- **Photo services** - Instagram, Google Photos
- **File storage** - Dropbox, Google Drive
- **Document management** - DocuSign

## 🔍 Monitor Your Application

### View Logs
```bash
gcloud app logs tail -s default --project=biotechproject-483505
```

### View in Console
- **App Engine:** https://console.cloud.google.com/appengine?project=biotechproject-483505
- **Storage:** https://console.cloud.google.com/storage/browser?project=biotechproject-483505

### Check Costs
```bash
gcloud billing accounts list
```

Visit: https://console.cloud.google.com/billing?project=biotechproject-483505

## 🎨 Customize Your Application

### Change Upload Location
Edit [backend/main.py](backend/main.py:58):
```python
unique_filename = f"music/{user_id}/{timestamp}_{filename}"
```

### Restrict File Types
Edit [backend/main.py](backend/main.py:46):
```python
ALLOWED_TYPES = ['audio/mpeg', 'audio/wav', 'audio/ogg']
if content_type not in ALLOWED_TYPES:
    return jsonify({'error': 'Invalid file type'}), 400
```

### Change Expiration Time
Edit [backend/main.py](backend/main.py:68):
```python
expiration=timedelta(minutes=60)  # Changed from 15 to 60
```

## 📚 Learn More

- **Concepts:** Read [LEARNING.md](LEARNING.md)
- **Architecture:** Read [ARCHITECTURE.md](ARCHITECTURE.md)
- **Full Docs:** Read [README.md](README.md)

## 🧹 Cleanup (When Done)

To avoid ongoing charges:

```bash
# Delete uploaded files
gsutil -m rm -r gs://biotechproject-483505-music-uploads/uploads/

# Destroy infrastructure
cd "/Users/shankar/Documents/GCP Projects - Signed URL"
terraform destroy
```

## ✨ Try These Next

1. **Upload different file types**
   - Images (JPG, PNG)
   - Audio (MP3, WAV)
   - Video (MP4, MOV)

2. **Test resumable uploads**
   - Upload a large file (> 50MB)
   - Pause it mid-upload
   - Resume and complete

3. **View in console**
   - Watch uploads appear in real-time
   - Check file metadata
   - Download files

4. **Monitor logs**
   - See API requests
   - Check for errors
   - View performance

## 🎉 Success!

You've successfully deployed a production-ready GCP application that:
- ✅ Uploads files directly to Cloud Storage
- ✅ Uses signed URLs for authentication
- ✅ Bypasses backend for better performance
- ✅ Demonstrates real-world best practices
- ✅ Answers the GCP exam question perfectly!

**Your application is ready to use!**

---

**Quick Links:**
- **Backend:** https://biotechproject-483505.uc.r.appspot.com
- **Console:** https://console.cloud.google.com/storage/browser/biotechproject-483505-music-uploads
- **Logs:** `gcloud app logs tail -s default`

Happy uploading! 🚀
