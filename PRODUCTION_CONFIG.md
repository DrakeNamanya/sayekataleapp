# 🔐 PRODUCTION CONFIGURATION

## ✅ Confirmed Configuration

### **New PawaPay API Key**
```
eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJ0dCI6IkFBVCIsInN1YiI6IjE5MTEiLCJtYXYiOiIxIiwiZXhwIjoyMDc5MjQxMTE4LCJpYXQiOjE3NjM3MDgzMTgsInBtIjoiREFGLFBBRiIsImp0aSI6Ijk3YmJjM2Y2LTFiY2MtNDBlMS05ZTA1LWZkNjYyODRiODAzMSJ9.85FNrfBkh_RqiTR8sD-Ey7FWdPX3Ul56E7n2VixllH8c-qTu8JxeR-KB4rbcnVTyXXsr92Ph_0fZP4ju7rF8dg
```

**Key Details:**
- Subject: `"sub":"1911"` (same as before)
- Issued At: 2025-11-20 (New key)
- Expires: 2034-11-17 (~9 years validity)
- JTI: `97bbc3f6-1bcc-40e1-9e05-fd66284b8031` (New unique ID)

### **Webhook URL**
```
https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook
```

**Webhook Configuration:**
- Method: POST
- Events: `deposit.status.updated`
- Active: ✅ Enabled

### **Firebase Project**
- Project ID: `sayekataleapp`
- Region: `us-central1`

---

## 🚀 DEPLOYMENT COMMANDS

### **Option 1: Automated Deployment (Recommended)**

From your local machine with Firebase CLI:

```bash
# Clone repository
git clone https://github.com/DrakeNamanya/sayekataleapp.git
cd sayekataleapp

# Run automated deployment
./deploy_production.sh
```

### **Option 2: Manual Deployment**

```bash
# 1. Login to Firebase
firebase login

# 2. Set project
firebase use sayekataleapp

# 3. Configure API token
firebase functions:config:set pawapay.api_token="eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJ0dCI6IkFBVCIsInN1YiI6IjE5MTEiLCJtYXYiOiIxIiwiZXhwIjoyMDc5MjQxMTE4LCJpYXQiOjE3NjM3MDgzMTgsInBtIjoiREFGLFBBRiIsImp0aSI6Ijk3YmJjM2Y2LTFiY2MtNDBlMS05ZTA1LWZkNjYyODRiODAzMSJ9.85FNrfBkh_RqiTR8sD-Ey7FWdPX3Ul56E7n2VixllH8c-qTu8JxeR-KB4rbcnVTyXXsr92Ph_0fZP4ju7rF8dg"

# 4. Set production mode
firebase functions:config:set pawapay.use_sandbox="false"

# 5. Verify configuration
firebase functions:config:get

# 6. Deploy functions
firebase deploy --only functions
```

### **Expected Deployment Output**

```
=== Deploying to 'sayekataleapp'...

i  deploying functions
i  functions: ensuring required API cloudfunctions.googleapis.com is enabled...
i  functions: ensuring required API cloudbuild.googleapis.com is enabled...
✔  functions: required API cloudfunctions.googleapis.com is enabled
✔  functions: required API cloudbuild.googleapis.com is enabled
i  functions: preparing functions directory for uploading...
i  functions: packaged functions (XX.XX KB) for uploading
✔  functions: functions folder uploaded successfully

The following functions will be deployed:
- initiatePayment(us-central1)
- pawaPayWebhook(us-central1)
- pawaPayWebhookHealth(us-central1)

Functions deploy had errors with the following functions:
   initiatePayment(us-central1)
   pawaPayWebhook(us-central1)
   pawaPayWebhookHealth(us-central1)

To continue deploying other features (such as database), run:
    firebase deploy --except functions

✔  functions[initiatePayment(us-central1)]: Successful create operation.
Function URL (initiatePayment): https://us-central1-sayekataleapp.cloudfunctions.net/initiatePayment

✔  functions[pawaPayWebhook(us-central1)]: Successful update operation.
Function URL (pawaPayWebhook): https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook

✔  functions[pawaPayWebhookHealth(us-central1)]: Successful update operation.
Function URL (pawaPayWebhookHealth): https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhookHealth

✔  Deploy complete!
```

---

## 🧪 POST-DEPLOYMENT VERIFICATION

### **Step 1: Test Webhook Health**

```bash
curl https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhookHealth
```

**Expected Response:**
```json
{
  "status": "healthy",
  "message": "PawaPay webhook handler is running",
  "timestamp": "2025-11-20T...",
  "version": "2.0.0"
}
```

### **Step 2: Verify Firebase Configuration**

```bash
firebase functions:config:get
```

**Expected Output:**
```json
{
  "pawapay": {
    "api_token": "eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ...",
    "use_sandbox": "false"
  }
}
```

### **Step 3: Check Function Deployment**

```bash
firebase functions:list
```

**Expected Functions:**
- `initiatePayment` (us-central1)
- `pawaPayWebhook` (us-central1)
- `pawaPayWebhookHealth` (us-central1)

---

## 📋 PAWAPAY DASHBOARD VERIFICATION

### **Webhook Configuration Checklist**

Login to: https://dashboard.pawapay.io/

**Navigate to:** Settings → Webhooks

**Verify:**
- [ ] Callback URL: `https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook`
- [ ] HTTP Method: POST
- [ ] Events: `deposit.status.updated` is checked
- [ ] Active: Toggle is ON (green)
- [ ] "I do not wish to receive callbacks" is UNCHECKED

**Test Webhook (Optional):**
- Click "Test Webhook" button
- Should receive: ✅ 200 OK response

### **Correspondents Verification**

**Navigate to:** Settings → Correspondents

**Verify these are ENABLED:**
- [ ] MTN_MOMO_UGA (MTN Mobile Money - Uganda)
- [ ] AIRTEL_OAPI_UGA (Airtel Money - Uganda)

---

## 📱 PRODUCTION APK

### **Download Pre-Built APK**

APK with new secure architecture (API key NOT included):

**Download URL:**
```
https://www.genspark.ai/api/code_sandbox/download_file_stream?project_id=8bd01bd7-e1d6-45a8-86f6-ad3953c185e9&file_path=%2Fhome%2Fuser%2Fflutter_app%2Fbuild%2Fapp%2Foutputs%2Fflutter-apk%2Fapp-release.apk&file_name=app-release.apk
```

**APK Details:**
- Size: ~67 MB
- Version: 1.0.0
- Security: ✅ No API keys in code
- Architecture: Server-side payment initiation
- Platform: Android (ARM64 + ARMv7 + x86_64)

### **Or Build Locally**

```bash
cd sayekataleapp
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🧪 PRODUCTION TESTING PROCEDURE

### **Test Payment Flow**

1. **Install APK**
   ```bash
   adb install app-release.apk
   ```

2. **Open App and Login**
   - Email: `drnamanya@gmail.com`
   - Password: [Your password]

3. **Navigate to Premium Upgrade**
   - Go to: SME Directory
   - Click: "Upgrade to Premium" button

4. **Initiate Payment**
   - Enter YOUR mobile money number
   - Supported formats:
     - MTN: 077X, 078X, 076X, 079X, 031X, 039X
     - Airtel: 070X, 074X, 075X
   - Accept terms and conditions
   - Click: "Pay with Mobile Money"

5. **Expected Flow:**
   ```
   ✅ App shows: "Payment initiated. Please approve on your phone."
   ⏳ Wait 5-10 seconds
   ✅ Mobile money prompt appears on YOUR PHONE
   ✅ Enter PIN on phone
   ✅ Confirm payment (UGX 50,000)
   ⏳ Wait 5-15 seconds
   ✅ Subscription activates in app
   ✅ Premium features unlock
   ```

6. **Monitor During Test:**
   - **Firebase Functions Logs**: https://console.firebase.google.com/project/sayekataleapp/functions/logs
   - **Firestore Database**: https://console.firebase.google.com/project/sayekataleapp/firestore

---

## 🔍 MONITORING CHECKLIST

### **What to Look For in Firebase Logs**

**Successful Payment Logs:**
```
🔧 PawaPay Configuration: {"baseUrl":"https://api.pawapay.cloud","tokenSet":true,"mode":"PRODUCTION"}
💳 Payment initiation request: {"userId":"...","phoneNumber":"077...","amount":50000}
📱 Sanitized MSISDN: 256774000001
📡 Correspondent: MTN_MOMO_UGA
🌐 Calling PawaPay API: {"url":"https://api.pawapay.cloud/deposits","depositId":"dep_..."}
📥 PawaPay Response: {"statusCode":201,"data":{"status":"SUBMITTED"}}
✅ PawaPay deposit initiated: dep_...
```

**Webhook Processing Logs:**
```
📥 PawaPay Webhook Received
✅ Digest verified
✅ Signature verification passed
📋 Transaction found: {"depositId":"dep_...","userId":"...","status":"completed"}
✅ Payment COMPLETED: dep_..., Amount: UGX 50000
✅ Premium subscription activated for user: ...
✅ Marked as processed: dep_...
```

### **What to Check in Firestore**

**transactions/{depositId}**
```json
{
  "status": "completed",
  "metadata": {
    "msisdn": "256774000001",
    "correspondent": "MTN_MOMO_UGA",
    "pawapay_status": "COMPLETED"
  }
}
```

**subscriptions/{userId}**
```json
{
  "status": "active",
  "end_date": "2026-11-20T...",
  "payment_reference": "dep_..."
}
```

---

## ⚠️ TROUBLESHOOTING GUIDE

### **Issue: No Mobile Money Prompt**

**Check Firebase Logs for:**

**401 Unauthorized:**
```
📥 PawaPay Response: {"statusCode":401,"error":"Unauthorized"}
```
**Solution:** API token configuration issue
```bash
# Verify token is correct
firebase functions:config:get

# If wrong, reconfigure
firebase functions:config:set pawapay.api_token="YOUR_CORRECT_TOKEN"
firebase deploy --only functions
```

**403 Forbidden:**
```
📥 PawaPay Response: {"statusCode":403,"error":"Correspondent not activated"}
```
**Solution:** Enable correspondent in PawaPay Dashboard
- Go to: Settings → Correspondents
- Enable: MTN_MOMO_UGA or AIRTEL_OAPI_UGA

**400 Bad Request:**
```
📥 PawaPay Response: {"statusCode":400,"error":"Invalid MSISDN"}
```
**Solution:** Check MSISDN sanitization in logs
- Should show: `📱 Sanitized MSISDN: 256774000001`
- If wrong format, check phone number input

### **Issue: Subscription Not Activating**

**Check:**
1. Webhook URL configured in PawaPay Dashboard
2. Transaction exists in Firestore
3. Webhook logs show callback received

**Solution:**
```bash
# Check recent webhook calls
# Firebase Console → Functions → pawaPayWebhook → Logs

# Verify transaction exists
# Firestore → transactions → [search by depositId]
```

---

## ✅ SUCCESS CRITERIA

### **Deployment Success:**
- [ ] Firebase Functions deployed (3 functions)
- [ ] Configuration verified (API token + production mode)
- [ ] Webhook health endpoint returns 200 OK
- [ ] No errors in deployment logs

### **PawaPay Configuration Success:**
- [ ] Webhook URL configured correctly
- [ ] Webhook is active (green toggle)
- [ ] MTN and Airtel correspondents enabled
- [ ] Test webhook returns 200 OK

### **Payment Flow Success:**
- [ ] Payment initiated successfully
- [ ] Mobile money prompt received
- [ ] PIN entry works
- [ ] Payment completes
- [ ] Subscription activates
- [ ] Premium features accessible

---

## 🔗 QUICK REFERENCE LINKS

### **Firebase**
- **Console**: https://console.firebase.google.com/project/sayekataleapp
- **Functions**: https://console.firebase.google.com/project/sayekataleapp/functions
- **Firestore**: https://console.firebase.google.com/project/sayekataleapp/firestore
- **Logs**: https://console.firebase.google.com/project/sayekataleapp/functions/logs

### **PawaPay**
- **Dashboard**: https://dashboard.pawapay.io/
- **Documentation**: https://docs.pawapay.io/

### **GitHub**
- **Repository**: https://github.com/DrakeNamanya/sayekataleapp
- **Latest Commit**: `ea3cb35`

---

## 📞 SUPPORT

If you encounter issues:

1. **Check logs first**: Firebase Functions logs
2. **Review documentation**: DEPLOYMENT_INSTRUCTIONS.md
3. **Contact PawaPay**: support@pawapay.io
4. **Firebase Support**: Console support chat

---

**Last Updated:** November 20, 2025  
**New API Key Issued:** November 20, 2025  
**Status:** ✅ Ready for Production Deployment
