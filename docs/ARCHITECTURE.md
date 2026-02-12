# Architecture Overview

## Flow Diagram: Standard Signed URL Upload

```
┌─────────────┐
│   Browser   │
│   (User)    │
└──────┬──────┘
       │
       │ 1. User selects file "song.mp3"
       │
       ▼
┌─────────────────────────────────────────────────────────┐
│  JavaScript (frontend/upload.js)                         │
│                                                          │
│  POST /api/generate-signed-url                          │
│  { "filename": "song.mp3", "content_type": "audio/mpeg" }│
└──────┬──────────────────────────────────────────────────┘
       │
       │ 2. Request signed URL
       │
       ▼
┌─────────────────────────────────────────────────────────┐
│  App Engine Backend (backend/main.py)                    │
│                                                          │
│  1. Validate request                                     │
│  2. Generate unique filename with timestamp              │
│  3. Create signed URL using service account              │
│     blob.generate_signed_url(method="PUT", ...)         │
│  4. Return signed URL to browser                         │
└──────┬──────────────────────────────────────────────────┘
       │
       │ 3. Returns signed URL
       │    (valid for 15 minutes)
       │
       ▼
┌─────────────────────────────────────────────────────────┐
│  Browser                                                 │
│                                                          │
│  Receives:                                               │
│  {                                                       │
│    "signed_url": "https://storage.googleapis.com/...",  │
│    "method": "PUT"                                       │
│  }                                                       │
└──────┬──────────────────────────────────────────────────┘
       │
       │ 4. Upload directly to GCS
       │    PUT request with file data
       │    ⚠️  Payload does NOT go through backend!
       │
       ▼
┌─────────────────────────────────────────────────────────┐
│  Cloud Storage Bucket                                    │
│                                                          │
│  1. Validates signed URL signature                       │
│  2. Checks expiration time                               │
│  3. Verifies CORS headers                                │
│  4. Stores file: uploads/20240211_123456_song.mp3       │
└──────┬──────────────────────────────────────────────────┘
       │
       │ 5. Returns 200 OK
       │
       ▼
┌─────────────┐
│   Browser   │
│             │
│  ✅ Success! │
└─────────────┘
```

## Component Details

### 1. Frontend (Browser)

**Location:** `frontend/`

**Responsibilities:**
- File selection UI
- Request signed URLs from backend
- Upload files directly to Cloud Storage
- Progress tracking
- Error handling

**Key Code:**
```javascript
// Get signed URL
const response = await fetch(`${backendUrl}/api/generate-signed-url`, {
    method: 'POST',
    body: JSON.stringify({ filename, content_type })
});
const { signed_url } = await response.json();

// Upload directly to GCS (bypasses backend!)
xhr.open('PUT', signed_url);
xhr.send(file);
```

### 2. Backend API (App Engine)

**Location:** `backend/main.py`

**Responsibilities:**
- Generate signed URLs using service account
- Validate file types and sizes
- Add timestamps to filenames
- Rate limiting (not implemented in demo)

**Key Code:**
```python
blob = bucket.blob(unique_filename)
signed_url = blob.generate_signed_url(
    version="v4",
    expiration=timedelta(minutes=15),
    method="PUT",
    content_type=content_type
)
```

**Important:** Backend never receives the actual file data!

### 3. Cloud Storage

**Configuration:** Set via Terraform in `main.tf`

**Key Settings:**
```terraform
cors {
  origin          = ["*"]
  method          = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
  response_header = ["Content-Type", "Content-Range"]
  max_age_seconds = 3600
}
```

**What CORS Does:**
- Allows browser JavaScript to make requests to different origin
- Without CORS: Browser blocks the upload
- With CORS: Browser allows upload to storage.googleapis.com

### 4. Service Account

**Purpose:** Signs URLs to prove authorization

**Permissions:**
- `roles/storage.objectAdmin` on the bucket
- Can create/delete/read objects
- Private key used to sign URLs

**Created by Terraform:**
```terraform
resource "google_service_account" "url_signer" {
  account_id   = "url-signer"
  display_name = "URL Signing Service Account"
}
```

## Security Flow

```
┌──────────────┐
│ Service      │
│ Account      │
│ Private Key  │
└──────┬───────┘
       │
       │ Signs URL with:
       │ - Timestamp
       │ - Expiration
       │ - HTTP method (PUT)
       │ - Resource path
       │
       ▼
┌─────────────────────────────────────────────────┐
│  Signed URL                                      │
│                                                  │
│  https://storage.googleapis.com/bucket/file     │
│    ?X-Goog-Algorithm=GOOG4-RSA-SHA256           │
│    &X-Goog-Credential=signer@project.iam...     │
│    &X-Goog-Date=20240211T120000Z                │
│    &X-Goog-Expires=900                          │
│    &X-Goog-Signature=abc123...                  │
└──────┬──────────────────────────────────────────┘
       │
       │ Browser uses this URL
       │
       ▼
┌─────────────────────────────────────────────────┐
│  Cloud Storage validates:                       │
│                                                  │
│  ✓ Signature matches (proves authorization)     │
│  ✓ Not expired (15 min limit)                   │
│  ✓ Method matches (PUT only)                    │
│  ✓ Path matches (specific file only)            │
│                                                  │
│  If all pass → Allow upload                     │
│  If any fail → 403 Forbidden                    │
└─────────────────────────────────────────────────┘
```

## Data Flow Comparison

### Traditional Upload (WITHOUT Signed URLs)

```
Browser ──── 50 MB ────→ App Engine ──── 50 MB ────→ Cloud Storage
             (slow)      (expensive!)     (storage)

Total network: 100 MB (50 MB × 2)
App Engine load: High (processes 50 MB)
Cost: High
```

### Direct Upload (WITH Signed URLs)

```
Browser ──── ~1 KB ────→ App Engine (generates URL)
  │                           │
  │                           └──── ~1 KB ────→ Browser
  │
  └──────── 50 MB ──────────────────────────────→ Cloud Storage
            (fast, direct)

Total network: 50 MB + ~2 KB
App Engine load: Minimal (only URL generation)
Cost: Low
```

**Key Insight:** The file data never touches App Engine!

## Infrastructure Components

```
GCP Project
│
├── Cloud Storage Bucket
│   ├── CORS Configuration
│   ├── Lifecycle Rules (30-day deletion)
│   └── Files: uploads/
│       ├── 20240211_120000_song1.mp3
│       ├── 20240211_120100_song2.mp3
│       └── ...
│
├── App Engine Application
│   ├── Python 3.12 Runtime
│   ├── Flask API
│   └── Endpoints:
│       ├── /api/generate-signed-url
│       ├── /api/generate-resumable-url
│       └── /api/list-files
│
├── Service Account (url-signer)
│   ├── Email: url-signer@project.iam.gserviceaccount.com
│   ├── Private Key (for signing URLs)
│   └── Permissions: roles/storage.objectAdmin
│
└── IAM Bindings
    └── url-signer → bucket (objectAdmin)
```

## Request/Response Examples

### 1. Generate Signed URL

**Request:**
```http
POST /api/generate-signed-url HTTP/1.1
Host: your-app.appspot.com
Content-Type: application/json

{
  "filename": "song.mp3",
  "content_type": "audio/mpeg"
}
```

**Response:**
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "signed_url": "https://storage.googleapis.com/my-bucket/uploads/20240211_120000_song.mp3?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Credential=url-signer%40project.iam.gserviceaccount.com%2F20240211%2Fauto%2Fstorage%2Fgoog4_request&X-Goog-Date=20240211T120000Z&X-Goog-Expires=900&X-Goog-SignedHeaders=content-type%3Bhost&X-Goog-Signature=abc123...",
  "filename": "uploads/20240211_120000_song.mp3",
  "method": "PUT",
  "content_type": "audio/mpeg",
  "expires_in": "15 minutes"
}
```

### 2. Upload to Cloud Storage

**Request:**
```http
PUT /my-bucket/uploads/20240211_120000_song.mp3?X-Goog-Algorithm=... HTTP/1.1
Host: storage.googleapis.com
Content-Type: audio/mpeg
Content-Length: 52428800

[... 50 MB of file data ...]
```

**Response:**
```http
HTTP/1.1 200 OK
Content-Length: 0
```

## Error Scenarios

### Expired Signed URL
```
Browser → GCS (with expired URL)
        ← 403 Forbidden
          {"error": "Expired signature"}
```

### CORS Not Configured
```
Browser → GCS (upload request)
        ← (blocked by browser before reaching GCS)
Console: "CORS policy: No 'Access-Control-Allow-Origin' header"
```

### Invalid Signature
```
Browser → GCS (with tampered URL)
        ← 403 Forbidden
          {"error": "Invalid signature"}
```

## Performance Metrics

### Traditional Upload
- **Latency:** 2× network round trips
- **Backend CPU:** High (file processing)
- **Backend Memory:** High (buffering file)
- **Scalability:** Limited by backend

### Signed URL Upload
- **Latency:** 1 network round trip (after getting URL)
- **Backend CPU:** Minimal (URL generation only)
- **Backend Memory:** Minimal (~KB per request)
- **Scalability:** Limited by GCS (extremely high)

## Cost Breakdown (10,000 uploads of 50MB files)

### Traditional Approach
```
App Engine:
- Instance hours: 100 hours @ $0.05/hr = $5.00
- Network egress: 500 GB @ $0.12/GB = $60.00

Cloud Storage:
- Storage: 500 GB @ $0.02/GB = $10.00

Total: $75.00/month
```

### Signed URL Approach
```
App Engine:
- Instance hours: 1 hour @ $0.05/hr = $0.05
- Network egress: ~1 MB @ $0.12/GB ≈ $0.00

Cloud Storage:
- Storage: 500 GB @ $0.02/GB = $10.00

Total: $10.05/month
```

**Savings: $64.95/month (87%)**

## Terraform-Managed Resources

All infrastructure is defined as code in `main.tf`:

```
terraform apply
     │
     ├── Creates bucket with CORS
     ├── Creates service account
     ├── Grants permissions
     ├── Generates private key
     └── Provisions App Engine app

terraform destroy
     │
     └── Deletes everything (except App Engine app)
```

## Summary

**This architecture demonstrates:**
1. ✅ Direct browser-to-storage uploads
2. ✅ Backend generates auth tokens (signed URLs)
3. ✅ CORS enables cross-origin requests
4. ✅ Scalable and cost-effective
5. ✅ Secure with time-limited access

**Perfect for:** File uploads, music sharing, photo galleries, document management, any scenario where users upload files to the cloud.
