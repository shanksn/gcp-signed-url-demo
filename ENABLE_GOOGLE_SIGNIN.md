# Enable Google Sign-In in Firebase - Visual Guide

## Problem
Getting error: `Firebase: Error (auth/configuration-not-found)`

This means Google Sign-In provider is not enabled in Firebase Authentication.

## Solution (2 minutes)

### Option 1: Direct Link ⚡ FASTEST
Click this URL - it opens the exact page you need:
```
https://console.firebase.google.com/u/0/project/biotechproject-483505/authentication/providers
```

Then skip to **Step 5** below.

---

### Option 2: Manual Navigation (if link doesn't work)

**Step 1: Open Firebase Console**
```
https://console.firebase.google.com
```

**Step 2: Select Your Project**
- Look for a card or dropdown that says **"biotechproject-483505"**
- Click on it

**Step 3: Find Authentication in Sidebar**

The left sidebar might look different depending on your view. Look for:

**VIEW A (Product view):**
```
📱 Project Overview
━━━━━━━━━━━━━━━━
BUILD ▼
  🔒 Authentication      ← CLICK THIS!
  📊 Firestore Database
  💾 Realtime Database
  📦 Storage
  🌐 Hosting
  ⚡ Functions
```

**VIEW B (Collapsed view):**
```
🏠 Project Overview
⚙️  Authentication        ← CLICK THIS!
💾 Database
📦 Storage
```

**VIEW C (All Products view):**
- Click **"See all Build features"** or **"All Products"**
- Then find **"Authentication"**

**Step 4: Go to Sign-in Method Tab**

After clicking Authentication, you'll see tabs:
```
┌─────────┬──────────────────┬───────────┬───────┐
│  Users  │  Sign-in method  │ Templates │ Usage │
└─────────┴──────────────────┴───────────┴───────┘
```
Click on **"Sign-in method"**

**Step 5: Enable Google Provider**

You'll see a list of sign-in providers:

```
┌──────────────────────────────────────────────┐
│ Sign-in providers                             │
├───────────────────────┬──────────┬───────────┤
│ Provider              │ Status   │           │
├───────────────────────┼──────────┼───────────┤
│ Email/Password        │ Disabled │           │
│ Google                │ Disabled │  ← CLICK  │
│ Phone                 │ Disabled │           │
│ Facebook              │ Disabled │           │
│ Twitter               │ Disabled │           │
│ GitHub                │ Disabled │           │
└───────────────────────┴──────────┴───────────┘
```

Click on the **"Google"** row (not just the status, click anywhere on that row)

**Step 6: Configure Google Sign-In**

A panel will open on the right side:

```
┌─────────────────────────────────────────┐
│ Google                                   │
│                                          │
│ ⚪ Disabled    ⚫ Enabled  ← TOGGLE THIS │
│                                          │
│ Project support email *                  │
│ ┌─────────────────────────────────────┐ │
│ │ shanksreader@gmail.com          ▼   │ │ ← SELECT YOUR EMAIL
│ └─────────────────────────────────────┘ │
│                                          │
│ Project public-facing name (optional)    │
│ ┌─────────────────────────────────────┐ │
│ │ biotechproject-483505               │ │
│ └─────────────────────────────────────┘ │
│                                          │
│        ┌────────┐     ┌──────┐         │
│        │ Cancel │     │ Save │          │ ← CLICK SAVE
│        └────────┘     └──────┘         │
└─────────────────────────────────────────┘
```

1. Toggle the switch to **"Enabled"**
2. Select **"shanksreader@gmail.com"** from the dropdown
3. Click **"Save"** button

**Step 7: Verify**

After saving, you should see:
```
┌───────────────────────┬──────────┐
│ Google                │ Enabled  │ ✅
└───────────────────────┴──────────┘
```

## Test It!

1. Go back to your app: http://127.0.0.1:8001/index-with-auth.html
2. Refresh the page (Ctrl+R or Cmd+R)
3. Click "Sign in with Google"
4. You should see Google's account picker popup! ✅

## Still Not Working?

If you still can't find Authentication:

1. **Make sure you're in the Firebase Console**, not the GCP Console
   - Firebase: https://console.firebase.google.com
   - GCP: https://console.cloud.google.com (different!)

2. **Try incognito/private browsing mode** - sometimes cache causes issues

3. **Check if your account has permission**:
   ```
   You need to be an Owner or Editor of the Firebase project
   ```

## Alternative: Screenshot What You See

Take a screenshot of your Firebase Console and share it - I can help you find where to click!

---

**After enabling, your error will change from:**
```
❌ Firebase: Error (auth/configuration-not-found)
```

**To:**
```
✅ Google Sign-In popup appears successfully!
```
