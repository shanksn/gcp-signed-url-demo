# Firebase Authentication Setup Guide

## 🎯 What We're Building

Add Google Sign-In to your app so that:
- ✅ Only authenticated users can request signed URLs
- ✅ Files are organized by user ID
- ✅ You know who uploaded what
- ✅ Backend is protected from abuse

## 📋 Step-by-Step Setup

### Step 1: Enable Firebase in Your GCP Project (5 min)

**Option A: Using Firebase Console (Recommended)**

1. Go to https://console.firebase.google.com/
2. Click "Add project"
3. Select existing project: **biotechproject-483505**
4. Click "Continue"
5. Disable Google Analytics (not needed for this demo)
6. Click "Add Firebase"

**Option B: Using gcloud CLI**

```bash
# Enable Firebase Management API
gcloud services enable firebase.googleapis.com --project=biotechproject-483505

# This creates a Firebase project linked to your GCP project
```

### Step 2: Enable Authentication

1. In Firebase Console → Build → Authentication
2. Click "Get Started"
3. Go to "Sign-in method" tab
4. Enable **Google** provider:
   - Click on "Google"
   - Toggle "Enable"
   - Add support email (your email)
   - Click "Save"

### Step 3: Register Your Web App

1. In Firebase Console → Project Overview (gear icon) → Project settings
2. Scroll down to "Your apps"
3. Click the **Web** icon (`</>`)
4. Give it a name: "Signed URL Demo"
5. **Don't** check "Also set up Firebase Hosting"
6. Click "Register app"
7. **Copy the firebaseConfig object** - you'll need this!

It will look like:
```javascript
const firebaseConfig = {
  apiKey: "AIza...",
  authDomain: "biotechproject-483505.firebaseapp.com",
  projectId: "biotechproject-483505",
  storageBucket: "biotechproject-483505.appspot.com",
  messagingSenderId: "...",
  appId: "1:..."
};
```

8. Click "Continue to console"

### Step 4: Get Service Account Key for Backend

**Your existing service account can be used!**

The service account you created with Terraform (`url-signer@biotechproject-483505.iam.gserviceaccount.com`) can also verify Firebase tokens.

No additional setup needed - we'll use the existing `service-account-key.json`!

---

## 🔧 Implementation

### Step 5: Update Backend Dependencies

```bash
cd backend
```

Edit `requirements.txt`:
```txt
Flask==3.0.0
flask-cors==4.0.0
google-cloud-storage==2.14.0
gunicorn==21.2.0
firebase-admin==6.4.0  # ADD THIS LINE
```

Install locally:
```bash
pip install -r requirements.txt
```

### Step 6: Update Backend Code

Create a new file `backend/auth.py`:

```python
"""
Firebase Authentication middleware for Flask
"""
import firebase_admin
from firebase_admin import credentials, auth
from flask import request, jsonify
import functools
import os

# Initialize Firebase Admin SDK
KEY_PATH = os.path.join(os.path.dirname(__file__), 'service-account-key.json')
cred = credentials.Certificate(KEY_PATH)
firebase_admin.initialize_app(cred)

def require_auth(f):
    """
    Decorator to require Firebase authentication for a route.

    Usage:
        @app.route('/api/protected')
        @require_auth
        def protected_route(user):
            # user is the decoded Firebase token
            user_id = user['uid']
            user_email = user.get('email')
            # ...
    """
    @functools.wraps(f)
    def decorated_function(*args, **kwargs):
        # Get the ID token from Authorization header
        auth_header = request.headers.get('Authorization', '')

        if not auth_header.startswith('Bearer '):
            return jsonify({'error': 'Missing or invalid Authorization header'}), 401

        id_token = auth_header.replace('Bearer ', '')

        try:
            # Verify the ID token
            decoded_token = auth.verify_id_token(id_token)

            # Pass the user info to the route
            return f(decoded_token, *args, **kwargs)

        except Exception as e:
            return jsonify({'error': f'Invalid token: {str(e)}'}), 401

    return decorated_function
```

Now update `backend/main.py`:

```python
# At the top, add this import
from auth import require_auth

# Update the generate_signed_url function
@app.route('/api/generate-signed-url', methods=['POST'])
@require_auth  # ADD THIS DECORATOR
def generate_signed_url(user):  # ADD user PARAMETER
    """
    Generate a standard signed URL for PUT method upload.
    Now requires authentication!
    """
    try:
        # Extract user info
        user_id = user['uid']
        user_email = user.get('email', 'unknown')

        data = request.get_json()
        filename = data.get('filename')
        content_type = data.get('content_type', 'application/octet-stream')

        if not filename:
            return jsonify({'error': 'filename is required'}), 400

        # Generate unique filename with user ID!
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        unique_filename = f"uploads/{user_id}/{timestamp}_{filename}"  # CHANGED

        # Log who's uploading
        print(f"User {user_email} ({user_id}) uploading {filename}")

        bucket = storage_client.bucket(BUCKET_NAME)
        blob = bucket.blob(unique_filename)

        # Generate signed URL valid for 15 minutes
        url = blob.generate_signed_url(
            version="v4",
            expiration=timedelta(minutes=15),
            method="PUT",
            content_type=content_type
        )

        return jsonify({
            'signed_url': url,
            'filename': unique_filename,
            'method': 'PUT',
            'content_type': content_type,
            'expires_in': '15 minutes',
            'user': user_email,  # NEW: Tell user who they are
            'instructions': 'Use PUT method to upload file directly to this URL'
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Also update the resumable URL endpoint the same way
@app.route('/api/generate-resumable-url', methods=['POST'])
@require_auth  # ADD THIS
def generate_resumable_url(user):  # ADD user PARAMETER
    # ... same updates as above ...
```

### Step 7: Update Frontend

Create `frontend/firebase-config.js`:

```javascript
// Firebase configuration
// REPLACE WITH YOUR CONFIG FROM STEP 3!
const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "biotechproject-483505.firebaseapp.com",
  projectId: "biotechproject-483505",
  storageBucket: "biotechproject-483505.appspot.com",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "YOUR_APP_ID"
};

export default firebaseConfig;
```

Update `frontend/index.html` - add Firebase SDK and login UI:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <!-- existing head content -->
</head>
<body>
    <div class="container">
        <h1>Cloud Storage Upload Demo</h1>
        <p class="subtitle">Now with Firebase Authentication!</p>

        <!-- ADD LOGIN SECTION -->
        <div id="auth-section">
            <div id="logged-out" class="auth-state">
                <p>Please sign in to upload files</p>
                <button id="sign-in-btn">Sign in with Google</button>
            </div>

            <div id="logged-in" class="auth-state" style="display: none;">
                <p>Signed in as: <span id="user-email"></span></p>
                <button id="sign-out-btn">Sign Out</button>
            </div>
        </div>

        <!-- Rest of your existing HTML -->
        <!-- Upload section will be hidden until logged in -->

    </div>

    <!-- ADD FIREBASE SDK -->
    <script type="module">
        import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js';
        import { getAuth, signInWithPopup, GoogleAuthProvider, signOut, onAuthStateChanged } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js';
        import firebaseConfig from './firebase-config.js';

        // Initialize Firebase
        const app = initializeApp(firebaseConfig);
        const auth = getAuth(app);
        const provider = new GoogleAuthProvider();

        // Global variable for current user token
        window.currentUserToken = null;

        // Sign in button
        document.getElementById('sign-in-btn').addEventListener('click', async () => {
            try {
                const result = await signInWithPopup(auth, provider);
                console.log('Signed in:', result.user.email);
            } catch (error) {
                console.error('Sign in error:', error);
                alert('Sign in failed: ' + error.message);
            }
        });

        // Sign out button
        document.getElementById('sign-out-btn').addEventListener('click', async () => {
            try {
                await signOut(auth);
                console.log('Signed out');
            } catch (error) {
                console.error('Sign out error:', error);
            }
        });

        // Listen for auth state changes
        onAuthStateChanged(auth, async (user) => {
            if (user) {
                // User is signed in
                document.getElementById('logged-out').style.display = 'none';
                document.getElementById('logged-in').style.display = 'block';
                document.getElementById('user-email').textContent = user.email;

                // Get and store the ID token
                window.currentUserToken = await user.getIdToken();

                // Show upload interface
                document.querySelector('.tabs').style.display = 'flex';

            } else {
                // User is signed out
                document.getElementById('logged-out').style.display = 'block';
                document.getElementById('logged-in').style.display = 'none';
                window.currentUserToken = null;

                // Hide upload interface
                document.querySelector('.tabs').style.display = 'none';
            }
        });
    </script>

    <script src="upload.js"></script>
</body>
</html>
```

Update `frontend/upload.js` to include auth token:

```javascript
// At the top of the file, update the fetch calls to include auth token

async function generateSignedUrl(backendUrl, filename, contentType) {
    // Check if user is logged in
    if (!window.currentUserToken) {
        throw new Error('Please sign in first');
    }

    const response = await fetch(`${backendUrl}/api/generate-signed-url`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${window.currentUserToken}`  // ADD THIS
        },
        body: JSON.stringify({
            filename: filename,
            content_type: contentType
        })
    });

    if (!response.ok) {
        const error = await response.json();
        throw new Error(error.error || 'Failed to generate signed URL');
    }

    return await response.json();
}

// Update your existing code to use this function
```

---

## 🧪 Testing

### Test 1: Start Backend Locally

```bash
cd backend
export BUCKET_NAME=biotechproject-483505-music-uploads
export SERVICE_ACCOUNT_EMAIL=url-signer@biotechproject-483505.iam.gserviceaccount.com
python main.py
```

### Test 2: Start Frontend Locally

```bash
cd frontend
python3 -m http.server 8000
```

Open http://localhost:8000

### Test 3: Try Without Login

Try to upload → Should see "Please sign in first"

### Test 4: Sign In with Google

1. Click "Sign in with Google"
2. Choose your Google account
3. Grant permission
4. You should see "Signed in as: your@email.com"

### Test 5: Upload a File

1. Select a file
2. Click Upload
3. Should work! Check the response to see your email

### Test 6: Check File Organization

```bash
gsutil ls gs://biotechproject-483505-music-uploads/uploads/

# You should see folders organized by user ID:
# gs://biotechproject-483505-music-uploads/uploads/abc123.../
```

---

## 🚀 Deploy to Production

### Update backend/requirements.txt

Already done! (added firebase-admin)

### Deploy Backend

```bash
cd backend
gcloud app deploy
```

### Test Production

1. Get your App Engine URL
2. Update frontend to use production URL
3. Sign in and upload - it works!

---

## 🔒 Security Verification

### Test Unauthorized Access

```bash
# Try without token - should FAIL
curl -X POST 'https://biotechproject-483505.uc.r.appspot.com/api/generate-signed-url' \
  -H 'Content-Type: application/json' \
  -d '{"filename": "test.txt"}'

# Response: {"error": "Missing or invalid Authorization header"}
# ✅ SUCCESS! Backend is now protected
```

### Test with Valid Token

```bash
# Get a token (from browser console after logging in)
TOKEN="eyJhbGciOi..."  # Copy from browser

curl -X POST 'https://biotechproject-483505.uc.r.appspot.com/api/generate-signed-url' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer '$TOKEN \
  -d '{"filename": "test.txt"}'

# Response: {"signed_url": "...", "user": "your@email.com"}
# ✅ SUCCESS! Works with valid token
```

---

## 🎯 What You've Achieved

✅ **Backend is now secure**
   - Only authenticated users can request signed URLs
   - No more open access

✅ **Know who uploads what**
   - Files organized by user ID
   - Logs show user email

✅ **Better user experience**
   - Users sign in with Google
   - No passwords to remember

✅ **Production-ready auth**
   - Industry-standard Firebase
   - Scalable and secure

---

## 📚 Next Steps (Optional)

1. **Add user-specific quotas**
   - Limit uploads per user per day

2. **Add file listing**
   - Show only the user's files

3. **Add file deletion**
   - Let users delete their own files

4. **Add profile page**
   - Show user's uploads and usage

---

## 🐛 Troubleshooting

### "Firebase app not initialized"
- Make sure `auth.py` runs before route definitions
- Check service account key path

### "No 'Access-Control-Allow-Origin' header"
- CORS is already enabled in your `main.py`
- Make sure flask-cors is installed

### "Invalid token" in browser
- Token might be expired (tokens expire after 1 hour)
- Sign out and sign in again

### "Permission denied" on upload
- Firebase token is valid for backend auth
- But signed URL is what allows GCS upload
- Check both separately

---

## 💡 Understanding the Flow

```
1. User signs in with Google
   ↓
2. Firebase gives user an ID token
   ↓
3. Frontend includes token in API requests
   ↓
4. Backend verifies token with Firebase
   ↓
5. Backend generates signed URL (only if auth succeeds)
   ↓
6. Frontend uploads to GCS using signed URL
```

**Two separate security layers:**
- Firebase auth → Protects backend API
- Signed URL → Authorizes GCS upload

Perfect! 🎉
