# 🚀 Firebase Webhook Deployment Guide

## Prerequisites Completed ✅

- ✅ Webhook functions code ready (`functions/index.js`)
- ✅ Firebase project configured (`sayekataleapp`)
- ✅ Node.js dependencies installed (403 packages)
- ✅ Firebase Admin SDK configured
- ✅ Firestore security rules deployed

---

## Deployment Options

### **Option 1: Google Cloud Shell (Recommended)** ⭐

**Advantages:**
- ✅ No local setup required
- ✅ Direct access to Google Cloud
- ✅ Pre-configured authentication
- ✅ Fastest deployment method

**Steps:**

1. **Open Google Cloud Shell:**
   - Go to: https://console.cloud.google.com/
   - Click the **"Activate Cloud Shell"** icon (>_) in the top right
   - Wait for terminal to initialize

2. **Clone Repository:**
   ```bash
   git clone https://github.com/DrakeNamanya/sayekataleapp.git
   cd sayekataleapp
   ```

3. **Install Firebase Tools:**
   ```bash
   npm install -g firebase-tools
   ```

4. **Login to Firebase:**
   ```bash
   firebase login --no-localhost
   ```
   - Follow the authentication link
   - Copy the authorization code
   - Paste it back in the terminal

5. **Install Function Dependencies:**
   ```bash
   cd functions
   npm install
   cd ..
   ```

6. **Deploy Functions:**
   ```bash
   firebase deploy --only functions --project sayekataleapp
   ```

7. **Copy Webhook URL:**
   After deployment, you'll see output like:
   ```
   ✔  functions: Finished running predeploy script.
   ✔  functions[pawaPayWebhook(us-central1)]: Deployed
   ✔  functions[pawaPayWebhookHealth(us-central1)]: Deployed
   
   Function URL (pawaPayWebhook):
   https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook
   ```
   
   **Copy this URL** - you'll need it for PawaPay configuration!

---

### **Option 2: Local Deployment**

**Prerequisites:**
- Node.js 20+ installed
- Firebase CLI installed globally
- Git installed

**Steps:**

1. **Clone Repository:**
   ```bash
   git clone https://github.com/DrakeNamanya/sayekataleapp.git
   cd sayekataleapp
   ```

2. **Install Firebase Tools:**
   ```bash
   npm install -g firebase-tools
   ```

3. **Login to Firebase:**
   ```bash
   firebase login
   ```

4. **Install Function Dependencies:**
   ```bash
   cd functions
   npm install
   cd ..
   ```

5. **Deploy:**
   ```bash
   firebase deploy --only functions --project sayekataleapp
   ```

---

## Deployed Functions

After successful deployment, you'll have these Cloud Functions:

### **1. pawaPayWebhook** (Main Handler)
- **URL:** `https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook`
- **Method:** POST
- **Purpose:** Receives payment status updates from PawaPay
- **Features:**
  - ✅ RFC-9421 signature verification
  - ✅ Idempotency handling
  - ✅ Transaction status updates
  - ✅ Automatic subscription activation

### **2. pawaPayWebhookHealth** (Health Check)
- **URL:** `https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhookHealth`
- **Method:** GET
- **Purpose:** Verify webhook is running
- **Response:** 
  ```json
  {
    "status": "healthy",
    "timestamp": "2025-11-20T12:00:00Z",
    "service": "PawaPay Webhook"
  }
  ```

### **3. manualActivateSubscription** (Admin Utility)
- **Type:** Callable Function
- **Purpose:** Manually activate subscriptions for testing
- **Usage:** Call from Flutter app or Firebase Console

---

## PawaPay Configuration

After webhook deployment, configure PawaPay to send status updates:

### **Step 1: Access PawaPay Dashboard**
- Go to: https://dashboard.pawapay.io/ (or your PawaPay portal)
- Login with your credentials

### **Step 2: Navigate to Webhooks**
- Click **"Developers"** or **"Settings"**
- Select **"Webhooks"** or **"API Configuration"**

### **Step 3: Add Webhook URL**
- Click **"Add Webhook"** or **"New Endpoint"**
- **URL:** `https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook`
- **Method:** POST
- **Events to subscribe:**
  - ✅ `deposit.status.updated` (Critical)
  - ✅ `payment.completed`
  - ✅ `payment.failed`

### **Step 4: Configure Signature Verification**
- **Signature Type:** RFC-9421 (HTTP Message Signatures)
- **Algorithm:** HMAC-SHA256
- **Secret:** (Your PawaPay API secret key)

### **Step 5: Test Webhook**
- Use PawaPay's "Test Webhook" feature
- Or initiate a real payment from the Flutter app
- Check Firebase Functions logs to verify receipt

---

## Verification Steps

### **1. Test Webhook Health Check**
```bash
curl https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhookHealth
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2025-11-20T...",
  "service": "PawaPay Webhook"
}
```

### **2. Check Firebase Function Logs**
- Go to: https://console.firebase.google.com/project/sayekataleapp/functions/logs
- Filter by function: `pawaPayWebhook`
- Look for deployment success messages

### **3. Monitor Webhook Activity**
After PawaPay configuration:
- Initiate a test payment from Flutter app
- Check Firebase logs for incoming webhook requests
- Verify transaction status updates in Firestore

---

## Webhook Flow

```
1. User initiates payment in Flutter app
   └─> Transaction created (status: initiated)
   └─> Subscription created (status: pending)

2. User approves payment on phone
   └─> PawaPay processes payment

3. PawaPay sends webhook to Firebase Function
   └─> Webhook verifies signature (RFC-9421)
   └─> Webhook updates transaction (status: completed)
   └─> Webhook activates subscription (status: active)

4. User gains premium access automatically
```

---

## Troubleshooting

### **Issue: Deployment fails with authentication error**
**Solution:**
```bash
firebase login --reauth
firebase use sayekataleapp
firebase deploy --only functions
```

### **Issue: Functions not deploying**
**Solution:**
```bash
# Check Firebase CLI version
firebase --version

# Update Firebase CLI
npm install -g firebase-tools@latest

# Clear cache and redeploy
cd functions
rm -rf node_modules package-lock.json
npm install
cd ..
firebase deploy --only functions
```

### **Issue: Webhook not receiving requests**
**Solution:**
1. Verify webhook URL in PawaPay dashboard
2. Check if HTTPS is used (not HTTP)
3. Verify PawaPay events are enabled
4. Check Firebase Function logs for errors

### **Issue: Signature verification failing**
**Solution:**
1. Verify API secret key in PawaPay config
2. Check signature algorithm (should be HMAC-SHA256)
3. Review Firebase Function logs for signature details

---

## Important URLs

- **Firebase Console:** https://console.firebase.google.com/project/sayekataleapp
- **Function Logs:** https://console.firebase.google.com/project/sayekataleapp/functions/logs
- **Firestore Data:** https://console.firebase.google.com/project/sayekataleapp/firestore
- **GitHub Repo:** https://github.com/DrakeNamanya/sayekataleapp
- **Google Cloud Shell:** https://console.cloud.google.com/

---

## Expected Webhook URL

After deployment, your webhook URL will be:
```
https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook
```

**Copy this URL for PawaPay configuration!**

---

## Security Notes

1. **Signature Verification:** All webhook requests are verified using RFC-9421
2. **Idempotency:** Duplicate webhook requests are safely handled
3. **Admin SDK:** Firestore updates use Admin SDK (bypasses security rules)
4. **HTTPS Only:** Webhook only accepts HTTPS requests

---

## Success Criteria

✅ Webhook deployed successfully  
✅ Health check responds with 200 OK  
✅ PawaPay webhook URL configured  
✅ Test payment updates subscription status  
✅ Firebase logs show webhook activity  

---

**Last Updated:** November 20, 2025  
**Status:** Ready for deployment 🚀
