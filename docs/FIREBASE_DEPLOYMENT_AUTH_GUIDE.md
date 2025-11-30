# 🔑 Firebase Cloud Functions Deployment - Authentication Guide

## **Current Status**: ❌ Authentication Required

Firebase CLI requires authentication before deploying functions.

---

## **Deployment Options**

### **Option 1: Service Account Key (Recommended)** ⭐

**Steps:**
1. Go to Firebase Console: https://console.firebase.google.com/
2. Select project: **sayekataleapp**
3. Click **Settings (⚙️)** → **Project Settings**
4. Navigate to **"Service accounts"** tab
5. Click **"Generate new private key"**
6. Save the JSON file (e.g., `sayekataleapp-firebase-adminsdk.json`)
7. Upload it to the sandbox:
   - Via Firebase tab in your environment
   - Or use `DownloadFileWrapper` tool

**Deploy with Service Account:**
```bash
# Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json

# Deploy functions
cd /home/user/flutter_app
firebase deploy --only functions:onDeliveryTrackingCreated,functions:onDeliveryStatusUpdate
```

---

### **Option 2: Firebase Token (Temporary Access)** 🎫

**Steps:**
1. On your **local machine** (not sandbox), run:
   ```bash
   firebase login:ci
   ```

2. Follow the browser authentication flow

3. Copy the generated token

4. Use token in sandbox:
   ```bash
   export FIREBASE_TOKEN="your-token-here"
   cd /home/user/flutter_app
   firebase deploy --token "$FIREBASE_TOKEN" --only functions:onDeliveryTrackingCreated,functions:onDeliveryStatusUpdate
   ```

**Security Note**: Tokens expire and should not be shared publicly.

---

### **Option 3: Deploy from Local Machine** 💻

If authentication in sandbox is difficult:

1. **Clone your repository locally**:
   ```bash
   git clone https://github.com/DrakeNamanya/sayekataleapp.git
   cd sayekataleapp/functions
   ```

2. **Authenticate Firebase CLI**:
   ```bash
   firebase login
   ```

3. **Deploy functions**:
   ```bash
   firebase deploy --only functions:onDeliveryTrackingCreated,functions:onDeliveryStatusUpdate
   ```

---

## **After Authentication**

Once authenticated, the deployment command is:

```bash
cd /home/user/flutter_app
firebase deploy --only functions:onDeliveryTrackingCreated,functions:onDeliveryStatusUpdate
```

**Expected deployment time**: 2-3 minutes

---

## **Post-Deployment**

1. **Verify deployment**:
   ```bash
   firebase functions:list
   ```

2. **Check logs**:
   ```bash
   firebase functions:log --only onDeliveryTrackingCreated,onDeliveryStatusUpdate
   ```

3. **Update Firestore Security Rules** (see FIREBASE_FUNCTIONS_DEPLOYMENT_GUIDE.md)

---

## **Need Help?**

- Firebase Console: https://console.firebase.google.com/
- Firebase CLI Docs: https://firebase.google.com/docs/cli
- Service Account Guide: https://firebase.google.com/docs/admin/setup#initialize-sdk

