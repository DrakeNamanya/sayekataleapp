# 🔒 Premium Subscription Locked - Ready for Payment Testing

## ✅ Current Status

**Date**: November 21, 2025, 21:00
**Test Account**: drnamanya@gmail.com
**User ID**: SccSSc08HbQUIYH731HvGhgSJNX2
**Subscription Status**: 🔒 **LOCKED** (expired)

The Premium SME Directory subscription has been successfully deactivated to enable full payment flow testing.

---

## 🎯 What to Test Now

You can now test the **complete end-to-end payment flow** from scratch:

### Step 1: Open the App
- Download the latest APK: [app-release.apk](https://www.genspark.ai/api/code_sandbox/download_file_stream?project_id=8bd01bd7-e1d6-45a8-86f6-ad3953c185e9&file_path=%2Fhome%2Fuser%2Fflutter_app%2Fbuild%2Fapp%2Foutputs%2Fflutter-apk%2Fapp-release.apk&file_name=app-release.apk)
- Or use Web Preview: https://5060-i25ra390rl3tp6c83ufw7-8f57ffe2.sandbox.novita.ai

### Step 2: Login
- Email: `drnamanya@gmail.com`
- Password: (your password)

### Step 3: Navigate to SHG Dashboard
- From home screen, go to **SHG Dashboard**
- You should see the **"Unlock Premium"** button
- It should show: "Full SME Directory • UGX 50,000/year"

### Step 4: Click "Unlock Premium"
- This will open the **Subscription Purchase Screen**
- Shows pricing: **UGX 50,000** for 1 year

### Step 5: Enter Phone Number
Test with one of these numbers:

**MTN Numbers** (Recommended for testing):
- `0774000001`
- `0774000002`
- `0774000003`

**Airtel Numbers**:
- `0744646069` (your actual number)
- `0700000001`
- `0700000002`

### Step 6: Click "Subscribe"
**Expected Flow**:
1. ⏳ App shows "Processing payment..."
2. 📞 **PIN PROMPT** appears on your phone
3. 🔐 Enter your Mobile Money PIN
4. ✅ Payment confirmed
5. 🎉 Subscription activated
6. 🚀 Access Premium SME Directory

---

## 📊 What to Monitor

### 1. Firestore Collections

**Transactions Collection**:
- URL: https://console.firebase.google.com/project/sayekataleapp/firestore/data/transactions
- Look for new document with:
  - `phone_number`: Your test number
  - `status`: `initiated` → `completed`
  - `deposit_id`: `dep_xxx...`
  - `user_id`: `SccSSc08HbQUIYH731HvGhgSJNX2`
  - `amount`: `50000`
  - `currency`: `UGX`
  - `correspondent`: `MTN_MOMO_UGA` or `AIRTEL_OAPI_UGA`

**Subscriptions Collection**:
- URL: https://console.firebase.google.com/project/sayekataleapp/firestore/data/subscriptions
- Look for updated document:
  - `status`: `pending` → `active`
  - `type`: `smeDirectory`
  - `is_active`: `true`
  - `start_date`: (timestamp)
  - `end_date`: (1 year from start)

### 2. Firebase Functions Logs

**View Logs**:
- URL: https://console.firebase.google.com/project/sayekataleapp/functions/logs

**What to Look For**:

**In `initiatePayment` logs**:
```
🔄 Initiating PawaPay payment request
Phone Number (raw): 0774000001
MSISDN (formatted): 256774000001
Correspondent detected: MTN_MOMO_UGA
✅ Transaction created with depositId: dep_xxx...
✅ PawaPay API call successful
```

**In `pawaPayWebhook` logs**:
```
🔔 Webhook received: deposit.status.updated
Deposit ID: dep_xxx...
Status: COMPLETED
Amount: 50000.00 UGX
Correspondent: MTN_MOMO_UGA
✅ Premium subscription activated
```

### 3. PawaPay Dashboard

- Login: https://dashboard.pawapay.io/
- Check **Transactions** tab for new deposit
- Status should be: `SUBMITTED` → `COMPLETED`

---

## ✅ Success Criteria

### Complete Success
- [ ] **Transaction document created** in Firestore with `status: initiated`
- [ ] **PIN prompt appeared** on phone
- [ ] **Payment completed** with PIN
- [ ] **Webhook received** and processed
- [ ] **Transaction status** updated to `completed`
- [ ] **Subscription status** updated to `active`
- [ ] **Premium SME Directory** accessible in app

### Partial Success (Troubleshooting Needed)
- [ ] Transaction created but no PIN prompt
- [ ] PIN prompt appeared but payment failed
- [ ] Payment completed but subscription not activated

---

## 🚨 Troubleshooting Guide

### Issue 1: No Transaction Document Created

**Symptoms**: 
- Click "Subscribe" but nothing happens
- No transaction in Firestore

**Solutions**:
1. **Deploy Firestore Rules**:
   ```bash
   cd ~/sayekataleapp
   git pull origin main
   firebase deploy --only firestore:rules
   ```

2. **Check Function Logs**:
   - Look for errors in: https://console.firebase.google.com/project/sayekataleapp/functions/logs
   - Search for: `initiatePayment`

3. **Verify Phone Number Format**:
   - Use: `0774000001` (with leading 0)
   - Not: `+256774000001` or `774000001`

### Issue 2: Transaction Created But No PIN Prompt

**Symptoms**:
- Transaction appears in Firestore with `status: initiated`
- No PIN prompt on phone

**Solutions**:
1. **Check PawaPay Status**:
   - Login to: https://dashboard.pawapay.io/
   - Find transaction by `deposit_id`
   - Check status and error messages

2. **Verify Phone Number**:
   - Ensure it's a real, funded mobile money account
   - Not a test number in production

3. **Check Correspondent**:
   - Transaction should have `correspondent` field
   - Value: `MTN_MOMO_UGA` or `AIRTEL_OAPI_UGA`

### Issue 3: PIN Prompt But Payment Failed

**Symptoms**:
- PIN prompt appeared
- Error message: "Insufficient funds" or "Transaction failed"

**Solutions**:
1. **Check Mobile Money Balance**:
   - Ensure account has at least UGX 50,000
   - Plus transaction fees (~1%)

2. **Try Different Number**:
   - Test with another funded account
   - Verify operator (MTN vs Airtel)

3. **Check Daily Limits**:
   - Mobile Money has daily transaction limits
   - Wait or use different account

### Issue 4: Payment Completed But Subscription Not Activated

**Symptoms**:
- Payment successful
- Transaction `status: completed`
- Subscription still `status: pending`

**Solutions**:
1. **Check Webhook Logs**:
   - Look for: `pawaPayWebhook` in logs
   - Should show: `deposit.status.updated` event

2. **Verify Webhook Configuration**:
   - PawaPay Dashboard → Settings → Webhooks
   - URL: `https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook`
   - Events: `deposit.status.updated`

3. **Manual Activation** (if needed):
   ```bash
   # In Google Cloud Shell
   firebase functions:shell
   
   # Then run:
   manualActivateSubscription({userId: 'SccSSc08HbQUIYH731HvGhgSJNX2', depositId: 'dep_xxx...'})
   ```

---

## 📝 Test Results Template

After testing, document your results:

```
## Test Execution Report
**Date**: [Date]
**Tester**: Drake Namanya
**Test Account**: drnamanya@gmail.com
**Phone Number Used**: [e.g., 0744646069]

### Results:
- [ ] Transaction created: YES / NO
- [ ] Transaction ID: [e.g., dep_1763759059282_6xcbs7]
- [ ] PIN prompt appeared: YES / NO
- [ ] Payment completed: YES / NO
- [ ] Subscription activated: YES / NO
- [ ] Premium directory accessible: YES / NO

### Issues Encountered:
[List any problems]

### Resolution:
[What fixed the issues]

### Screenshots:
[Attach screenshots of successful flow]
```

---

## 🔗 Quick Links

| Resource | URL |
|----------|-----|
| **Firestore Transactions** | https://console.firebase.google.com/project/sayekataleapp/firestore/data/transactions |
| **Firestore Subscriptions** | https://console.firebase.google.com/project/sayekataleapp/firestore/data/subscriptions |
| **Firebase Functions Logs** | https://console.firebase.google.com/project/sayekataleapp/functions/logs |
| **PawaPay Dashboard** | https://dashboard.pawapay.io/ |
| **GitHub Repository** | https://github.com/DrakeNamanya/sayekataleapp |
| **Flutter Web Preview** | https://5060-i25ra390rl3tp6c83ufw7-8f57ffe2.sandbox.novita.ai |

---

## 🎓 Understanding the Payment Flow

### Client-Side (Flutter App)
1. User clicks "Subscribe"
2. App calls `PawaPayService.initiatePayment()`
3. App makes HTTP POST to Cloud Function
4. App creates `pending` subscription in Firestore
5. App shows "Processing..." message

### Server-Side (Firebase Cloud Functions)
1. `initiatePayment` function receives request
2. Validates phone number and user ID
3. Sanitizes MSISDN: `0774000001` → `256774000001`
4. Detects correspondent: `077` prefix → `MTN_MOMO_UGA`
5. Creates transaction in Firestore (`status: initiated`)
6. Calls PawaPay Direct Deposits API
7. Returns deposit ID to app

### PawaPay Side
1. Receives deposit request
2. Validates request
3. Sends USSD push to user's phone
4. User sees PIN prompt
5. User enters PIN
6. Payment processed
7. Sends webhook callback to app

### Webhook Processing
1. `pawaPayWebhook` function receives callback
2. Verifies signature (RFC-9421)
3. Checks idempotency (prevents duplicate processing)
4. Updates transaction (`status: completed`)
5. Activates subscription (`status: active`)
6. Sets end date (1 year from now)

---

## 🚀 Next Steps After Successful Test

1. **Document Results**: Fill out test results template above
2. **Deploy to Production**: If test successful, no further deployment needed
3. **User Acceptance Testing**: Have real users test the flow
4. **Monitor Performance**: Track success rate in Firebase Analytics
5. **Optimize UX**: Based on user feedback, improve the flow

---

## 💡 Tips for Successful Testing

1. **Use Real Phone Numbers**: Test numbers won't receive PIN prompts in production
2. **Ensure Sufficient Balance**: Have at least UGX 55,000 (50k + fees)
3. **Check Internet Connection**: Both app and phone need stable connection
4. **Wait for PIN Prompt**: May take 5-30 seconds to arrive
5. **Monitor Logs in Real-Time**: Keep Firebase console open during test
6. **Test Multiple Operators**: Try both MTN and Airtel if possible

---

**Status**: 🔒 **LOCKED AND READY FOR TESTING**

The subscription has been locked successfully. You can now test the complete payment flow from subscription initiation to activation!
