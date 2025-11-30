# ⚡ Firebase Storage CORS - Quick Fix

## 🔴 The Error You're Seeing

```
Access to XMLHttpRequest at 'https://firebasestorage.googleapis.com/...' 
from origin 'https://5060-in9hu1x2vblsbdru37ud5-18e660f9.sandbox.novita.ai' 
has been blocked by CORS policy
```

## 🎯 Quick Fix (3 Steps)

### Step 1: Install Google Cloud SDK

**Download**: https://cloud.google.com/sdk/docs/install

### Step 2: Authenticate & Configure

```bash
gcloud auth login
gcloud config set project sayekataleapp
```

### Step 3: Apply CORS Configuration

**Download the CORS config file** I created: `/home/user/firebase_storage_cors_config.json`

**Apply it:**
```bash
gsutil cors set firebase_storage_cors_config.json gs://sayekataleapp.appspot.com
```

**Verify:**
```bash
gsutil cors get gs://sayekataleapp.appspot.com
```

## ✅ That's It!

Clear your browser cache and test the PSA verification upload again.

---

## 🚀 Alternative: Test on Android First

Since Android doesn't have CORS restrictions:

1. Build Android APK
2. Test on real Android device
3. Configure CORS later for web deployment

---

## 📞 Need More Details?

See the complete guide: `/home/user/FIREBASE_STORAGE_CORS_FIX_GUIDE.md`
