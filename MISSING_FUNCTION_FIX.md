# 🔧 Fix: Missing `initiatePayment` Function

## 🔍 Issue

After deploying Firebase Functions, only 3 functions appear in Firebase Console:
- ✅ pawaPayWebhook
- ✅ pawaPayWebhookHealth
- ✅ manualActivateSubscription
- ❌ **initiatePayment** (MISSING)

**Without `initiatePayment`, payments cannot be initiated!**

---

## ✅ Solution: Force Redeploy All Functions

The `initiatePayment` function EXISTS in the GitHub repository but wasn't deployed properly. This is likely due to:
- Firebase CLI caching issues
- Incomplete deployment
- Node modules not properly installed

---

## 🚀 Quick Fix (5 minutes)

### **Run this in Google Cloud Shell:**

```bash
cd ~/sayekataleapp
./force_deploy_all_functions.sh
```

This automated script will:
1. ✅ Clean local cache
2. ✅ Pull latest code from GitHub
3. ✅ Verify all 4 functions exist in code
4. ✅ Install dependencies
5. ✅ Force redeploy all functions
6. ✅ Test endpoints
7. ✅ Show verification results

---

## 📝 Manual Fix (If Automated Script Fails)

### **Step 1: Clean Cache**

```bash
cd ~/sayekataleapp
rm -rf functions/node_modules
rm -rf functions/.firebase
rm -f .firebase/*/cache/*
```

### **Step 2: Pull Latest Code**

```bash
git pull origin main
```

### **Step 3: Verify Functions Exist**

```bash
grep "exports.initiatePayment" functions/index.js
grep "exports.pawaPayWebhook" functions/index.js
grep "exports.pawaPayWebhookHealth" functions/index.js
grep "exports.manualActivateSubscription" functions/index.js
```

**Expected:** Each command should show the function export.

### **Step 4: Install Dependencies**

```bash
cd functions
npm install
cd ..
```

### **Step 5: Force Deploy**

```bash
npx firebase deploy --only functions --force
```

**Look for in deployment output:**

```
✔  functions[initiatePayment(us-central1)] Successful create operation.
Function URL (initiatePayment): https://us-central1-sayekataleapp.cloudfunctions.net/initiatePayment

✔  functions[pawaPayWebhook(us-central1)] Successful update operation.
✔  functions[pawaPayWebhookHealth(us-central1)] Successful update operation.
✔  functions[manualActivateSubscription(us-central1)] Successful update operation.
```

---

## 🧪 Verify Deployment

### **1. List Deployed Functions**

```bash
npx firebase functions:list
```

**Expected Output:**
```
┌─────────────────────────────┬────────┬─────────────┐
│ Function                    │ Region │ Trigger     │
├─────────────────────────────┼────────┼─────────────┤
│ initiatePayment             │ us-c1  │ HTTP        │
│ pawaPayWebhook              │ us-c1  │ HTTP        │
│ pawaPayWebhookHealth        │ us-c1  │ HTTP        │
│ manualActivateSubscription  │ us-c1  │ Callable    │
└─────────────────────────────┴────────┴─────────────┘
```

### **2. Test Endpoints**

**Test Health Check:**
```bash
curl https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhookHealth
```

**Expected Response:**
```json
{
  "status": "healthy",
  "message": "PawaPay webhook handler is running",
  "version": "2.0.0"
}
```

**Test initiatePayment Exists:**
```bash
curl -X GET https://us-central1-sayekataleapp.cloudfunctions.net/initiatePayment
```

**Expected Response:**
```json
{"error":"Method not allowed"}
```

This 405 error proves the function exists (GET not allowed, only POST).

---

## 🎯 After Successful Deployment

### **Verify in Firebase Console**

Go to: https://console.firebase.google.com/project/sayekataleapp/functions

You should see **4 functions**:

| Function | Trigger | Requests | Status |
|----------|---------|----------|--------|
| initiatePayment | HTTP | 0 | ✅ |
| pawaPayWebhook | HTTP | 1+ | ✅ |
| pawaPayWebhookHealth | HTTP | 0 | ✅ |
| manualActivateSubscription | HTTP | 0 | ✅ |

---

## 📱 Test Payment Flow

Once `initiatePayment` is deployed:

### **1. Download Production APK**

Download: [app-release.apk](https://www.genspark.ai/api/code_sandbox/download_file_stream?project_id=8bd01bd7-e1d6-45a8-86f6-ad3953c185e9&file_path=%2Fhome%2Fuser%2Fflutter_app%2Fbuild%2Fapp%2Foutputs%2Fflutter-apk%2Fapp-release.apk&file_name=app-release.apk)

### **2. Install on Android Device**

```bash
adb install app-release.apk
```

### **3. Test Real Payment**

1. Open app
2. Login: `drnamanya@gmail.com`
3. Navigate: **SME Directory → Upgrade to Premium**
4. Enter YOUR Uganda mobile money number
   - MTN: 077/078/076/079/031/039
   - Airtel: 070/074/075
5. Click "Pay with Mobile Money"

### **4. Expected Behavior**

✅ App shows: "Payment initiated. Please approve on your phone."  
✅ **Mobile money prompt appears on YOUR PHONE**  
✅ Enter PIN on phone  
✅ Payment completes (UGX 50,000)  
✅ App shows: "Subscription activated"  
✅ Premium features unlock  

### **5. Monitor During Test**

**Firebase Functions Logs:**
```
https://console.firebase.google.com/project/sayekataleapp/functions/logs
```

Look for:
```
🔧 PawaPay Configuration: {"mode":"PRODUCTION"}
💳 Payment initiation request: {"userId":"...","phoneNumber":"077...","amount":50000}
📱 Sanitized MSISDN: 256774000001
📡 Correspondent: MTN_MOMO_UGA
🌐 Calling PawaPay API
📥 Response status: 201
✅ PawaPay deposit initiated
```

**Firestore Database:**
```
https://console.firebase.google.com/project/sayekataleapp/firestore
```

Check:
- `transactions/{depositId}` - Status: `initiated` → `completed`
- `subscriptions/{userId}` - Status: `pending` → `active`

---

## 🆘 Troubleshooting

### **Issue: Still No `initiatePayment` After Deployment**

**Possible Causes:**

1. **Code not pulled correctly**
   ```bash
   cd ~/sayekataleapp
   git status
   git log origin/main..HEAD
   ```
   
   If you see uncommitted changes or unpushed commits, try:
   ```bash
   git reset --hard origin/main
   git pull origin main
   npx firebase deploy --only functions --force
   ```

2. **Wrong directory**
   ```bash
   pwd
   # Should show: /home/drnamanya/sayekataleapp
   ```

3. **Firebase project mismatch**
   ```bash
   npx firebase use
   # Should show: sayekataleapp
   ```
   
   If wrong project:
   ```bash
   npx firebase use sayekataleapp
   ```

4. **Node version incompatibility**
   ```bash
   node --version
   # Should be v20.x.x
   ```

### **Issue: Deployment Succeeds But Function Not Listed**

Try deleting and redeploying:

```bash
# Delete the function
npx firebase functions:delete initiatePayment

# Redeploy
npx firebase deploy --only functions:initiatePayment
```

### **Issue: Function Exists But Returns Errors**

Check configuration:

```bash
npx firebase functions:config:get
```

**Expected:**
```json
{
  "pawapay": {
    "api_token": "eyJ...",
    "use_sandbox": "false"
  }
}
```

If missing, reconfigure:
```bash
npx firebase functions:config:set pawapay.api_token="YOUR_NEW_API_KEY"
npx firebase functions:config:set pawapay.use_sandbox="false"
npx firebase deploy --only functions
```

---

## 📊 Success Checklist

- [ ] Ran `force_deploy_all_functions.sh` or manual steps
- [ ] Deployment shows "Successful create operation" for initiatePayment
- [ ] Firebase Console shows 4 functions
- [ ] `curl` test returns 405 error (proves function exists)
- [ ] APK downloaded and installed
- [ ] Test payment with real mobile number
- [ ] Mobile money prompt received
- [ ] Payment completed
- [ ] Subscription activated
- [ ] Premium features accessible

---

## 📚 Related Documentation

- **PRODUCTION_CONFIG.md** - Your exact configuration
- **DEPLOYMENT_CHECKLIST.md** - Complete deployment guide
- **ARCHITECTURE.md** - System architecture
- **SECURITY_CRITICAL_FIXES.md** - Security implementation

---

## 🎯 Quick Commands Summary

```bash
# Automated fix (recommended)
cd ~/sayekataleapp
./force_deploy_all_functions.sh

# Manual verification
npx firebase functions:list
curl https://us-central1-sayekataleapp.cloudfunctions.net/initiatePayment

# Test payment
# (Install APK, login, try payment with real number)
```

---

**Last Updated:** November 21, 2025  
**Issue:** Missing `initiatePayment` function  
**Solution:** Force redeploy with cache cleaning  
**Status:** ✅ Fix available - Run `force_deploy_all_functions.sh`
