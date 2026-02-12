# Security Guide - Protecting Your Backend API

## ⚠️ Current Security Status

**Your backend is currently OPEN to anyone!**

Anyone who knows `https://YOUR-PROJECT-ID.uc.r.appspot.com` can:
- ✓ Request signed URLs
- ✓ Upload files to your bucket
- ✓ Use your Cloud Storage quota
- ✓ Cost you money if they upload a lot

### Why Is It Open?

Look at your `backend/main.py`:

```python
@app.route('/api/generate-signed-url', methods=['POST'])
def generate_signed_url():
    # NO AUTHENTICATION CHECK HERE!
    data = request.get_json()
    # ... generates URL for anyone ...
```

**There's no check for:**
- ❌ Who is making the request
- ❌ If they're logged in
- ❌ If they have permission

## 🎯 Is This a Problem?

### For This Learning Project: ✅ It's Fine

This is a **demo/learning project**, so it's acceptable because:
- You're learning the signed URL concept
- Files auto-delete after 30 days (set in Terraform)
- It's not production data
- You can destroy it anytime

### For Production: ⚠️ CRITICAL SECURITY ISSUE

In a real application, this would allow:
- **Cost attacks**: Someone uploads 1TB → you pay $20+
- **Quota abuse**: Fill your storage quota
- **Spam**: Unwanted files in your bucket
- **Legal issues**: Someone uploads illegal content to YOUR bucket

## 🔒 Security Solutions (Choose Your Level)

### Solution 1: Add Simple API Key (5 minutes)

**Best for:** Quick protection, hobby projects

**How it works:**
1. Create a secret API key
2. Clients must include it in requests
3. Backend validates the key

**Implementation:**

```python
# backend/main.py
import os

# Secret API key (in production, use environment variable!)
API_KEY = os.environ.get('API_KEY', 'your-secret-key-here-change-this')

@app.route('/api/generate-signed-url', methods=['POST'])
def generate_signed_url():
    # CHECK API KEY FIRST!
    api_key = request.headers.get('X-API-Key')
    if api_key != API_KEY:
        return jsonify({'error': 'Invalid API key'}), 401

    # Rest of your code...
    data = request.get_json()
    # ...
```

**Client usage:**
```javascript
fetch('https://your-app.appspot.com/api/generate-signed-url', {
    headers: {
        'Content-Type': 'application/json',
        'X-API-Key': 'your-secret-key-here-change-this'
    },
    body: JSON.stringify({...})
})
```

**Pros:**
- ✅ Easy to implement (5 minutes)
- ✅ Stops casual abuse

**Cons:**
- ⚠️ Key can leak if exposed in frontend code
- ⚠️ All users share same key
- ⚠️ Can't track who uploaded what

---

### Solution 2: Add Firebase Authentication (30 minutes)

**Best for:** Real applications with user accounts

**How it works:**
1. Users log in with Google/Email (Firebase handles it)
2. Frontend gets an auth token
3. Backend verifies token with Firebase
4. Each user can only upload their own files

**Implementation:**

**Step 1: Add Firebase to your project**
```bash
# In backend/
pip install firebase-admin
```

**Step 2: Update backend**
```python
# backend/main.py
import firebase_admin
from firebase_admin import credentials, auth

# Initialize Firebase (use your service account)
cred = credentials.Certificate('firebase-service-account.json')
firebase_admin.initialize_app(cred)

@app.route('/api/generate-signed-url', methods=['POST'])
def generate_signed_url():
    # Get Firebase token from header
    id_token = request.headers.get('Authorization', '').replace('Bearer ', '')

    try:
        # Verify the token with Firebase
        decoded_token = auth.verify_id_token(id_token)
        user_id = decoded_token['uid']
        user_email = decoded_token.get('email', 'unknown')

        # Now you know WHO is making the request!
        print(f"User {user_email} requesting upload")

    except Exception as e:
        return jsonify({'error': 'Unauthorized'}), 401

    # Generate signed URL only for authenticated users
    data = request.get_json()
    filename = data.get('filename')

    # Store in user-specific folder
    unique_filename = f"uploads/{user_id}/{filename}"
    # ... rest of code ...
```

**Step 3: Frontend login**
```javascript
// frontend/upload.js
import { initializeApp } from 'firebase/app';
import { getAuth, signInWithPopup, GoogleAuthProvider } from 'firebase/auth';

// User logs in with Google
const provider = new GoogleAuthProvider();
const auth = getAuth();
const result = await signInWithPopup(auth, provider);

// Get auth token
const idToken = await result.user.getIdToken();

// Include token in requests
fetch('https://your-app.appspot.com/api/generate-signed-url', {
    headers: {
        'Authorization': `Bearer ${idToken}`,
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({...})
})
```

**Pros:**
- ✅ Real user authentication
- ✅ Know who uploaded each file
- ✅ Can organize files by user
- ✅ Can set per-user quotas

**Cons:**
- ⚠️ Requires Firebase setup
- ⚠️ More complex

---

### Solution 3: Add Identity Platform (Google's Solution)

**Best for:** Enterprise applications

**How it works:**
1. Use Google Cloud Identity Platform
2. Users authenticate with your app
3. Backend validates using IAM
4. Full audit trail

**Implementation:**

```python
# backend/main.py
from google.oauth2 import id_token
from google.auth.transport import requests

@app.route('/api/generate-signed-url', methods=['POST'])
def generate_signed_url():
    # Get token from header
    token = request.headers.get('Authorization', '').replace('Bearer ', '')

    try:
        # Verify with Google
        idinfo = id_token.verify_oauth2_token(
            token,
            requests.Request(),
            'YOUR_CLIENT_ID.apps.googleusercontent.com'
        )

        user_id = idinfo['sub']

    except ValueError:
        return jsonify({'error': 'Invalid token'}), 401

    # ... rest of code ...
```

---

### Solution 4: Add Rate Limiting (10 minutes)

**Best for:** Preventing abuse on any auth level

**How it works:**
Limit how many URLs each IP/user can request per hour

**Implementation:**

```python
# backend/main.py
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

limiter = Limiter(
    app=app,
    key_func=get_remote_address,  # Track by IP address
    default_limits=["100 per hour"]  # Max 100 requests per hour per IP
)

@app.route('/api/generate-signed-url', methods=['POST'])
@limiter.limit("10 per minute")  # Max 10 URLs per minute
def generate_signed_url():
    # ... your code ...
```

**Install:**
```bash
pip install Flask-Limiter
```

**Pros:**
- ✅ Prevents spam/abuse
- ✅ Easy to add
- ✅ Works with any auth method

---

## 🎯 Recommended Approach by Use Case

### For Your Learning Project (Current)
```
✅ Keep it as-is
   - It's for learning
   - Easy to test
   - Can destroy anytime

Optional: Add to .gitignore to not expose URL publicly
```

### For a Hobby Project
```
✅ API Key (Solution 1)
✅ Rate Limiting (Solution 4)
   - Simple to implement
   - Good enough for small projects
```

### For a Real Application
```
✅ Firebase Auth (Solution 2)
✅ Rate Limiting (Solution 4)
✅ User-specific folders
   - Proper authentication
   - Track who uploads what
   - Per-user quotas
```

### For Enterprise
```
✅ Identity Platform (Solution 3)
✅ Rate Limiting (Solution 4)
✅ Cloud Armor (DDoS protection)
✅ Audit logging
✅ VPC Service Controls
   - Maximum security
   - Full compliance
   - Audit trail
```

---

## 🛡️ Other Security Measures

### 1. Validate File Types

```python
@app.route('/api/generate-signed-url', methods=['POST'])
def generate_signed_url():
    data = request.get_json()
    content_type = data.get('content_type')

    # Only allow specific file types
    ALLOWED_TYPES = [
        'audio/mpeg',
        'audio/wav',
        'image/jpeg',
        'image/png'
    ]

    if content_type not in ALLOWED_TYPES:
        return jsonify({'error': 'File type not allowed'}), 400

    # ... continue ...
```

### 2. Limit File Size

```python
# In signed URL generation
url = blob.generate_signed_url(
    version="v4",
    expiration=timedelta(minutes=15),
    method="PUT",
    content_type=content_type,
    # Add max file size validation
    headers={
        'Content-Length-Range': '0,104857600'  # Max 100MB
    }
)
```

### 3. Restrict CORS to Your Domain

**In `main.tf`:**
```hcl
cors {
  # Don't use "*" in production!
  origin = ["https://yourdomain.com"]
  method = ["GET", "POST", "PUT"]
}
```

### 4. Add Monitoring

```python
import logging

@app.route('/api/generate-signed-url', methods=['POST'])
def generate_signed_url():
    ip = request.remote_addr
    filename = request.json.get('filename')

    # Log who's requesting what
    logging.info(f"Signed URL request from {ip} for {filename}")

    # ... rest of code ...
```

### 5. Set Up Alerts

In Google Cloud Console:
1. Go to Monitoring → Alerting
2. Create alert for:
   - High Cloud Storage costs
   - Unusual upload patterns
   - Large number of requests

---

## 🎓 For the GCP Exam

**Q: How do you secure a signed URL generation endpoint?**

**A:**
1. ✅ Authenticate users (Firebase, Identity Platform, OAuth)
2. ✅ Validate file types and sizes
3. ✅ Rate limit requests
4. ✅ Restrict CORS origins
5. ✅ Monitor and alert on usage

**The exam focuses on the signed URL concept itself, not auth**
- They assume you handle auth properly
- Main point: Files bypass backend
- CORS + Signed URLs = Direct upload

---

## 🧪 Test Security

### Test 1: Without Auth (Current)
```bash
# Anyone can do this:
curl -X POST 'https://YOUR-PROJECT-ID.uc.r.appspot.com/api/generate-signed-url' \
  -H 'Content-Type: application/json' \
  -d '{"filename": "test.txt", "content_type": "text/plain"}'

# ✅ Works (no auth required)
```

### Test 2: With API Key
```bash
# Without key - FAILS
curl -X POST 'https://your-app.appspot.com/api/generate-signed-url' \
  -H 'Content-Type: application/json' \
  -d '{"filename": "test.txt"}'
# ❌ 401 Unauthorized

# With key - WORKS
curl -X POST 'https://your-app.appspot.com/api/generate-signed-url' \
  -H 'Content-Type: application/json' \
  -H 'X-API-Key: your-secret-key' \
  -d '{"filename": "test.txt"}'
# ✅ Returns signed URL
```

---

## 📊 Cost Protection

Even with auth, protect against costs:

### Set Budget Alerts
```bash
gcloud billing budgets create \
  --billing-account=YOUR_BILLING_ACCOUNT \
  --display-name="Cloud Storage Budget" \
  --budget-amount=10USD \
  --threshold-rule=percent=90
```

### Set Quota Limits
In Terraform:
```hcl
resource "google_storage_bucket" "music_uploads" {
  # ... existing config ...

  # Max 10GB total
  storage_class = "STANDARD"

  lifecycle_rule {
    condition {
      age = 7  # Delete after 7 days instead of 30
    }
    action {
      type = "Delete"
    }
  }
}
```

---

## 🎯 Summary

**Your Current Setup:**
- ⚠️ Open to anyone (for learning - OK!)
- ⚠️ No authentication
- ⚠️ No rate limiting
- ✅ Auto-deletes after 30 days (good!)
- ✅ Perfect for learning the concept

**For Production, Add:**
1. User authentication (Firebase/Identity Platform)
2. Rate limiting (Flask-Limiter)
3. File validation (type, size)
4. CORS restriction (specific domain)
5. Monitoring and alerts
6. Budget limits

**Remember:** The signed URL itself is secure! The issue is WHO can request one. That's why you need auth on the backend endpoint.

---

**Your observation was spot-on!** Anyone with the backend URL can currently request signed URLs. This is fine for learning, but would need authentication in production. 🎯
