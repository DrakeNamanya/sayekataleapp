# 🚀 DEPLOYMENT INSTRUCTIONS - PawaPay Server-Side Integration

## 🔒 CRITICAL: Security Notice

**An API key was exposed in client-side code. It MUST be rotated before production deployment.**

Exposed key (first 50 chars): `eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJ0dCI6IkFBVCIs...`

---

## 📋 PRE-DEPLOYMENT CHECKLIST

### 1. ⚠️ ROTATE API KEY (DO THIS FIRST!)

**Step-by-step:**

1. Log in to **PawaPay Dashboard**: https://dashboard.pawapay.io/

2. Navigate to **Settings → API Keys**

3. **Revoke the exposed key**:
   - Find the API key with subject `"sub":"1911"`
   - Click "Revoke" or "Delete"

4. **Generate NEW Production Key**:
   - Click "Create New API Key"
   - Select "Production" environment
   - Name it: "SayeKatale Production"
   - Save the key securely

5. **Verify correspondents are activated**:
   - Go to **Settings → Correspondents**
   - Ensure these are ENABLED:
     - ✅ **MTN_MOMO_UGA** (MTN Mobile Money Uganda)
     - ✅ **AIRTEL_OAPI_UGA** (Airtel Money Uganda)

---

## 🔧 FIREBASE FUNCTIONS DEPLOYMENT

### Step 1: Install Firebase CLI (if not already installed)

```bash
npm install -g firebase-tools
```

### Step 2: Login to Firebase

```bash
firebase login
```

### Step 3: Set Firebase Project

```bash
cd /home/user/flutter_app
firebase use sayekataleapp
```

### Step 4: Configure PawaPay API Token

**For Sandbox Testing:**
```bash
firebase functions:config:set pawapay.api_token="YOUR_SANDBOX_API_KEY"
firebase functions:config:set pawapay.use_sandbox="true"
```

**For Production:**
```bash
firebase functions:config:set pawapay.api_token="YOUR_NEW_PRODUCTION_KEY"
firebase functions:config:set pawapay.use_sandbox="false"
```

### Step 5: Verify Configuration

```bash
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

### Step 6: Deploy Cloud Functions

```bash
cd /home/user/flutter_app
firebase deploy --only functions
```

This will deploy:
- ✅ `initiatePayment` - Server-side payment initiation
- ✅ `pawaPayWebhook` - Payment status callback handler
- ✅ `pawaPayWebhookHealth` - Health check endpoint

**Expected output:**
```
✔  functions[initiatePayment(us-central1)] Successful create operation.
✔  functions[pawaPayWebhook(us-central1)] Successful update operation.
✔  functions[pawaPayWebhookHealth(us-central1)] Successful update operation.
```

### Step 7: Note Function URLs

After deployment, Firebase will show URLs like:
```
initiatePayment: https://us-central1-sayekataleapp.cloudfunctions.net/initiatePayment
pawaPayWebhook: https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook
```

---

## 🌐 PAWAPAY DASHBOARD WEBHOOK CONFIGURATION

### Step 1: Configure Webhook URL

1. Log in to **PawaPay Dashboard**: https://dashboard.pawapay.io/

2. Navigate to **Settings → Webhooks**

3. **Deposits Callback Configuration:**
   - **URL**: `https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook`
   - **Method**: `POST`
   - **Events**: Select `deposit.status.updated`
   - **Active**: ✅ **Enabled**
   - **Important**: Ensure "I do not wish to receive callbacks" is **UNCHECKED**

4. **Test Webhook (Optional):**
   - Click "Test Webhook"
   - Should receive 200 OK response
   - Check Firebase Functions logs for webhook test

5. **Save Configuration**

---

## 📱 FLUTTER APP BUILD & DEPLOYMENT

### Option A: Build Android APK

```bash
cd /home/user/flutter_app
flutter build apk --release
```

**APK Location:**
```
build/app/outputs/flutter-apk/app-release.apk
```

### Option B: Build App Bundle (for Google Play Store)

```bash
cd /home/user/flutter_app
flutter build appbundle --release
```

**AAB Location:**
```
build/app/outputs/bundle/release/app-release.aab
```

---

## 🧪 TESTING GUIDE

### Phase 1: Sandbox Testing

**Prerequisites:**
- Sandbox API key configured
- `use_sandbox="true"` in Firebase Functions config
- Cloud Functions deployed

**Test Numbers:**
- **MTN**: `0772000001`
- **Airtel**: `0702000001`

**Testing Steps:**

1. **Install Test APK**:
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

2. **Login**: `drnamanya@gmail.com`

3. **Navigate**: SME Directory → Upgrade to Premium

4. **Enter Test Number**: `0772000001` (MTN) or `0702000001` (Airtel)

5. **Accept Terms** and click **"Pay with Mobile Money"**

6. **Expected Behavior**:
   - ✅ Message: "Payment initiated. Please approve on your phone."
   - ✅ Transaction created in Firestore with `status: "initiated"`
   - ✅ Subscription created with `status: "pending"`
   - ✅ In sandbox, transaction auto-completes after 3-5 seconds
   - ✅ Webhook receives callback
   - ✅ Subscription status changes to `"active"`
   - ✅ Premium features unlock

7. **Monitor Logs**:
   ```
   https://console.firebase.google.com/project/sayekataleapp/functions/logs
   ```
   
   Look for:
   ```
   🌐 Calling PawaPay API: https://api.sandbox.pawapay.cloud/deposits
   📥 PawaPay Response: {"statusCode":201}
   ✅ Transaction created: dep_...
   📥 PawaPay Webhook Received
   ✅ Premium subscription activated for user: ...
   ```

8. **Verify Firestore**:
   ```
   https://console.firebase.google.com/project/sayekataleapp/firestore
   ```
   
   Check:
   - `transactions/{depositId}` - status should be `"completed"`
   - `subscriptions/{userId}` - status should be `"active"`

### Phase 2: Production Testing

**Prerequisites:**
- **NEW Production API key** configured (old key revoked)
- `use_sandbox="false"` in Firebase Functions config
- Cloud Functions redeployed with production config
- PawaPay webhook URL verified

**⚠️ WARNING: Production testing uses REAL money!**

**Test with Small Amount (Optional):**

If you want to test without charging full subscription price, you can temporarily modify:

File: `functions/index.js`
```javascript
// Test with small amount
const testAmount = 100; // UGX 100 instead of 50,000
```

**Production Test Steps:**

1. **Deploy with Production Config**:
   ```bash
   firebase functions:config:set pawapay.use_sandbox="false"
   firebase deploy --only functions
   ```

2. **Install Production APK**

3. **Test with Real Number**:
   - Use your own MTN or Airtel number
   - Prefixes: MTN (077/078/076/079/031/039), Airtel (070/074/075)

4. **Expected Behavior**:
   - ✅ Payment initiated
   - ✅ **Mobile money prompt appears on your phone**
   - ✅ Enter PIN on phone
   - ✅ Payment processes
   - ✅ Webhook receives callback
   - ✅ Subscription activates
   - ✅ Premium unlocks

5. **Troubleshooting**:
   - If no prompt: Check Firebase logs for PawaPay API error
   - Common errors:
     - `401 Unauthorized` → API key incorrect
     - `403 Forbidden` → Correspondent not activated
     - `400 Bad Request` → MSISDN format issue

---

## 📊 MONITORING & DEBUGGING

### Firebase Functions Logs

**URL:** https://console.firebase.google.com/project/sayekataleapp/functions/logs

**Filter by function:**
- `resource.labels.function_name="initiatePayment"`
- `resource.labels.function_name="pawaPayWebhook"`

**Key logs to look for:**

**Payment Initiation:**
```
🔧 PawaPay Configuration: {"baseUrl":"https://api.pawapay.cloud","tokenSet":true,"mode":"PRODUCTION"}
💳 Payment initiation request: {"userId":"...","phoneNumber":"0774000001","amount":50000}
📱 Sanitized MSISDN: 256774000001
📡 Correspondent: MTN_MOMO_UGA
🌐 Calling PawaPay API: {"url":"https://api.pawapay.cloud/deposits","depositId":"dep_..."}
📥 PawaPay Response: {"statusCode":201,"body":"..."}
✅ PawaPay deposit initiated: dep_...
```

**Webhook Processing:**
```
📥 PawaPay Webhook Received
✅ Digest verified
✅ Signature verification passed
📋 Transaction found: {"depositId":"dep_...","userId":"...","status":"completed"}
✅ Payment COMPLETED: dep_..., Amount: UGX 50000
✅ Premium subscription activated for user: ...
✅ Marked as processed: dep_...
```

### Firestore Database

**URL:** https://console.firebase.google.com/project/sayekataleapp/firestore

**Collections to monitor:**

1. **transactions/**
   - Document ID: `{depositId}`
   - Fields to watch:
     - `status`: `"initiated"` → `"completed"`
     - `metadata.msisdn`: Should be `"2567XXXXXXXX"` (no + prefix)
     - `metadata.correspondent`: `"MTN_MOMO_UGA"` or `"AIRTEL_OAPI_UGA"`

2. **subscriptions/**
   - Document ID: `{userId}`
   - Fields to watch:
     - `status`: `"pending"` → `"active"`
     - `payment_reference`: Should match transaction `depositId`

3. **webhook_logs/**
   - Document ID: `{depositId}`
   - Purpose: Idempotency tracking
   - Verify webhook was processed only once

---

## ⚠️ TROUBLESHOOTING

### Issue 1: No Mobile Money Prompt

**Symptoms:**
- Payment initiated message shows
- No prompt on phone
- Transaction status stays `"initiated"`

**Debugging:**

1. **Check Firebase Functions logs** for PawaPay API response:
   ```
   📥 PawaPay Response: {"statusCode":401,"error":"..."}
   ```

2. **Common Causes:**
   
   **401 Unauthorized:**
   - Old API key still configured
   - Solution: Rotate key and redeploy
   
   **403 Forbidden:**
   - Correspondent not activated (MTN_MOMO_UGA / AIRTEL_OAPI_UGA)
   - Solution: Enable in PawaPay Dashboard → Settings → Correspondents
   
   **400 Bad Request:**
   - MSISDN format issue
   - Check log: `📱 Sanitized MSISDN:` should show `256774000001` (no + prefix)
   
   **404 Not Found:**
   - Wrong API endpoint
   - Check: Should be `https://api.pawapay.cloud` (not sandbox)

### Issue 2: Subscription Not Activating

**Symptoms:**
- Mobile money prompt works
- Payment completes
- Subscription stays `"pending"`

**Debugging:**

1. **Check webhook is configured** in PawaPay Dashboard

2. **Test webhook manually**:
   ```bash
   curl -X POST https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook \
     -H "Content-Type: application/json" \
     -d '{
       "depositId": "test_123",
       "status": "COMPLETED",
       "amount": "50000",
       "currency": "UGX",
       "correspondent": "MTN_MOMO_UGA"
     }'
   ```

3. **Check webhook logs** for errors

4. **Verify transaction exists** in Firestore with matching `depositId`

### Issue 3: Exposed API Key Still in Code

**Symptoms:**
- Git history shows API key
- Security scanners flagging key

**Solution:**

1. **Rotate the key** (even if removed from current code)

2. **Remove from git history** (optional but recommended):
   ```bash
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch lib/screens/shg/subscription_purchase_screen.dart" \
     --prune-empty --tag-name-filter cat -- --all
   ```

3. **Force push** (⚠️ CAUTION: Rewrites history):
   ```bash
   git push origin --force --all
   ```

---

## ✅ DEPLOYMENT SUCCESS CRITERIA

### Backend (Cloud Functions)

- [ ] New API key generated and old key revoked
- [ ] Firebase Functions config set with new API key
- [ ] Cloud Functions deployed successfully
- [ ] `initiatePayment` function accessible
- [ ] `pawaPayWebhook` function accessible
- [ ] Webhook URL configured in PawaPay Dashboard
- [ ] Correspondents (MTN, Airtel) activated in PawaPay

### Frontend (Flutter App)

- [ ] No API key in client code
- [ ] Payment service calls backend endpoint
- [ ] Subscriptions created as `"pending"`
- [ ] Premium check verifies `status === "active"`
- [ ] APK/AAB built successfully

### Testing

- [ ] Sandbox test: Payment completes automatically
- [ ] Production test: Mobile money prompt appears
- [ ] Production test: PIN entry works
- [ ] Production test: Subscription activates after payment
- [ ] Premium features unlock correctly

### Monitoring

- [ ] Firebase Functions logs show successful payment initiations
- [ ] PawaPay API returns 201 status
- [ ] Webhook callbacks processed successfully
- [ ] Firestore data updates correctly
- [ ] No duplicate webhook processing (idempotency working)

---

## 📞 SUPPORT

### PawaPay Support
- **Dashboard**: https://dashboard.pawapay.io/
- **Docs**: https://docs.pawapay.io/
- **Support Email**: support@pawapay.io

### Firebase Support
- **Console**: https://console.firebase.google.com/
- **Docs**: https://firebase.google.com/docs/functions
- **Status**: https://status.firebase.google.com/

### GitHub Repository
- **URL**: https://github.com/DrakeNamanya/sayekataleapp
- **Latest Commit**: `b0042e3` - Security fixes applied

---

## 🎯 NEXT STEPS

1. **IMMEDIATE (CRITICAL):**
   - [ ] Rotate exposed API key
   - [ ] Deploy Cloud Functions with new key
   - [ ] Test in sandbox mode

2. **BEFORE PRODUCTION:**
   - [ ] Verify PawaPay correspondents activated
   - [ ] Configure production API key
   - [ ] Test with small real transaction
   - [ ] Verify webhook receives callbacks

3. **PRODUCTION DEPLOYMENT:**
   - [ ] Build production APK/AAB
   - [ ] Deploy to Google Play Store
   - [ ] Monitor Firebase logs
   - [ ] Verify real payments work

4. **POST-DEPLOYMENT:**
   - [ ] Monitor transaction success rate
   - [ ] Review Firebase Functions costs
   - [ ] Set up alerts for failed payments
   - [ ] Document any production issues

---

**Last Updated:** November 20, 2025  
**Version:** 1.0.0 - Server-Side Payment Integration  
**Status:** ✅ Ready for deployment (after API key rotation)
