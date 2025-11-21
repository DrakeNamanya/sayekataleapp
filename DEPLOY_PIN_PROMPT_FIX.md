# 🚀 DEPLOY PIN PROMPT FIX

## 🎯 What This Fix Does

**Problem**: No mobile money PIN prompts appearing on phones  
**Root Cause**: PawaPay API responses not being stored in Firestore  
**Solution**: Updated `initiatePayment` function to store all PawaPay responses

---

## 📦 What Was Fixed

### Before (Old Code)
```javascript
const pawaPayResponse = await callPawaPayApi(depositData);

if (pawaPayResponse.success) {
  return res.status(200).json({
    success: true,
    depositId: depositId,
    message: 'Payment initiated',
    status: 'SUBMITTED',
  });
}
```

**Problem**: PawaPay response discarded - can't debug issues!

### After (New Code)
```javascript
const pawaPayResponse = await callPawaPayApi(depositData);

// 🆕 STORE PAWAPAY RESPONSE IN FIRESTORE
await transactionRef.update({
  pawapay_response: pawaPayResponse,
  pawapay_status: pawaPayResponse.data?.status || 'UNKNOWN',
  pawapay_updated_at: admin.firestore.FieldValue.serverTimestamp(),
});

if (pawaPayResponse.success) {
  console.log('✅ PawaPay deposit initiated:', depositId);
  console.log('📊 PawaPay Response:', JSON.stringify(pawaPayResponse.data));
  
  return res.status(200).json({
    success: true,
    depositId: depositId,
    message: 'Payment initiated',
    status: pawaPayResponse.data?.status || 'SUBMITTED',
    pawapayData: pawaPayResponse.data, // Include full response
  });
}
```

**Benefits**: 
- ✅ Can see PawaPay's actual response
- ✅ Can diagnose PIN prompt issues
- ✅ Better error tracking
- ✅ Complete transaction lifecycle visibility

---

## 🚀 Deployment Steps

### Step 1: Open Google Cloud Shell

Go to: https://shell.cloud.google.com/

Or use this direct link:
https://console.cloud.google.com/home/dashboard?project=sayekataleapp&cloudshell=true

### Step 2: Clone Latest Code

```bash
# Remove old code if exists
rm -rf sayekataleapp

# Clone fresh from GitHub
git clone https://github.com/DrakeNamanya/sayekataleapp.git
cd sayekataleapp
```

### Step 3: Navigate to Functions Directory

```bash
cd functions
```

### Step 4: Install Dependencies

```bash
npm install
```

### Step 5: Deploy the Fix

```bash
# Deploy ONLY the initiatePayment function (faster)
firebase deploy --only functions:initiatePayment

# Or deploy all functions (slower but complete)
firebase deploy --only functions
```

**Expected Output**:
```
✔  functions[initiatePayment(us-central1)] Successful update operation.
Function URL (initiatePayment): https://us-central1-sayekataleapp.cloudfunctions.net/initiatePayment
```

### Step 6: Verify Deployment

Check Firebase Console:
https://console.firebase.google.com/project/sayekataleapp/functions

Look for:
- `initiatePayment` function status: **Deployed**
- Last deployment time: **Recent** (within minutes)

---

## 🧪 Testing After Deployment

### Test 1: Try Payment Again

**Use Flutter App**:
1. Login: drnamanya@gmail.com
2. Navigate: SHG Dashboard → "Unlock Premium"
3. Enter phone: `0744646069` (your number)
4. Click "Subscribe"
5. Wait for PIN prompt

### Test 2: Check New Transaction

After clicking subscribe, a NEW transaction will be created with the fixed code.

**Check Firestore**:
https://console.firebase.google.com/project/sayekataleapp/firestore/data/transactions

Look for the newest transaction (starts with `dep_...`)

**New Fields**:
- ✅ `pawapay_response` - Full PawaPay API response
- ✅ `pawapay_status` - Deposit status from PawaPay
- ✅ `pawapay_updated_at` - When response was stored

**Example**:
```json
{
  "id": "dep_1763762000000_xxxxx",
  "status": "initiated",
  "pawapay_response": {
    "success": true,
    "statusCode": 200,
    "data": {
      "depositId": "dep_1763762000000_xxxxx",
      "status": "SUBMITTED",
      "created": "2025-11-21T22:00:00Z"
    }
  },
  "pawapay_status": "SUBMITTED"
}
```

### Test 3: Check Firebase Logs

URL: https://console.firebase.google.com/project/sayekataleapp/functions/logs

Search for the new deposit ID.

Look for:
- `✅ PawaPay deposit initiated`
- `📊 PawaPay Response: {...}`

---

## 🔍 Diagnosing PIN Prompt Issues

After deployment, when you test payment:

### Scenario 1: PawaPay Returns Success

**Transaction shows**:
```json
{
  "pawapay_status": "SUBMITTED",
  "pawapay_response": {
    "success": true,
    "data": { "status": "SUBMITTED" }
  }
}
```

**Meaning**: PawaPay accepted the request but...
- Might be in SANDBOX mode (no real USSD)
- Phone not registered for mobile money
- Telco USSD gateway issue

**Action**: Check PawaPay Dashboard to see if deposit exists and its actual status.

### Scenario 2: PawaPay Returns Error

**Transaction shows**:
```json
{
  "status": "failed",
  "pawapay_status": "FAILED",
  "pawapay_response": {
    "success": false,
    "error": {
      "code": "INVALID_MSISDN",
      "message": "Phone number format invalid"
    }
  }
}
```

**Meaning**: PawaPay rejected the request.

**Common errors**:
- `INVALID_MSISDN` - Phone format wrong
- `INVALID_CORRESPONDENT` - Operator detection wrong
- `AUTHENTICATION_FAILED` - API token invalid
- `INSUFFICIENT_BALANCE` - PawaPay account balance low

### Scenario 3: Network/Timeout Error

**Transaction shows**:
```json
{
  "status": "initiated",
  "pawapay_response": {
    "success": false,
    "error": {
      "message": "ETIMEDOUT"
    }
  }
}
```

**Meaning**: Couldn't reach PawaPay API.

**Action**: Check internet connectivity, PawaPay API status.

---

## 🎯 Most Likely Issue: SANDBOX MODE

The most common reason for no PIN prompts is **PawaPay running in SANDBOX mode**.

### Check Current Mode

In Google Cloud Shell:

```bash
cd ~/sayekataleapp
firebase functions:config:get
```

Look for:
```json
{
  "pawapay": {
    "api_token": "xxx...",
    "use_sandbox": "true"  // ← THIS IS THE PROBLEM!
  }
}
```

If `use_sandbox: "true"`:
- ✅ API calls succeed
- ✅ Deposits created
- ❌ But no real USSD pushes sent
- ❌ No PIN prompts on phones

### Switch to Production Mode

```bash
# Set to production
firebase functions:config:set pawapay.use_sandbox="false"

# Redeploy
firebase deploy --only functions

# Verify
firebase functions:config:get
```

**⚠️ Warning**: Only switch to production if:
1. You have a valid PRODUCTION API token
2. Your PawaPay account is approved for production
3. You're ready to process real money transactions

---

## 📊 Success Criteria

After deployment, a successful payment flow should show:

### In Firestore Transaction:
```json
{
  "status": "initiated",
  "pawapay_status": "SUBMITTED",
  "pawapay_response": {
    "success": true,
    "statusCode": 200,
    "data": {
      "depositId": "dep_xxx",
      "status": "SUBMITTED"
    }
  }
}
```

### In Firebase Logs:
```
✅ PawaPay deposit initiated: dep_xxx
📊 PawaPay Response: {"depositId":"dep_xxx","status":"SUBMITTED"}
```

### On User's Phone:
- 📱 **PIN prompt appears within 30 seconds**
- User enters PIN
- Payment completes

### After Webhook:
```json
{
  "status": "completed",  // Updated by webhook
  "pawapay_status": "COMPLETED"
}
```

---

## 🔧 Troubleshooting

### Issue: Deployment Fails

**Error**: "Failed to authenticate"

**Solution**:
```bash
firebase login
firebase use sayekataleapp
firebase deploy --only functions
```

### Issue: Old Function Still Running

**Error**: Seeing old behavior after deployment

**Solution**: Wait 2-3 minutes for function to fully deploy, then:
```bash
# Force re-deploy
firebase deploy --only functions:initiatePayment --force
```

### Issue: Can't Access Google Cloud Shell

**Alternative**: Deploy from local machine:

1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Login:
   ```bash
   firebase login
   ```

3. Deploy:
   ```bash
   cd ~/sayekataleapp
   firebase deploy --only functions
   ```

---

## 🔗 Quick Links

| Resource | URL |
|----------|-----|
| **Google Cloud Shell** | https://shell.cloud.google.com/ |
| **Firebase Console** | https://console.firebase.google.com/project/sayekataleapp |
| **Functions Dashboard** | https://console.firebase.google.com/project/sayekataleapp/functions |
| **Functions Logs** | https://console.firebase.google.com/project/sayekataleapp/functions/logs |
| **Firestore Transactions** | https://console.firebase.google.com/project/sayekataleapp/firestore/data/transactions |
| **GitHub Repo** | https://github.com/DrakeNamanya/sayekataleapp |

---

## 📋 Deployment Checklist

Before deploying:
- [ ] Committed fix to GitHub
- [ ] Opened Google Cloud Shell
- [ ] Cloned latest code
- [ ] Navigated to functions directory
- [ ] Installed dependencies

Deploying:
- [ ] Run `firebase deploy --only functions:initiatePayment`
- [ ] Wait for successful deployment message
- [ ] Verify in Firebase Console

After deploying:
- [ ] Test payment with Flutter app
- [ ] Check new transaction in Firestore for `pawapay_response`
- [ ] Review Firebase Functions logs
- [ ] Verify PIN prompt appears (or check response for why not)

---

**Status**: 🚀 **READY TO DEPLOY!**

This fix will give us visibility into why PIN prompts aren't appearing. Deploy it now and retest!
