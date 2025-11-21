# ✅ DEPLOYMENT CHECKLIST - Step-by-Step Guide

## 🔴 CRITICAL PRIORITY TASKS

### ☐ Task 1: Rotate Exposed PawaPay API Key (30 minutes)

**Why Critical:** The old API key was exposed in client code and must be revoked immediately.

**Steps:**

1. **Login to PawaPay Dashboard**
   - URL: https://dashboard.pawapay.io/
   - Use your PawaPay credentials

2. **Navigate to API Keys**
   - Dashboard → Settings → API Keys

3. **Revoke Old Key**
   - Find the key with these characteristics:
     - Subject: `"sub":"1911"`
     - Starts with: `eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJ0dCI6IkFBVCIs...`
   - Click "Revoke" or "Delete"
   - Confirm revocation

4. **Generate New Production Key**
   - Click "Create New API Key" or "Generate Key"
   - **Environment:** Production
   - **Name:** `SayeKatale Production`
   - Click "Generate"

5. **Save the New Key Securely**
   - Copy the key to a secure location (password manager)
   - You'll need it in the next step
   - Example format: `eyJ...` (will be different from old key)

**✅ Completion Criteria:**
- [ ] Old key revoked in PawaPay Dashboard
- [ ] New production key generated
- [ ] New key saved securely

---

### ☐ Task 2: Verify PawaPay Correspondents (10 minutes)

**Why Important:** Ensure MTN and Airtel are activated for Uganda.

**Steps:**

1. **Navigate to Correspondents**
   - PawaPay Dashboard → Settings → Correspondents

2. **Verify These Are ENABLED:**
   - [ ] **MTN_MOMO_UGA** (MTN Mobile Money Uganda)
   - [ ] **AIRTEL_OAPI_UGA** (Airtel Money Uganda)

3. **If Not Enabled:**
   - Contact PawaPay support: support@pawapay.io
   - Request activation for Uganda correspondents

**✅ Completion Criteria:**
- [ ] MTN_MOMO_UGA is enabled
- [ ] AIRTEL_OAPI_UGA is enabled

---

### ☐ Task 3: Configure Firebase Functions (15 minutes)

**Prerequisites:**
- [ ] New PawaPay API key from Task 1
- [ ] Firebase CLI installed (`npm install -g firebase-tools`)
- [ ] Firebase project access (sayekataleapp)

**Option A: Use Automated Setup Script**

```bash
cd /home/user/flutter_app
./setup_firebase.sh
```

Follow the prompts:
1. Enter new PawaPay API token
2. Choose mode (2 for Production)
3. Confirm deployment

**Option B: Manual Configuration**

```bash
# Login to Firebase
firebase login

# Set Firebase project
cd /home/user/flutter_app
firebase use sayekataleapp

# Configure PawaPay API token (use your NEW key)
firebase functions:config:set pawapay.api_token="YOUR_NEW_PRODUCTION_KEY"

# Set production mode
firebase functions:config:set pawapay.use_sandbox="false"

# Verify configuration
firebase functions:config:get
```

Expected output:
```json
{
  "pawapay": {
    "api_token": "eyJ...",
    "use_sandbox": "false"
  }
}
```

**✅ Completion Criteria:**
- [ ] Firebase CLI authenticated
- [ ] PawaPay token configured
- [ ] Production mode set (`use_sandbox="false"`)
- [ ] Configuration verified

---

### ☐ Task 4: Deploy Cloud Functions (10 minutes)

**Steps:**

```bash
cd /home/user/flutter_app
firebase deploy --only functions
```

**Expected Output:**

```
✔  functions[initiatePayment(us-central1)] Successful create operation.
Function URL (initiatePayment): https://us-central1-sayekataleapp.cloudfunctions.net/initiatePayment

✔  functions[pawaPayWebhook(us-central1)] Successful update operation.
Function URL (pawaPayWebhook): https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook

✔  functions[pawaPayWebhookHealth(us-central1)] Successful update operation.
Function URL (pawaPayWebhookHealth): https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhookHealth

✔  Deploy complete!
```

**Verify Deployment:**

```bash
# Test health endpoint
curl https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhookHealth
```

Expected response:
```json
{
  "status": "healthy",
  "message": "PawaPay webhook handler is running",
  "timestamp": "2025-11-20T...",
  "version": "2.0.0"
}
```

**✅ Completion Criteria:**
- [ ] Functions deployed successfully
- [ ] All 3 functions show success status
- [ ] Health endpoint returns 200 OK

---

### ☐ Task 5: Configure PawaPay Webhook URL (5 minutes)

**Steps:**

1. **Login to PawaPay Dashboard**
   - URL: https://dashboard.pawapay.io/

2. **Navigate to Webhooks**
   - Dashboard → Settings → Webhooks

3. **Configure Deposits Callback**
   - **Callback URL:** `https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook`
   - **HTTP Method:** POST
   - **Events:** Check `deposit.status.updated`
   - **Active:** ✅ Enabled
   - **IMPORTANT:** Ensure "I do not wish to receive callbacks" is **UNCHECKED**

4. **Save Configuration**

5. **Test Webhook (Optional)**
   - Click "Test Webhook" button
   - Should receive 200 OK response

**✅ Completion Criteria:**
- [ ] Webhook URL configured correctly
- [ ] Events: `deposit.status.updated` selected
- [ ] Webhook is active
- [ ] Test webhook returns 200 OK (optional)

---

## 🟡 HIGH PRIORITY TASKS

### ☐ Task 6: Build Production APK (5 minutes)

**Steps:**

```bash
cd /home/user/flutter_app

# Build release APK
flutter build apk --release
```

**Output Location:**
```
build/app/outputs/flutter-apk/app-release.apk
```

**APK Size:** ~67-69 MB

**Download APK:**
```
https://www.genspark.ai/api/code_sandbox/download_file_stream?project_id=8bd01bd7-e1d6-45a8-86f6-ad3953c185e9&file_path=%2Fhome%2Fuser%2Fflutter_app%2Fbuild%2Fapp%2Foutputs%2Fflutter-apk%2Fapp-release.apk&file_name=app-release.apk
```

**✅ Completion Criteria:**
- [ ] APK built successfully
- [ ] APK file size is reasonable (~67-69 MB)
- [ ] APK downloaded to your computer

---

### ☐ Task 7: Test Payment Flow - Sandbox Mode (20 minutes)

**Prerequisites:**
- [ ] APK installed on Android device
- [ ] Sandbox mode configured in Firebase Functions

**If Testing in Sandbox:**

1. **Configure Sandbox Mode:**
   ```bash
   firebase functions:config:set pawapay.use_sandbox="true"
   firebase deploy --only functions
   ```

2. **Install APK**
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

3. **Test with Sandbox Numbers:**
   - **MTN Test Number:** `0772000001`
   - **Airtel Test Number:** `0702000001`

4. **Testing Steps:**
   - Open app
   - Login: `drnamanya@gmail.com`
   - Navigate: SME Directory → Upgrade to Premium
   - Enter test number: `0772000001`
   - Accept terms and conditions
   - Click "Pay with Mobile Money"

5. **Expected Behavior (Sandbox):**
   - ✅ Message: "Payment initiated"
   - ✅ Transaction created in Firestore
   - ✅ Subscription created as `pending`
   - ✅ After 3-5 seconds, transaction auto-completes
   - ✅ Subscription status changes to `active`
   - ✅ Premium features unlock

6. **Monitor Logs:**
   - Firebase: https://console.firebase.google.com/project/sayekataleapp/functions/logs
   - Firestore: https://console.firebase.google.com/project/sayekataleapp/firestore

**✅ Completion Criteria:**
- [ ] Sandbox payment completes automatically
- [ ] Transaction status: `initiated` → `completed`
- [ ] Subscription status: `pending` → `active`
- [ ] Premium features accessible
- [ ] No errors in Firebase logs

---

### ☐ Task 8: Test Payment Flow - Production Mode (30 minutes)

**⚠️ WARNING:** This will charge REAL MONEY!

**Prerequisites:**
- [ ] Sandbox testing successful
- [ ] Production API key configured
- [ ] Production mode enabled

**Configure Production Mode:**

```bash
firebase functions:config:set pawapay.use_sandbox="false"
firebase deploy --only functions
```

**Testing Steps:**

1. **Use Real Uganda Number**
   - MTN: 077/078/076/079/031/039
   - Airtel: 070/074/075
   - Use YOUR OWN number for testing

2. **Test Payment Flow:**
   - Open app
   - Login: `drnamanya@gmail.com`
   - Navigate: SME Directory → Upgrade to Premium
   - Enter YOUR mobile money number
   - Accept terms
   - Click "Pay with Mobile Money"

3. **Expected Behavior:**
   - ✅ Message: "Payment initiated. Please approve on your phone."
   - ✅ **MOBILE MONEY PROMPT APPEARS ON YOUR PHONE**
   - ✅ Enter PIN on phone
   - ✅ Payment processes
   - ✅ Receive confirmation SMS
   - ✅ Subscription activates in app
   - ✅ Premium features unlock

4. **Monitor Everything:**
   - Your phone for mobile money prompt
   - Firebase Functions logs
   - Firestore database
   - App subscription status

**Troubleshooting:**

| Issue | Check | Solution |
|-------|-------|----------|
| No mobile money prompt | Firebase logs | Look for PawaPay API error (401/403/400) |
| 401 Unauthorized | API key | Verify new key is configured correctly |
| 403 Forbidden | Correspondents | Ensure MTN/Airtel activated in PawaPay |
| 400 Bad Request | MSISDN format | Check logs for sanitized MSISDN value |

**✅ Completion Criteria:**
- [ ] Mobile money prompt received
- [ ] PIN entry successful
- [ ] Payment completed
- [ ] Webhook received callback
- [ ] Subscription activated
- [ ] Premium features work

---

## 🟢 MEDIUM PRIORITY TASKS

### ☐ Task 9: Monitor Production Deployment (Ongoing)

**Daily Monitoring (First Week):**

1. **Firebase Functions Logs**
   - URL: https://console.firebase.google.com/project/sayekataleapp/functions/logs
   - Filter: `resource.labels.function_name="initiatePayment"`
   - Check for errors or failed payments

2. **Firestore Database**
   - URL: https://console.firebase.google.com/project/sayekataleapp/firestore
   - Collections to watch:
     - `transactions/` - Track payment success rate
     - `subscriptions/` - Verify activations
     - `webhook_logs/` - Ensure no duplicates

3. **Key Metrics to Track:**
   - Payment initiation success rate
   - Webhook callback success rate
   - Subscription activation rate
   - Average time from payment to activation

**✅ Completion Criteria:**
- [ ] No critical errors in logs
- [ ] All payments completing successfully
- [ ] Webhooks processing correctly
- [ ] Subscriptions activating properly

---

### ☐ Task 10: Set Up Alerts (Optional but Recommended)

**Firebase Alerts:**

1. **Go to Firebase Console**
   - Project: sayekataleapp
   - Functions → Health

2. **Set Up Alerts for:**
   - Function execution failures
   - High error rates
   - Long execution times

3. **Configure Alert Channels:**
   - Email notifications
   - Slack integration (if available)

**✅ Completion Criteria:**
- [ ] Alerts configured
- [ ] Alert channels tested
- [ ] Team notified of alert setup

---

## 📊 PROGRESS TRACKER

### Critical Tasks (Must Complete Before Production)
- [ ] Task 1: Rotate API Key
- [ ] Task 2: Verify Correspondents
- [ ] Task 3: Configure Firebase Functions
- [ ] Task 4: Deploy Cloud Functions
- [ ] Task 5: Configure Webhook URL

**Progress:** 0/5 Critical Tasks Complete

### High Priority Tasks (Complete Before Launch)
- [ ] Task 6: Build Production APK
- [ ] Task 7: Test Sandbox Mode
- [ ] Task 8: Test Production Mode

**Progress:** 0/3 High Priority Tasks Complete

### Medium Priority Tasks (Complete Within First Week)
- [ ] Task 9: Monitor Production
- [ ] Task 10: Set Up Alerts

**Progress:** 0/2 Medium Priority Tasks Complete

---

## 🎯 SUCCESS CRITERIA

### Phase 1: Security (Critical)
- ✅ Old API key revoked
- ✅ New API key configured
- ✅ Cloud Functions deployed
- ✅ No API keys in client code

### Phase 2: Functionality (High Priority)
- ✅ Sandbox testing passes
- ✅ Production payment works
- ✅ Mobile money prompt appears
- ✅ Subscription activates correctly

### Phase 3: Stability (Medium Priority)
- ✅ No errors in production logs
- ✅ All payments completing
- ✅ Monitoring in place
- ✅ Alerts configured

---

## 📞 SUPPORT RESOURCES

### PawaPay Support
- **Dashboard:** https://dashboard.pawapay.io/
- **Documentation:** https://docs.pawapay.io/
- **Email:** support@pawapay.io
- **Response Time:** 24-48 hours

### Firebase Support
- **Console:** https://console.firebase.google.com/
- **Documentation:** https://firebase.google.com/docs/functions
- **Community:** https://stackoverflow.com/questions/tagged/firebase

### Your Resources
- **GitHub:** https://github.com/DrakeNamanya/sayekataleapp
- **Commit:** `4868713` (latest)
- **Documentation:** See SECURITY_CRITICAL_FIXES.md, DEPLOYMENT_INSTRUCTIONS.md

---

## 🚨 EMERGENCY ROLLBACK PROCEDURE

**If Production Has Critical Issues:**

1. **Disable Payments Immediately:**
   ```bash
   # Comment out payment button in UI
   # Or set maintenance mode
   ```

2. **Check Logs:**
   ```
   https://console.firebase.google.com/project/sayekataleapp/functions/logs
   ```

3. **Rollback Functions (if needed):**
   ```bash
   # List previous deployments
   firebase functions:log
   
   # Rollback to previous version
   firebase deploy --only functions
   ```

4. **Contact Support:**
   - PawaPay: support@pawapay.io
   - Firebase: Console support chat

---

## ✅ FINAL CHECKLIST

Before marking deployment as complete:

- [ ] Old API key revoked in PawaPay Dashboard
- [ ] New API key configured in Firebase Functions
- [ ] Cloud Functions deployed successfully
- [ ] Webhook URL configured in PawaPay Dashboard
- [ ] MTN and Airtel correspondents activated
- [ ] Sandbox testing successful
- [ ] Production payment tested with real number
- [ ] Mobile money prompt received and worked
- [ ] Subscription activated correctly
- [ ] Premium features accessible
- [ ] Monitoring in place
- [ ] Team trained on monitoring

---

**Estimated Total Time:** 2-3 hours (excluding monitoring)

**Last Updated:** November 20, 2025  
**Version:** 1.0.0  
**Status:** Ready for execution
