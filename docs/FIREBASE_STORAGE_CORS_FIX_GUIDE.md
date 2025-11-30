# 🔧 Firebase Storage CORS Fix Guide

## 🔴 The Problem

**Error**: `Access to XMLHttpRequest at 'https://firebasestorage.googleapis.com/...' has been blocked by CORS policy`

**Root Cause**: Firebase Storage bucket doesn't have CORS rules configured to allow uploads from your web app origin.

---

## ✅ Solution: Configure Firebase Storage CORS

### Method 1: Using Google Cloud Console (Recommended for Production)

#### Step 1: Install Google Cloud SDK (If Not Already Installed)

**For Windows:**
1. Download from: https://cloud.google.com/sdk/docs/install
2. Run the installer
3. Open Cloud SDK Shell

**For Mac/Linux:**
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

#### Step 2: Authenticate with Google Cloud

```bash
gcloud auth login
```

This will open your browser for authentication.

#### Step 3: Set Your Firebase Project

```bash
gcloud config set project sayekataleapp
```

#### Step 4: Apply CORS Configuration

**Download the CORS config file:**
- The file `firebase_storage_cors_config.json` has been created in `/home/user/`

**Content of the CORS config:**
```json
[
  {
    "origin": ["https://5060-in9hu1x2vblsbdru37ud5-18e660f9.sandbox.novita.ai"],
    "method": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    "maxAgeSeconds": 3600,
    "responseHeader": ["Content-Type", "Authorization", "Content-Length", "X-Requested-With"]
  },
  {
    "origin": ["*"],
    "method": ["GET", "HEAD"],
    "maxAgeSeconds": 3600
  }
]
```

**Apply the configuration:**
```bash
gsutil cors set firebase_storage_cors_config.json gs://sayekataleapp.appspot.com
```

**Verify the configuration:**
```bash
gsutil cors get gs://sayekataleapp.appspot.com
```

---

### Method 2: Using Firebase Console (Alternative)

**Note**: Firebase Console doesn't have a direct UI for CORS configuration. You must use the `gsutil` command-line tool above.

However, you can check your Storage bucket settings:

1. Go to: https://console.firebase.google.com/project/sayekataleapp/storage
2. Navigate to: **Storage** → **Files**
3. Click on **Rules** tab to ensure write permissions are correct

---

## 🔧 Temporary Workaround for Development

### Option A: Add Wildcard CORS (Development Only)

**⚠️ WARNING**: This allows ALL origins. Only use for development/testing!

Create a more permissive CORS config:

```json
[
  {
    "origin": ["*"],
    "method": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    "maxAgeSeconds": 3600,
    "responseHeader": ["*"]
  }
]
```

Apply it:
```bash
gsutil cors set cors_permissive.json gs://sayekataleapp.appspot.com
```

### Option B: Test on Android First

Since Android apps don't have CORS restrictions, you can:

1. Build the Android APK
2. Test the full verification flow on a real Android device
3. Once verified working, then configure CORS for web deployment

---

## 📋 Production CORS Configuration

For production, you should add your actual deployed web app domains:

```json
[
  {
    "origin": [
      "https://yourdomain.com",
      "https://www.yourdomain.com",
      "https://5060-in9hu1x2vblsbdru37ud5-18e660f9.sandbox.novita.ai"
    ],
    "method": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    "maxAgeSeconds": 3600,
    "responseHeader": ["Content-Type", "Authorization", "Content-Length", "X-Requested-With"]
  },
  {
    "origin": ["*"],
    "method": ["GET", "HEAD"],
    "maxAgeSeconds": 3600
  }
]
```

---

## 🧪 Testing the Fix

### 1. After Applying CORS Configuration:

**Clear browser cache:**
- Chrome: Press `Ctrl+Shift+Delete` → Clear cached images and files
- Or use Incognito/Private mode

### 2. Test PSA Verification Upload:

1. Go to: https://5060-in9hu1x2vblsbdru37ud5-18e660f9.sandbox.novita.ai
2. Login as PSA
3. Fill verification form (all 6 steps)
4. Upload all 4 documents:
   - Business License
   - Tax Certificate  
   - National ID
   - Trade License (optional)
5. Click "Submit Verification"

### 3. Expected Results:

✅ **Success Indicators:**
- Upload progress shows for each document
- Console (F12) shows successful uploads with URLs
- Success message: "Verification submitted successfully!"
- Dashboard shows "Profile Under Review"
- No CORS errors in browser console

❌ **If Still Failing:**
- Check browser console (F12) for error details
- Verify CORS config was applied: `gsutil cors get gs://sayekataleapp.appspot.com`
- Clear browser cache completely
- Try in Incognito/Private mode

---

## 🔍 Debugging CORS Issues

### Check Current CORS Configuration:

```bash
gsutil cors get gs://sayekataleapp.appspot.com
```

### Check Storage Bucket Permissions:

1. Go to: https://console.cloud.google.com/storage/browser/sayekataleapp.appspot.com
2. Click **Permissions** tab
3. Ensure `allUsers` or your service account has appropriate permissions

### View Browser Network Logs:

1. Open Developer Tools (F12)
2. Go to **Network** tab
3. Filter by `XHR` or `Fetch`
4. Look for OPTIONS requests (preflight) to `firebasestorage.googleapis.com`
5. Check response headers for `Access-Control-Allow-Origin`

---

## 🚀 Quick Start Commands

**1. Install Google Cloud SDK**
```bash
# See installation instructions above
```

**2. Authenticate and Configure**
```bash
gcloud auth login
gcloud config set project sayekataleapp
```

**3. Apply CORS (from your computer, not sandbox)**
```bash
gsutil cors set firebase_storage_cors_config.json gs://sayekataleapp.appspot.com
```

**4. Verify**
```bash
gsutil cors get gs://sayekataleapp.appspot.com
```

**5. Test**
- Clear browser cache
- Test PSA verification upload
- Check browser console for CORS errors

---

## 📝 Important Notes

1. **CORS changes take effect immediately** - no restart needed
2. **Browser caching** - Clear cache or use Incognito mode for testing
3. **Production deployment** - Update CORS origins when deploying to real domain
4. **Security** - Never use wildcard (`*`) CORS in production for write operations
5. **Android testing** - CORS doesn't affect Android apps, test there first if needed

---

## 🎯 Recommended Approach

### For Immediate Testing:
1. Apply the permissive CORS config (wildcard origin)
2. Test the complete PSA verification flow on web
3. Once verified working, build Android APK

### For Production:
1. Apply strict CORS config with specific origins
2. Deploy web app to a real domain
3. Update CORS config with production domain
4. Test on both web and Android

---

## 📞 If Issues Persist

If CORS issues continue after applying the configuration:

1. **Check Firebase Storage Rules**: Ensure write permissions are correct
2. **Verify Bucket Name**: Confirm it's `sayekataleapp.appspot.com`
3. **Check Service Account**: Ensure proper authentication
4. **Browser Extensions**: Disable ad blockers or CORS-related extensions
5. **Try Android Build**: Build APK and test on Android device (no CORS)

---

## ✅ Success Criteria

After fixing CORS, you should see:

✅ **In Browser Console (F12):**
```
✅ Firebase Storage initialized
✅ Uploading business_license...
✅ Upload successful: https://firebasestorage.googleapis.com/...
✅ Verification submitted successfully
```

✅ **In Firebase Storage:**
- Files appear at: `gs://sayekataleapp.appspot.com/psa_verifications/`
- Named: `business_license_{psaId}_{timestamp}.jpg`

✅ **In App:**
- Success message appears
- Dashboard shows "Profile Under Review"
- No CORS errors in console

---

## 🎉 Final Steps After CORS Fix

Once CORS is working:

1. ✅ Test complete PSA verification flow
2. ✅ Verify admin receives submissions
3. ✅ Test on web and Android platforms
4. ✅ Build final production APK
5. ✅ Deploy to Google Play Store

---

**Created**: 2025-06-09  
**Last Updated**: 2025-06-09  
**Status**: CORS Configuration Required
