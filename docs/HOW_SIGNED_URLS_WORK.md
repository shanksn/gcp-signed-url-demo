# How Signed URLs Work - Complete Guide

## 🎯 The Big Picture

**Problem:** Users need to upload files to Cloud Storage, but you can't give them your GCP credentials.

**Solution:** Generate a temporary, authorized URL that works for exactly one upload.

---

## 📊 The Complete Flow (With Your Code!)

### Step 1: User Selects a File

Browser has: `song.mp3` (50MB music file)

### Step 2: Browser Requests Signed URL

**JavaScript code** (from `frontend/upload.js`):
```javascript
const response = await fetch('https://your-app.appspot.com/api/generate-signed-url', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
        filename: 'song.mp3',
        content_type: 'audio/mpeg'
    })
});
```

### Step 3: Backend Generates Signed URL

**Python code** (from `backend/main.py:76-81`):
```python
# Create a reference to where the file will be stored
bucket = storage_client.bucket(BUCKET_NAME)
blob = bucket.blob('uploads/20260211_190000_song.mp3')

# Generate signed URL - THIS IS THE MAGIC!
url = blob.generate_signed_url(
    version="v4",              # Use signing version 4
    expiration=timedelta(minutes=15),  # Valid for 15 minutes
    method="PUT",              # Only allow PUT (upload)
    content_type="audio/mpeg"  # Must match this content type
)
```

**What `generate_signed_url()` does internally:**

1. **Creates a canonical request** (the thing to sign):
   ```
   PUT
   /YOUR-PROJECT-ID-music-uploads/uploads/20260211_190000_song.mp3
   
   content-type:audio/mpeg
   host:storage.googleapis.com
   
   20260211T190000Z
   900 seconds (15 minutes)
   ```

2. **Signs it with the service account private key**:
   ```python
   signature = RSA_SHA256_Sign(canonical_request, private_key)
   ```

3. **Builds the final URL** with all the parameters:
   ```
   https://storage.googleapis.com/bucket/file.mp3?
     X-Goog-Algorithm=GOOG4-RSA-SHA256&
     X-Goog-Credential=url-signer@project.iam.gserviceaccount.com/...&
     X-Goog-Date=20260211T190000Z&
     X-Goog-Expires=900&
     X-Goog-SignedHeaders=content-type;host&
     X-Goog-Signature=abc123def456...
   ```

### Step 4: Backend Returns Signed URL

**Response:**
```json
{
  "signed_url": "https://storage.googleapis.com/YOUR-PROJECT-ID-music-uploads/uploads/20260211_190000_song.mp3?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Credential=url-signer%40YOUR-PROJECT-ID.iam.gserviceaccount.com%2F20260211%2Fauto%2Fstorage%2Fgoog4_request&X-Goog-Date=20260211T190000Z&X-Goog-Expires=900&X-Goog-SignedHeaders=content-type%3Bhost&X-Goog-Signature=b9aff5a0c0341682958f8ffa74ec081c...",
  "filename": "uploads/20260211_190000_song.mp3",
  "method": "PUT",
  "expires_in": "15 minutes"
}
```

### Step 5: Browser Uploads Directly to Cloud Storage

**JavaScript code** (from `frontend/upload.js`):
```javascript
// Extract the signed URL from response
const { signed_url } = await response.json();

// Upload DIRECTLY to Cloud Storage (bypassing backend!)
xhr.open('PUT', signed_url);
xhr.setRequestHeader('Content-Type', 'audio/mpeg');
xhr.send(file);  // Send the 50MB file
```

**What happens on the network:**
```http
PUT /YOUR-PROJECT-ID-music-uploads/uploads/20260211_190000_song.mp3?X-Goog-Algorithm=GOOG4-RSA-SHA256&... HTTP/1.1
Host: storage.googleapis.com
Content-Type: audio/mpeg
Content-Length: 52428800

[50MB of file data]
```

### Step 6: Cloud Storage Validates

Cloud Storage receives the request and checks:

1. **✓ Signature is valid?**
   - Extracts the signature from URL
   - Re-creates the canonical request from URL parameters
   - Verifies signature using service account's PUBLIC key
   - If signature matches → authorized!

2. **✓ Not expired?**
   - Checks `X-Goog-Date` (when URL was created)
   - Checks `X-Goog-Expires` (900 seconds = 15 minutes)
   - Current time must be within that window

3. **✓ Method matches?**
   - Request is using PUT
   - URL was signed for PUT
   - ✓ Matches!

4. **✓ Path matches?**
   - Request is for `/bucket/uploads/20260211_190000_song.mp3`
   - URL was signed for exactly that path
   - ✓ Matches!

**All checks pass → File accepted and stored!**

### Step 7: Success!

Browser receives:
```http
HTTP/1.1 200 OK
Content-Length: 0
```

File is now in Cloud Storage at:
`gs://YOUR-PROJECT-ID-music-uploads/uploads/20260211_190000_song.mp3`

---

## 🔐 The Cryptography Explained

### Why It's Secure

**The Signing Process:**

1. **Backend has:** Private key (kept secret)
2. **Google Cloud has:** Public key (can be shared)
3. **Mathematical guarantee:** 
   - Only private key can CREATE signatures
   - But public key can VERIFY signatures
   - Can't forge a signature without the private key

**Analogy:**
- Private key = Your pen (only you can sign)
- Public key = Anyone can verify your signature is real
- Signature = Proof you signed it, can't be forged

### What's Being Signed?

The signature covers ALL these parameters:
```
HTTP Method: PUT
Resource path: /bucket/uploads/20260211_190000_song.mp3
Content-Type: audio/mpeg
Timestamp: 20260211T190000Z
Expiration: 900 seconds
Host: storage.googleapis.com
```

**Change ANY of these → Signature becomes invalid!**

This means:
- ❌ Can't change to DELETE method
- ❌ Can't change the file path
- ❌ Can't extend the expiration
- ❌ Can't use for a different bucket

---

## 🔑 Your Project's Keys

### Where the Keys Come From

**Created by Terraform** (`main.tf:102-113`):
```hcl
resource "google_service_account_key" "url_signer_key" {
  service_account_id = google_service_account.url_signer.name
}

resource "local_file" "service_account_key" {
  content  = base64decode(google_service_account_key.url_signer_key.private_key)
  filename = "${path.module}/service-account-key.json"
  file_permission = "0600"  # Only you can read it!
}
```

**The key file contains:**
```json
{
  "type": "service_account",
  "project_id": "YOUR-PROJECT-ID",
  "private_key_id": "dda1eb3632d192294ed5a0ed05dbe2e83c7e0acd",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "url-signer@YOUR-PROJECT-ID.iam.gserviceaccount.com"
}
```

### How Your Backend Uses It

**In `backend/main.py:25-30`:**
```python
# Load the service account key
KEY_PATH = os.path.join(os.path.dirname(__file__), 'service-account-key.json')
if os.path.exists(KEY_PATH):
    storage_client = storage.Client.from_service_account_json(KEY_PATH)
```

Now `storage_client` can sign URLs using that private key!

---

## 🎨 Real Example Breakdown

Let's decode an actual signed URL from your app:

### The URL
```
https://storage.googleapis.com/YOUR-PROJECT-ID-music-uploads/uploads/20260211_184733_example.txt?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Credential=url-signer%40YOUR-PROJECT-ID.iam.gserviceaccount.com%2F20260211%2Fauto%2Fstorage%2Fgoog4_request&X-Goog-Date=20260211T184733Z&X-Goog-Expires=900&X-Goog-SignedHeaders=content-type%3Bhost&X-Goog-Signature=b9aff5a0c0341682...
```

### Decoded Components

| Parameter | Value | Meaning |
|-----------|-------|---------|
| **Base URL** | `storage.googleapis.com/bucket/file.txt` | Where to upload |
| **X-Goog-Algorithm** | `GOOG4-RSA-SHA256` | RSA signature with SHA-256 hash |
| **X-Goog-Credential** | `url-signer@project.iam...` | Which service account signed it |
| **X-Goog-Date** | `20260211T184733Z` | Created at 18:47:33 UTC on Feb 11, 2026 |
| **X-Goog-Expires** | `900` | Valid for 900 seconds (15 minutes) |
| **X-Goog-SignedHeaders** | `content-type;host` | These headers are part of signature |
| **X-Goog-Signature** | `b9aff5a0c034...` | The cryptographic signature (long hex) |

### Timeline

```
18:47:33 → URL created
18:47:34 → Valid ✓
18:50:00 → Valid ✓
19:02:32 → Valid ✓ (last second!)
19:02:33 → EXPIRED ✗ (15 minutes have passed)
```

---

## 💡 Why This Is Brilliant

### Traditional Approach (Bad)
```
Browser → Upload 50MB → Backend receives → Backend uploads 50MB → Cloud Storage
```
- Backend handles 50MB (expensive!)
- Slower for user (double network hop)
- Backend needs to scale for upload traffic

### Signed URL Approach (Good!)
```
Browser → Request URL (1KB) → Backend generates → Browser → Upload 50MB directly → Cloud Storage
```
- Backend only handles 1KB request
- Faster for user (direct to storage)
- Backend doesn't need to scale
- **99% cost reduction!**

### Security Comparison

| Approach | Security |
|----------|----------|
| **Make bucket public** | ❌ Anyone can upload/download anything |
| **Give users credentials** | ❌ Users can do ANYTHING in your GCP project |
| **Upload through backend** | ✓ Secure but expensive |
| **Signed URLs** | ✅ Secure AND efficient! |

Signed URLs are:
- ✓ Time-limited (15 minutes)
- ✓ Operation-specific (only PUT, not DELETE)
- ✓ Path-specific (only one file)
- ✓ Can't be forged (cryptographically signed)
- ✓ Don't expose credentials

---

## 🧪 Try It Yourself!

### Generate a Signed URL
```bash
curl -X POST 'https://YOUR-PROJECT-ID.uc.r.appspot.com/api/generate-signed-url' \
  -H 'Content-Type: application/json' \
  -d '{"filename": "test.txt", "content_type": "text/plain"}' | jq .
```

### Use the Signed URL
```bash
# Save the URL
SIGNED_URL="..." # paste from above

# Create a test file
echo "Hello from signed URL!" > test.txt

# Upload it!
curl -X PUT "$SIGNED_URL" \
  -H 'Content-Type: text/plain' \
  --data-binary @test.txt

# Check if it worked
curl https://YOUR-PROJECT-ID.uc.r.appspot.com/api/list-files | jq .
```

### See It Expire
```bash
# Generate a URL
SIGNED_URL=$(curl -s ... | jq -r '.signed_url')

# Wait 16 minutes ☕

# Try to use it
curl -X PUT "$SIGNED_URL" ... 
# → 403 Forbidden: "Request has expired"
```

---

## 📚 Learn More

- **Your code:** `backend/main.py` (lines 48-93)
- **Terraform:** `main.tf` (lines 82-113)
- **Frontend:** `frontend/upload.js` (lines 66-84)
- **Google Docs:** https://cloud.google.com/storage/docs/access-control/signed-urls

---

## 🎯 Key Takeaways

1. **Signed URLs = Temporary authorized access**
   - Like a one-time building pass

2. **Cryptographic signatures prove authorization**
   - Can't be forged without private key

3. **Parameters are strictly enforced**
   - Method, path, expiration, content-type

4. **Massive performance benefit**
   - Files never touch your backend

5. **Perfect for the GCP exam!**
   - This is THE answer for direct browser uploads

**You now understand one of GCP's most important patterns!** 🚀
