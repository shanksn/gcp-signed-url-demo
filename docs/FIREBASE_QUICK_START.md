# Firebase Setup - Quick Start Guide

## ✅ APIs Already Enabled!

I've already enabled the Firebase APIs for your project:
- ✅ firebase.googleapis.com
- ✅ identitytoolkit.googleapis.com  
- ✅ firebasehosting.googleapis.com

## 🌐 Now: Setup in Firebase Console (3 steps)

### Step 1: Add Firebase to Project

1. **Open:** https://console.firebase.google.com/
2. **You should see:** "Add Firebase to one of your existing Google Cloud projects"
3. **Select:** biotechproject-483505
4. **Click:** Continue

**If you DON'T see your project:**
- Make sure you're logged in with the same Google account
- Try this direct link: https://console.firebase.google.com/u/0/project/biotechproject-483505/overview

### Step 2: Enable Google Sign-In

1. **Click:** Build → Authentication (in left sidebar)
2. **Click:** "Get started" button
3. **Tab:** Sign-in method
4. **Click:** Google (in providers list)
5. **Toggle:** Enable
6. **Select:** Support email from dropdown
7. **Click:** Save

### Step 3: Register Web App

1. **Click:** Gear icon ⚙️ → Project settings
2. **Scroll down to:** "Your apps" section
3. **Click:** Web icon `</>`
4. **Enter:** App nickname: "Signed URL Demo"
5. **Leave unchecked:** Firebase Hosting
6. **Click:** Register app

**You'll see this:**
```javascript
const firebaseConfig = {
  apiKey: "AIzaSy...",
  authDomain: "biotechproject-483505.firebaseapp.com",
  projectId: "biotechproject-483505",
  storageBucket: "biotechproject-483505.appspot.com",
  messagingSenderId: "...",
  appId: "..."
};
```

**📋 COPY THIS CONFIG!** Send it to me and I'll integrate it into your app!

---

## 🎯 Alternative: Use Just API Keys (5 minutes)

If you can't access Firebase Console, we can use a simpler approach:

**Option: HTTP API Key Authentication**

Instead of Firebase, we can add a simple API key to your backend.

Would you like me to implement this simpler option instead?

---

## 📞 Current Status

**What's Done:**
- ✅ Firebase APIs enabled in your GCP project
- ✅ Backend code ready ([backend/auth.py](backend/auth.py))
- ✅ Dependencies updated ([backend/requirements.txt](backend/requirements.txt))

**What You Need:**
- Firebase config from web console (3 steps above)

**OR:**
- Choose simpler API key approach

Let me know which path you want to take!

