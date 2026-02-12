# How to View Signed URLs and Resumable URLs

## Method 1: Use the Web Interface (Easiest - Visual)

### Step 1: Start the Frontend
```bash
cd "/Users/shankar/Documents/GCP Projects - Signed URL/frontend"
python3 -m http.server 8000
```

### Step 2: Open Browser
Open http://localhost:8000

### Step 3: View URLs in Browser DevTools

1. **Open Developer Tools** (F12 or Right-click → Inspect)
2. **Go to Network tab**
3. **Set Backend URL** to: `https://YOUR-PROJECT-ID.uc.r.appspot.com`
4. **Select a file** to upload
5. **Watch the Network tab** - you'll see:
   - First request: `generate-signed-url` (or `generate-resumable-url`)
   - Click on it → Response tab → You'll see the full signed URL!
   - Second request: The actual upload to `storage.googleapis.com`

The signed URL will be visible in the Response JSON!

---

## Method 2: Use cURL (Direct API Calls)

### Generate Standard Signed URL

```bash
curl -X POST 'https://YOUR-PROJECT-ID.uc.r.appspot.com/api/generate-signed-url' \
  -H 'Content-Type: application/json' \
  -d '{
    "filename": "my-test-file.txt",
    "content_type": "text/plain"
  }' | jq .
```

**Response Example:**
```json
{
  "signed_url": "https://storage.googleapis.com/YOUR-PROJECT-ID-music-uploads/uploads/20260211_180000_my-test-file.txt?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Credential=url-signer%40YOUR-PROJECT-ID.iam.gserviceaccount.com%2F20260211%2Fauto%2Fstorage%2Fgoog4_request&X-Goog-Date=20260211T180000Z&X-Goog-Expires=900&X-Goog-SignedHeaders=content-type%3Bhost&X-Goog-Signature=abc123...",
  "filename": "uploads/20260211_180000_my-test-file.txt",
  "method": "PUT",
  "content_type": "text/plain",
  "expires_in": "15 minutes",
  "instructions": "Use PUT method to upload file directly to this URL"
}
```

### Generate Resumable Upload URL

```bash
curl -X POST 'https://YOUR-PROJECT-ID.uc.r.appspot.com/api/generate-resumable-url' \
  -H 'Content-Type: application/json' \
  -d '{
    "filename": "large-file.zip",
    "content_type": "application/zip"
  }' | jq .
```

**Response Example:**
```json
{
  "resumable_url": "https://storage.googleapis.com/upload/storage/v1/b/YOUR-PROJECT-ID-music-uploads/o?uploadType=resumable&upload_id=ABPtcPo...",
  "filename": "uploads/20260211_180000_large-file.zip",
  "method": "PUT",
  "content_type": "application/zip",
  "timeout": "1 hour",
  "instructions": "Use PUT method to upload chunks. Supports pause/resume."
}
```

---

## Method 3: Interactive Demo Script

I'll create a script that shows you the URLs step-by-step:

```bash
cd "/Users/shankar/Documents/GCP Projects - Signed URL"
./view-urls-demo.sh
```

---

## Method 4: Use Postman or Similar Tools

### Import into Postman:

**Standard Signed URL Request:**
- **Method:** POST
- **URL:** `https://YOUR-PROJECT-ID.uc.r.appspot.com/api/generate-signed-url`
- **Headers:** `Content-Type: application/json`
- **Body (raw JSON):**
  ```json
  {
    "filename": "test.mp3",
    "content_type": "audio/mpeg"
  }
  ```

**Resumable URL Request:**
- **Method:** POST
- **URL:** `https://YOUR-PROJECT-ID.uc.r.appspot.com/api/generate-resumable-url`
- **Headers:** `Content-Type: application/json`
- **Body (raw JSON):**
  ```json
  {
    "filename": "large-video.mp4",
    "content_type": "video/mp4"
  }
  ```

---

## Understanding the Signed URL Components

When you see a signed URL, it looks like this:

```
https://storage.googleapis.com/BUCKET/FILE?
  X-Goog-Algorithm=GOOG4-RSA-SHA256          ← Signing algorithm
  &X-Goog-Credential=SA@PROJECT.iam...       ← Service account
  &X-Goog-Date=20260211T180000Z              ← Timestamp
  &X-Goog-Expires=900                        ← Valid for 900 seconds (15 min)
  &X-Goog-SignedHeaders=content-type;host    ← Signed headers
  &X-Goog-Signature=abc123...                ← Cryptographic signature
```

### Key Parts:
- **Base URL:** `storage.googleapis.com/BUCKET/FILE`
- **Expires:** 900 seconds = 15 minutes
- **Signature:** Proves this is authorized
- **Once you have this URL:** Anyone can upload to it (until expiration)

---

## Understanding the Resumable URL

Resumable URLs look different:

```
https://storage.googleapis.com/upload/storage/v1/b/BUCKET/o?
  uploadType=resumable
  &upload_id=ABPtcPo...                      ← Unique session ID
```

### Key Differences:
- **Session-based:** Not time-limited like signed URLs (1 hour default)
- **Supports chunks:** Can upload in pieces
- **Resumable:** If interrupted, can continue from where it stopped

---

## Complete Example: See URLs and Use Them

```bash
#!/bin/bash

echo "=== STANDARD SIGNED URL ==="
echo ""

# Step 1: Generate
echo "1. Generating signed URL..."
RESPONSE=$(curl -s -X POST 'https://YOUR-PROJECT-ID.uc.r.appspot.com/api/generate-signed-url' \
  -H 'Content-Type: application/json' \
  -d '{"filename": "demo.txt", "content_type": "text/plain"}')

echo "$RESPONSE" | jq .

# Step 2: Extract URL
SIGNED_URL=$(echo "$RESPONSE" | jq -r '.signed_url')
echo ""
echo "2. Signed URL:"
echo "$SIGNED_URL"
echo ""

# Step 3: Upload
echo "3. Uploading file..."
echo "Hello from signed URL!" > /tmp/demo.txt
curl -X PUT "$SIGNED_URL" \
  -H 'Content-Type: text/plain' \
  --data-binary @/tmp/demo.txt

echo ""
echo "✅ Upload complete!"
echo ""
echo "=== RESUMABLE URL ==="
echo ""

# Resumable URL
RESUMABLE=$(curl -s -X POST 'https://YOUR-PROJECT-ID.uc.r.appspot.com/api/generate-resumable-url' \
  -H 'Content-Type: application/json' \
  -d '{"filename": "large.txt", "content_type": "text/plain"}')

echo "Resumable URL:"
echo "$RESUMABLE" | jq .
```

---

## Quick Reference Commands

### Generate and Pretty Print Standard URL
```bash
curl -s -X POST 'https://YOUR-PROJECT-ID.uc.r.appspot.com/api/generate-signed-url' \
  -H 'Content-Type: application/json' \
  -d '{"filename": "test.txt", "content_type": "text/plain"}' | jq .
```

### Extract Just the URL
```bash
curl -s -X POST 'https://YOUR-PROJECT-ID.uc.r.appspot.com/api/generate-signed-url' \
  -H 'Content-Type: application/json' \
  -d '{"filename": "test.txt", "content_type": "text/plain"}' | jq -r '.signed_url'
```

### Generate and Save to Variable
```bash
SIGNED_URL=$(curl -s -X POST 'https://YOUR-PROJECT-ID.uc.r.appspot.com/api/generate-signed-url' \
  -H 'Content-Type: application/json' \
  -d '{"filename": "test.txt", "content_type": "text/plain"}' | jq -r '.signed_url')

echo "URL saved: $SIGNED_URL"
```

---

## Try It Now!

Run this simple one-liner to see a signed URL:

```bash
curl -X POST 'https://YOUR-PROJECT-ID.uc.r.appspot.com/api/generate-signed-url' \
  -H 'Content-Type: application/json' \
  -d '{"filename": "quick-test.txt", "content_type": "text/plain"}' | jq .
```

You should see the full signed URL in the response!
