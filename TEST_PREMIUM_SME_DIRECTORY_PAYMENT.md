# 🧪 Test Premium SME Directory Payment Flow

## 🎯 Overview

This guide walks through testing the complete Premium SME Directory subscription payment flow with PawaPay integration.

---

## 📱 Payment Flow

### **User Journey:**
```
SHG Dashboard
   ↓
Click "Unlock Premium" Card
   ↓
Subscription Purchase Screen
   ↓
Enter Phone Number (MTN/Airtel)
   ↓
Click "Subscribe" Button
   ↓
Backend: initiatePayment Cloud Function
   ↓
PawaPay API: Create Deposit
   ↓
Mobile Network: Send PIN Prompt to Phone
   ↓
User: Enter PIN and Confirm
   ↓
PawaPay: Send Webhook Callback
   ↓
Backend: pawaPayWebhook updates Firestore
   ↓
Subscription Activated!
   ↓
Access Premium SME Directory
```

---

## ✅ Pre-Test Checklist

### **1. Deploy Firestore Rules (REQUIRED)**

**If not done yet, run this first:**
```bash
cd ~/sayekataleapp && \
git pull origin main && \
firebase deploy --only firestore:rules
```

**Why:** Without updated rules, transaction documents won't be created!

### **2. Verify Cloud Functions Deployed**

Check: https://console.firebase.google.com/project/sayekataleapp/functions

**Expected functions:**
- ✅ initiatePayment
- ✅ pawaPayWebhook
- ✅ pawaPayWebhookHealth
- ✅ manualActivateSubscription

### **3. Verify PawaPay Configuration**

**API Token:** Configured in Firebase Functions config
**Webhook URL:** `https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook`
**Mode:** Production (`use_sandbox: false`)

**Check config:**
```bash
firebase functions:config:get
```

### **4. Install Latest APK**

**Download:** [app-release.apk](https://www.genspark.ai/api/code_sandbox/download_file_stream?project_id=8bd01bd7-e1d6-45a8-86f6-ad3953c185e9&file_path=%2Fhome%2Fuser%2Fflutter_app%2Fbuild%2Fapp%2Foutputs%2Fflutter-apk%2Fapp-release.apk&file_name=app-release.apk)

**Important:** Uninstall old version first if exists!

---

## 🧪 Test Procedure

### **Step 1: Open App and Navigate to Premium**

1. **Open Sayekatale app**
2. **Log in:**
   - Email: `drnamanya@gmail.com`
   - Password: Your password
3. **Navigate to SHG Dashboard**
4. **Locate "Unlock Premium" card:**
   - Should show: "Full SME Directory • UGX 50,000/year"
   - Card should be grey/silver color (inactive)

### **Step 2: Start Subscription Purchase**

1. **Tap on "Unlock Premium" card**
2. **You should see: Subscription Purchase Screen**
3. **Screen should show:**
   - Title: "Premium Subscription"
   - Price: "UGX 50,000 / year"
   - Phone number input field
   - Terms and conditions checkbox
   - "Subscribe" button

### **Step 3: Enter Payment Details**

1. **Enter your Uganda mobile number:**
   - **MTN:** 0774000001, 0784000001, 0764000001, etc.
   - **Airtel:** 0704000001, 0744646069, 0754000001, etc.

2. **Operator should be detected automatically:**
   - MTN numbers → Shows "MTN Mobile Money" icon
   - Airtel numbers → Shows "Airtel Money" icon

3. **Check terms and conditions checkbox**

4. **Click "Subscribe" button**

### **Step 4: Processing and API Call**

**You should see:**
1. ✅ Processing dialog: "Initiating payment..."
2. ✅ Dialog shows loading indicator

**Behind the scenes:**
```
Flutter app
   ↓ HTTP POST
initiatePayment Cloud Function
   ↓ Validates phone number
   ↓ Detects operator (MTN_MOMO_UGA / AIRTEL_OAPI_UGA)
   ↓ Generates depositId
   ↓ Creates transaction in Firestore
   ↓ Calls PawaPay API
PawaPay API
   ↓ Sends request to MTN/Airtel
Mobile Network
   ↓ Sends PIN prompt to your phone
```

### **Step 5: Mobile Money PIN Prompt**

**Expected:** Your phone receives a mobile money notification

**MTN Mobile Money Example:**
```
MTN Mobile Money
Pay UGX 50,000 to Sayekatale
Enter your PIN:
****
```

**Airtel Money Example:**
```
Airtel Money
Payment Request
Amount: UGX 50,000
Merchant: Sayekatale
Enter PIN:
****
```

**Important Notes:**
- PIN prompt may take 5-10 seconds to arrive
- Check your phone's notification bar
- Don't miss the prompt!

### **Step 6: Enter PIN and Confirm**

1. **Enter your mobile money PIN**
2. **Confirm the payment**
3. **Wait for confirmation SMS**

### **Step 7: Webhook Updates Subscription**

**Behind the scenes:**
```
You confirm payment
   ↓
Mobile Network processes payment
   ↓
PawaPay receives confirmation
   ↓ Webhook callback
pawaPayWebhook Cloud Function
   ↓ Updates transaction status: initiated → completed
   ↓ Activates subscription: pending → active
Firestore updated
```

**Expected time:** 2-10 seconds after PIN entry

### **Step 8: Verify Subscription Activated**

**In the app:**
1. **Go back to SHG Dashboard**
2. **The "Unlock Premium" card should now show:**
   - Title: "Premium Active" ✅
   - Details: "365 days remaining • Tap to access"
   - Card color: Purple gradient (active)
   - Green checkmark icon

3. **Tap the card again**
4. **You should now see: Premium SME Directory screen**
5. **Full access to all SME contacts!**

---

## 🔍 Monitoring During Test

### **Option 1: Firebase Console**

**1. Check Transactions Collection:**
- URL: https://console.firebase.google.com/project/sayekataleapp/firestore/data/transactions
- Look for document with ID: `dep_...`
- Check fields:
  ```
  status: "initiated" → "SUBMITTED" → "COMPLETED"
  amount: 50000
  phoneNumber: "0744646069"
  metadata.operator: "MTN Mobile Money" or "Airtel Money"
  metadata.correspondent: "MTN_MOMO_UGA" or "AIRTEL_OAPI_UGA"
  ```

**2. Check Subscriptions Collection:**
- URL: https://console.firebase.google.com/project/sayekataleapp/firestore/data/subscriptions
- Look for document with your userId
- Check fields:
  ```
  status: "pending" → "active"
  type: "smeDirectory"
  amount: 50000
  payment_reference: "dep_..." (matches transaction)
  start_date: Today
  end_date: Today + 1 year
  ```

### **Option 2: Firebase Functions Logs**

```bash
# Watch initiatePayment logs
firebase functions:log --only initiatePayment

# Watch webhook logs
firebase functions:log --only pawaPayWebhook
```

**Look for:**
- ✅ `💳 Payment initiation request`
- ✅ `📱 Sanitized MSISDN: 256774000001`
- ✅ `📡 Correspondent: MTN_MOMO_UGA`
- ✅ `✅ Transaction created: dep_...`
- ✅ `📱 Calling PawaPay API`
- ✅ `✅ PawaPay API call successful`
- ✅ `Webhook received: deposit.status.updated`
- ✅ `Activating subscription for user: ...`

### **Option 3: Test with curl (Before Mobile Test)**

```bash
# Test API endpoint first
curl -X POST https://us-central1-sayekataleapp.cloudfunctions.net/initiatePayment \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "SccSSc08HbQUIYH731HvGhgSJNX2",
    "phoneNumber": "0744646069",
    "amount": "50000"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "depositId": "dep_1763758123456_abc",
  "message": "Payment initiated. Please approve on your phone.",
  "status": "SUBMITTED"
}
```

---

## ✅ Success Criteria

### **Payment Flow Success:**
- ✅ Phone number validated and operator detected
- ✅ Processing dialog appears
- ✅ Mobile money PIN prompt received (5-10 seconds)
- ✅ Payment confirmed successfully

### **Backend Success:**
- ✅ Transaction document created in Firestore
- ✅ Transaction status: `initiated` → `SUBMITTED` → `COMPLETED`
- ✅ Subscription document created with status `pending`
- ✅ Webhook received and processed
- ✅ Subscription status updated: `pending` → `active`

### **User Experience Success:**
- ✅ "Unlock Premium" card changes to "Premium Active"
- ✅ Card shows days remaining (365)
- ✅ Card color changes to purple
- ✅ Tapping card opens Premium SME Directory
- ✅ Full access to SME contacts

---

## ❌ Troubleshooting

### **Issue 1: No Transaction in Firestore**

**Symptoms:** API returns success but no document in Firestore

**Cause:** Firestore rules not deployed

**Fix:**
```bash
cd ~/sayekataleapp && \
git pull origin main && \
firebase deploy --only firestore:rules
```

**Test again after deployment**

---

### **Issue 2: "Unknown operator" Error**

**Symptoms:** Error message: "Unknown operator for prefix XXX"

**Cause:** Phone number format issue

**Valid formats:**
- ✅ `0774000001` (local format)
- ✅ `+256774000001` (international)
- ✅ `256774000001` (without +)

**Invalid formats:**
- ❌ `774000001` (missing 0 or country code)
- ❌ `07740` (too short)

**Supported prefixes:**
- **MTN:** 077, 078, 076, 079, 031, 039
- **Airtel:** 070, 074, 075

---

### **Issue 3: No PIN Prompt Appears**

**Possible causes:**

**A. Phone number incorrect**
- Verify number is correct
- Check operator detection in app

**B. Insufficient balance**
- Ensure mobile money account has UGX 50,000+

**C. PawaPay API issue**
- Check Firebase logs for errors
- Look for PawaPay response errors

**D. Network delay**
- Wait 10-15 seconds
- PIN prompt may be delayed

---

### **Issue 4: Subscription Stays "Pending"**

**Symptoms:** Payment completed but subscription not activated

**Cause:** Webhook not updating Firestore

**Check:**
1. **Webhook URL configured in PawaPay dashboard?**
   - URL: `https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook`
   - Event: `deposit.status.updated`

2. **Check webhook logs:**
   ```bash
   firebase functions:log --only pawaPayWebhook
   ```
   - Look for: `Webhook received`
   - Look for: `Activating subscription`

3. **Manual activation (temporary workaround):**
   ```bash
   curl -X POST https://us-central1-sayekataleapp.cloudfunctions.net/manualActivateSubscription \
     -H "Content-Type: application/json" \
     -d '{
       "userId": "YOUR_USER_ID",
       "depositId": "dep_..."
     }'
   ```

---

### **Issue 5: App Crashes or Error Message**

**Check app logs:**
- Look for error messages in app
- Check if subscription was created

**Common errors:**
- **Firestore permission denied:** Rules not deployed
- **Network error:** Check internet connection
- **Invalid phone number:** Check format

---

## 📊 Test Results Template

### **Test Date:** _____________
### **Tester:** _____________
### **Phone Number Used:** _____________
### **Operator:** MTN / Airtel

### **Test Results:**

| Step | Expected | Actual | Status | Notes |
|------|----------|--------|--------|-------|
| 1. Navigate to Premium | "Unlock Premium" card visible | | ⬜ Pass / ⬜ Fail | |
| 2. Open purchase screen | Subscription screen appears | | ⬜ Pass / ⬜ Fail | |
| 3. Enter phone number | Operator detected | | ⬜ Pass / ⬜ Fail | |
| 4. Click Subscribe | Processing dialog | | ⬜ Pass / ⬜ Fail | |
| 5. Transaction created | Document in Firestore | | ⬜ Pass / ⬜ Fail | |
| 6. PIN prompt received | Notification on phone | | ⬜ Pass / ⬜ Fail | |
| 7. Enter PIN | Payment confirmed | | ⬜ Pass / ⬜ Fail | |
| 8. Subscription activated | Status = active | | ⬜ Pass / ⬜ Fail | |
| 9. Access directory | SME contacts visible | | ⬜ Pass / ⬜ Fail | |

### **Overall Result:** ⬜ PASS / ⬜ FAIL

### **Issues Encountered:**
```
(List any issues here)
```

### **Screenshots/Evidence:**
```
(Attach screenshots if possible)
```

---

## 🔗 Quick Reference Links

- **Firestore Transactions:** https://console.firebase.google.com/project/sayekataleapp/firestore/data/transactions
- **Firestore Subscriptions:** https://console.firebase.google.com/project/sayekataleapp/firestore/data/subscriptions
- **Cloud Functions:** https://console.firebase.google.com/project/sayekataleapp/functions
- **Function Logs:** https://console.firebase.google.com/project/sayekataleapp/functions/logs
- **PawaPay Dashboard:** https://dashboard.pawapay.io/
- **GitHub Repo:** https://github.com/DrakeNamanya/sayekataleapp

---

## 🎯 Summary

**What to test:**
1. ✅ Navigate to Premium SME Directory
2. ✅ Enter phone number and subscribe
3. ✅ Receive mobile money PIN prompt
4. ✅ Enter PIN and confirm payment
5. ✅ Verify subscription activated
6. ✅ Access Premium SME Directory

**Expected time:**
- Navigation: 10 seconds
- Payment initiation: 5 seconds
- PIN prompt: 5-10 seconds
- Payment confirmation: 5-10 seconds
- Subscription activation: 2-5 seconds
- **Total: ~30-40 seconds**

**After successful test:**
- ✅ Payment flow works end-to-end
- ✅ Mobile money integration functional
- ✅ Webhook activation working
- ✅ User gets access to Premium SME Directory
- ✅ Ready for production!

---

**Good luck with testing! 🚀**

**If you encounter any issues, check the Troubleshooting section above or review Firebase logs.**
