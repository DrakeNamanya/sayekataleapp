# 🚀 SayeKatale Web App Hosting Deployment Guide

## Firebase Project Information
- **Project ID**: sayekataleapp
- **Build Location**: `build/web/`
- **Build Size**: 34MB (12MB compressed)

---

## 🎯 Production URLs (After Deployment)

### Firebase Hosting URLs
Once deployed, your app will be available at:

**Primary URL**: 
- https://sayekataleapp.web.app
- https://sayekataleapp.firebaseapp.com

**Custom Domain** (optional):
- You can add your own domain (e.g., https://www.sayekatale.com)

---

## 📋 Deployment Steps

### Option 1: Firebase CLI Deployment (Recommended)

```bash
# 1. Login to Firebase (if not already logged in)
firebase login

# 2. Initialize Firebase project (if needed)
firebase use sayekataleapp

# 3. Build the Flutter web app (already done)
flutter build web --release

# 4. Deploy to Firebase Hosting
firebase deploy --only hosting

# Expected output:
# ✔ Deploy complete!
# Hosting URL: https://sayekataleapp.web.app
```

### Option 2: Firebase Console Deployment

1. Go to https://console.firebase.google.com/
2. Select project: **sayekataleapp**
3. Navigate to: **Hosting** section
4. Click: **Get started** or **Add another site**
5. Upload the `build/web` folder
6. Deploy

---

## 🔗 URLs You'll Need After Deployment

### 1. PawaPay Callback URLs
```
Deposit Callback:  https://sayekataleapp.web.app/api/pawapay/deposit/callback
Withdrawal Callback: https://sayekataleapp.web.app/api/pawapay/withdrawal/callback
```

### 2. OAuth Redirect URIs (if needed)
```
https://sayekataleapp.web.app/auth/callback
https://sayekataleapp.web.app/__/auth/handler
```

### 3. App Link / Universal Link
```
https://sayekataleapp.web.app
```

### 4. API Base URL
```
https://sayekataleapp.web.app/api
```

---

## 📱 AdMob Setup (For Mobile App)

### Step 1: Create AdMob Account
1. Go to https://admob.google.com/
2. Sign in with Google account
3. Click "Get Started"

### Step 2: Add Your App
1. Click "Apps" → "Add App"
2. Select platform: **Android**
3. App name: **SayeKatale**
4. Enter package name: `com.sayekatale.app` (or your actual package name)

### Step 3: Create Ad Units
1. **Banner Ad Unit** (for list screens)
   - Format: Banner
   - Name: "Home Banner"
   
2. **Interstitial Ad Unit** (optional, for transitions)
   - Format: Interstitial
   - Name: "Transition Ad"

### Step 4: Get Your IDs
After creating, you'll get:
```
App ID (Android): ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX
Banner Ad Unit ID: ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
```

**Important**: During testing, use these test IDs:
```
Test App ID: ca-app-pub-3940256099942544~3347511713
Test Banner ID: ca-app-pub-3940256099942544/6300978111
```

---

## 🔐 GitHub Secrets to Update

After getting production URLs and AdMob IDs, update these secrets:

### Firebase/Hosting Secrets
```bash
# Not needed - already configured
```

### PawaPay Secrets
```bash
PAWAPAY_DEPOSIT_CALLBACK=https://sayekataleapp.web.app/api/pawapay/deposit/callback
PAWAPAY_WITHDRAWAL_CALLBACK=https://sayekataleapp.web.app/api/pawapay/withdrawal/callback
API_BASE_URL=https://sayekataleapp.web.app/api
```

### AdMob Secrets (for Android build)
```bash
ADMOB_APP_ID_ANDROID=ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX
ADMOB_BANNER_ID_ANDROID=ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
```

---

## ✅ Post-Deployment Checklist

- [ ] App accessible at https://sayekataleapp.web.app
- [ ] Firebase authentication works
- [ ] Firestore data loads correctly
- [ ] Images from Firebase Storage load
- [ ] Custom domain configured (optional)
- [ ] PawaPay notified of callback URLs
- [ ] AdMob account created
- [ ] GitHub secrets updated with production values
- [ ] Test ad units replaced with production IDs
- [ ] SSL/HTTPS working correctly

---

## 🔍 Verification Commands

```bash
# Test hosting URL
curl -I https://sayekataleapp.web.app

# Check Firebase project
firebase projects:list

# View hosting info
firebase hosting:sites:list
```

---

## 📞 Next Steps

1. **Deploy to Firebase Hosting**
   ```bash
   firebase deploy --only hosting
   ```

2. **Get production URL** from deployment output

3. **Set up AdMob account** at https://admob.google.com/

4. **Update PawaPay dashboard** with callback URLs

5. **Update GitHub Secrets** with production values

6. **Test the hosted app** thoroughly

---

## 🆘 Troubleshooting

**Issue**: `firebase: command not found`
**Fix**: Already installed at `/usr/bin/firebase`

**Issue**: "Authentication required"
**Fix**: Run `firebase login` and authenticate

**Issue**: "Permission denied"
**Fix**: Ensure you have Firebase project permissions

**Issue**: "Build not found"
**Fix**: Run `flutter build web --release` first

---

**Ready to deploy?** Run: `firebase deploy --only hosting`
