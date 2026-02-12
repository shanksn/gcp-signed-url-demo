# Learning Guide: Cloud Storage Signed URLs

This document explains the key concepts behind direct browser uploads to Google Cloud Storage.

## The Problem

You have a web application where users upload files (music, images, videos). Traditionally:

```
Browser → Backend Server → Cloud Storage
         (uploads file)   (saves file)
```

**Problems with this approach:**
- Backend handles large file transfers (expensive bandwidth)
- Backend needs to scale for upload traffic
- Slower for users (double network hop)
- More complex backend code

## The Solution: Signed URLs

Allow browsers to upload **directly** to Cloud Storage:

```
Browser → Backend API → Returns signed URL
Browser → Cloud Storage (uploads directly using signed URL)
```

**Benefits:**
- Backend only generates URLs (tiny payload)
- Files never touch your servers
- Faster uploads for users
- Lower costs and complexity

## How Signed URLs Work

### 1. What is a Signed URL?

A signed URL is a time-limited, authenticated URL that grants temporary access to perform a specific operation.

**Example:**
```
https://storage.googleapis.com/my-bucket/song.mp3
  ?X-Goog-Algorithm=GOOG4-RSA-SHA256
  &X-Goog-Credential=signer@project.iam.gserviceaccount.com/20240211/auto/storage/goog4_request
  &X-Goog-Date=20240211T120000Z
  &X-Goog-Expires=900
  &X-Goog-SignedHeaders=content-type;host
  &X-Goog-Signature=abc123...
```

**Components:**
- **Algorithm**: Signing algorithm (RSA-SHA256)
- **Credential**: Service account used to sign
- **Date**: When the URL was created
- **Expires**: How long the URL is valid (900 seconds = 15 minutes)
- **Signature**: Cryptographic signature proving authenticity

### 2. The Signing Process

```python
# Backend generates signed URL
blob = bucket.blob('uploads/song.mp3')
signed_url = blob.generate_signed_url(
    version="v4",
    expiration=timedelta(minutes=15),
    method="PUT",
    content_type="audio/mpeg"
)
```

**What happens:**
1. Service account private key signs the request parameters
2. Creates a URL that proves "this request is authorized"
3. Anyone with this URL can upload for 15 minutes
4. After 15 minutes, the URL becomes invalid

### 3. Security

**Q: If anyone with the URL can upload, isn't that insecure?**

A: The URL is:
- **Time-limited** (typically 15 minutes)
- **Operation-specific** (only PUT, not delete)
- **Object-specific** (only this exact file path)
- **Generated on-demand** (unique per upload)

So even if intercepted, the attacker can only upload to that specific location for a short time.

## CORS Configuration

For browsers to upload directly, Cloud Storage needs CORS enabled:

```terraform
cors {
  origin          = ["https://myapp.com"]
  method          = ["PUT", "POST", "OPTIONS"]
  response_header = ["Content-Type"]
  max_age_seconds = 3600
}
```

**Why CORS?**

Browsers enforce the **Same-Origin Policy**: JavaScript can only make requests to the same domain. To upload to `storage.googleapis.com` from `myapp.com`, you need CORS headers that say "yes, myapp.com is allowed".

## Upload Methods Comparison

### Standard Signed URL (PUT)

**Best for:** Small to medium files (up to 100MB)

```javascript
// 1. Get signed URL from backend
const response = await fetch('/api/generate-signed-url', {
    method: 'POST',
    body: JSON.stringify({ filename: 'song.mp3' })
});
const { signed_url } = await response.json();

// 2. Upload directly to GCS
await fetch(signed_url, {
    method: 'PUT',
    headers: { 'Content-Type': 'audio/mpeg' },
    body: file
});
```

**Pros:**
- Simple, single request
- Works everywhere
- Easy progress tracking

**Cons:**
- No pause/resume
- If network fails, restart from beginning

### Resumable Upload

**Best for:** Large files (>100MB)

```javascript
// 1. Get resumable URL from backend
const response = await fetch('/api/generate-resumable-url', {
    method: 'POST',
    body: JSON.stringify({ filename: 'album.zip' })
});
const { resumable_url } = await response.json();

// 2. Upload in chunks
const chunkSize = 256 * 1024; // 256 KB chunks
let offset = 0;
while (offset < file.size) {
    const chunk = file.slice(offset, offset + chunkSize);
    await fetch(resumable_url, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/zip',
            'Content-Range': `bytes ${offset}-${offset + chunk.size - 1}/${file.size}`
        },
        body: chunk
    });
    offset += chunkSize;
}
```

**Pros:**
- Can pause and resume
- Survives network interruptions
- Better for large files

**Cons:**
- More complex
- Requires chunking logic

## Real-World Example: Music Sharing App

**User Story:** Sarah wants to upload her band's new album to share with fans.

### Without Signed URLs:
1. Sarah selects 50MB file
2. Browser uploads to App Engine backend
3. Backend receives 50MB, uses CPU/memory/bandwidth
4. Backend uploads 50MB to Cloud Storage
5. App Engine charged for:
   - Instance hours (processing)
   - Network egress (50MB out to GCS)

**Cost:** ~$0.01 per upload × 10,000 users = $100/month

### With Signed URLs:
1. Sarah selects 50MB file
2. Browser requests signed URL (tiny request)
3. Backend generates URL (milliseconds, tiny response)
4. Browser uploads 50MB directly to Cloud Storage
5. App Engine charged for:
   - Tiny API request (negligible)

**Cost:** ~$0.0001 per upload × 10,000 users = $1/month

**Savings: 99%** 💰

## Common Patterns

### Pattern 1: Pre-validate file type

```python
ALLOWED_TYPES = ['audio/mpeg', 'audio/wav', 'audio/ogg']

@app.route('/api/generate-signed-url', methods=['POST'])
def generate_signed_url():
    content_type = request.json.get('content_type')

    if content_type not in ALLOWED_TYPES:
        return jsonify({'error': 'Invalid file type'}), 400

    # Generate URL only for valid types...
```

### Pattern 2: Enforce file size limits

```python
blob.generate_signed_post_policy_v4(
    conditions=[
        ["content-length-range", 0, 104857600]  # Max 100MB
    ]
)
```

### Pattern 3: Organize uploads by user

```python
user_id = get_current_user_id()
timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
filename = f"uploads/{user_id}/{timestamp}_{filename}"
```

## Exam Tips

**Question pattern:** "Allow users to upload files directly from browser without passing through backend"

**Answer components:**
1. ✅ Set CORS configuration on bucket
2. ✅ Use signed URLs
3. ✅ Backend generates URLs, browser uploads directly

**Wrong answers to watch for:**
- ❌ Upload through backend then to GCS (defeats purpose)
- ❌ Make bucket public (security risk)
- ❌ Give users service account keys (major security risk)

## Further Reading

- [GCP Signed URLs Documentation](https://cloud.google.com/storage/docs/access-control/signed-urls)
- [CORS Configuration](https://cloud.google.com/storage/docs/cross-origin)
- [Cloud Storage Best Practices](https://cloud.google.com/storage/docs/best-practices)
- [Resumable Uploads](https://cloud.google.com/storage/docs/resumable-uploads)

## Quiz Yourself

1. **Why use signed URLs instead of making the bucket public?**
   <details>
   <summary>Answer</summary>
   Public buckets allow anyone to read/write anytime. Signed URLs grant temporary, specific access only for intended operations.
   </details>

2. **What's the minimum expiration time for a signed URL?**
   <details>
   <summary>Answer</summary>
   1 second. But typically use 15 minutes for uploads to give users enough time.
   </details>

3. **Can you use the same signed URL multiple times?**
   <details>
   <summary>Answer</summary>
   Yes, until it expires. But best practice is to generate a new URL for each upload.
   </details>

4. **What happens if upload takes longer than the signed URL expiration?**
   <details>
   <summary>Answer</summary>
   Upload will fail. For large files, use resumable uploads which have longer timeouts (hours).
   </details>

5. **Why do we need CORS for browser uploads?**
   <details>
   <summary>Answer</summary>
   Browsers block cross-origin requests by default. CORS headers tell the browser "yes, storage.googleapis.com allows requests from your app's domain".
   </details>
