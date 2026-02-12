# Firebase Authentication - Testing Guide

## ✅ What's Been Set Up

1. ✅ Firebase enabled in your GCP project
2. ✅ Firebase config added to frontend
3. ✅ Backend updated to require authentication
4. ✅ Frontend updated with login UI
5. ✅ All uploads now require sign-in!

## 🧪 Test Locally

### Step 1: Install Backend Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### Step 2: Start Backend

```bash
cd backend
export BUCKET_NAME=biotechproject-483505-music-uploads
export SERVICE_ACCOUNT_EMAIL=url-signer@biotechproject-483505.iam.gserviceaccount.com
python main.py
```

**You should see:**
```
✅ Firebase Admin SDK initialized successfully
 * Running on http://127.0.0.1:8080
```

### Step 3: Start Frontend

```bash
cd frontend
python3 -m http.server 8000
```

### Step 4: Open the Auth-Enabled UI

Open: **http://localhost:8000/index-with-auth.html**

### Step 5: Test Authentication Flow

#### Test 1: Try Without Login
1. You should see "🔐 Please sign in to upload files"
2. Upload sections are locked 🔒
3. ✅ **EXPECTED:** Interface is locked

#### Test 2: Sign In
1. Click "Sign in with Google"
2. Choose your Google account
3. Grant permission
4. ✅ **EXPECTED:** You see your photo and email
5. ✅ **EXPECTED:** Upload interface unlocks 🔓

#### Test 3: Upload a File (Authenticated)
1. Select a file
2. Click "Upload File"
3. ✅ **EXPECTED:** Upload succeeds!
4. Check the response - should include your email

#### Test 4: Check File Organization
```bash
gsutil ls gs://biotechproject-483505-music-uploads/uploads/
```

✅ **EXPECTED:** Files organized by user ID!
```
gs://biotechproject-483505-music-uploads/uploads/YOUR_USER_ID_HERE/
gs://biotechproject-483505-music-uploads/uploads/YOUR_USER_ID_HERE/20260211_120000_yourfile.txt
```

#### Test 5: Sign Out
1. Click "Sign Out"
2. ✅ **EXPECTED:** Interface locks again
3. ✅ **EXPECTED:** Can't upload anymore

### Step 6: Test API Security (Command Line)

#### Test Without Token (Should Fail)
```bash
curl -X POST 'http://localhost:8080/api/generate-signed-url' \
  -H 'Content-Type: application/json' \
  -d '{"filename": "test.txt", "content_type": "text/plain"}'
```

✅ **EXPECTED:**
```json
{
  "error": "Missing or invalid Authorization header",
  "hint": "Include: Authorization: Bearer YOUR_FIREBASE_TOKEN"
}
```

**🎉 SUCCESS! Backend is now protected!**

#### Test With Valid Token (Should Work)
1. Sign in to frontend
2. Open browser console (F12)
3. Type: `window.currentUserToken`
4. Copy the token

```bash
TOKEN="paste-token-here"

curl -X POST 'http://localhost:8080/api/generate-signed-url' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"filename": "test.txt", "content_type": "text/plain"}'
```

✅ **EXPECTED:** Returns signed URL with your email!

---

## 🚀 Deploy to Production

### Step 1: Deploy Backend

```bash
cd backend
gcloud app deploy --project=biotechproject-483505
```

**Wait 2-3 minutes for deployment...**

### Step 2: Test Production API

```bash
# Test without auth - should FAIL
curl -X POST 'https://biotechproject-483505.uc.r.appspot.com/api/generate-signed-url' \
  -H 'Content-Type: application/json' \
  -d '{"filename": "test.txt"}'

# Response: {"error": "Missing or invalid Authorization header"}
# ✅ Backend is secure!
```

### Step 3: Use Frontend with Production

1. Open `index-with-auth.html`
2. Change Backend URL to: `https://biotechproject-483505.uc.r.appspot.com`
3. Sign in
4. Upload files!

---

## 📊 What Changed?

### Before (No Auth)
```
Anyone → Backend → Gets signed URL → Uploads
        ⚠️ OPEN!
```

### After (With Firebase Auth)
```
User → Sign in with Google → Get token
     → Include token in request → Backend verifies
     → If valid → Get signed URL → Upload
        ✅ SECURED!
```

### File Organization

**Before:**
```
uploads/
  └── 20260211_120000_file1.txt
  └── 20260211_120100_file2.txt
```

**After:**
```
uploads/
  └── user-abc123.../
      └── 20260211_120000_file1.txt
  └── user-def456.../
      └── 20260211_120100_file2.txt
```

---

## 🔒 Security Verification Checklist

- [x] **Backend requires authentication**
  - Try without token → 401 Unauthorized ✅

- [x] **Only signed-in users can upload**
  - Try without login → Can't access upload UI ✅

- [x] **Files organized by user**
  - Check bucket → Files in user-specific folders ✅

- [x] **Logs show who uploaded**
  - Check backend logs → See user emails ✅

- [x] **Tokens expire**
  - Wait 1 hour → Token becomes invalid ✅

---

## 🐛 Troubleshooting

### "Firebase Admin SDK initialization error"
- **Fix:** Make sure `backend/service-account-key.json` exists
- Run: `ls backend/service-account-key.json`

### "Sign in popup blocked"
- **Fix:** Allow popups in your browser
- Or refresh and try again

### "Invalid token" even when signed in
- **Fix:** Token may have expired (tokens last 1 hour)
- Sign out and sign in again

### "CORS error" in browser console
- **Fix:** CORS is enabled in `main.py`
- Make sure flask-cors is installed: `pip install flask-cors`

### "Module 'auth' not found"
- **Fix:** Make sure `backend/auth.py` exists
- Check that you're running from the `backend/` directory

---

## 🎯 Success Criteria

You've successfully implemented Firebase auth when:

✅ **Unauthenticated users see login screen**
✅ **Users can sign in with Google**
✅ **Only signed-in users can upload**
✅ **Files are organized by user ID**
✅ **Backend logs show user emails**
✅ **API returns 401 without valid token**
✅ **Everything works in production!**

---

## 📚 Next Steps (Optional Enhancements)

1. **Add rate limiting**
   - Limit uploads per user per day

2. **Add user-specific file listing**
   - Show only the current user's files

3. **Add file deletion**
   - Let users delete their own uploads

4. **Add storage quotas**
   - Limit total storage per user

5. **Add email verification**
   - Require verified email before uploading

---

## 💡 Understanding the Flow

```
1. User clicks "Sign in with Google"
   ↓
2. Firebase popup opens
   ↓
3. User grants permission
   ↓
4. Firebase returns ID token (JWT)
   ↓
5. Frontend stores token: window.currentUserToken
   ↓
6. User uploads file
   ↓
7. Frontend includes token in API request:
   Authorization: Bearer <token>
   ↓
8. Backend (@require_auth decorator):
   - Extracts token from header
   - Verifies with Firebase
   - Checks signature, expiration
   - Extracts user info (uid, email)
   ↓
9. If valid → Generate signed URL
   If invalid → Return 401 Unauthorized
   ↓
10. User uploads to GCS using signed URL
```

**Two layers of security:**
- Layer 1: Firebase auth (protects backend API)
- Layer 2: Signed URL (authorizes GCS upload)

Both work together to create a fully secure system! 🎉

---

## 🎉 Congratulations!

You've successfully added Firebase Authentication to your app!

Your backend is now protected, files are organized by user, and you have a complete audit trail of who uploaded what.

This is a production-ready authentication pattern used by real applications! 🚀
