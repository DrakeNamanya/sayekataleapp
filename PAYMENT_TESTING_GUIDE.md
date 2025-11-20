# 🧪 Payment Testing Guide - Uganda Mobile Money

## ✅ Phone Number Verification

Your app **already supports all the correct Uganda mobile money prefixes**:

### 🟡 MTN Mobile Money (6 prefixes)
- ✅ `077` - Original MTN prefix
- ✅ `078` - Original MTN prefix  
- ✅ `031` - Newer MTN prefix
- ✅ `039` - Newer MTN prefix
- ✅ `076` - Newer MTN prefix
- ✅ `079` - Newest MTN prefix

### 🔴 Airtel Money (3 prefixes)
- ✅ `070` - Original Airtel prefix
- ✅ `074` - Newer Airtel prefix
- ✅ `075` - Newer Airtel prefix

---

## 📱 Download Latest APK

**Version:** 1.0.0 (Nov 20, 2025)  
**Size:** 67 MB  
**Download:** [app-release.apk](https://www.genspark.ai/api/code_sandbox/download_file_stream?project_id=8bd01bd7-e1d6-45a8-86f6-ad3953c185e9&file_path=%2Fhome%2Fuser%2Fflutter_app%2Fbuild%2Fapp%2Foutputs%2Fflutter-apk%2Fapp-release.apk&file_name=app-release.apk)

**What's Fixed:**
- ✅ Removed Zambia-hardcoded package
- ✅ Direct Uganda PawaPay API integration
- ✅ Correct currency: UGX (Uganda Shillings)
- ✅ Correct country: UGA (Uganda)
- ✅ Correct correspondents: MTN_MOMO_UGA / AIRTEL_OAPI_UGA
- ✅ Proper phone format: +256XXXXXXXXX
- ✅ All 9 Uganda mobile money prefixes supported

---

## 🧪 Testing Steps

### **1. Install APK**
- Transfer APK to your Android device
- Enable "Install from Unknown Sources" if needed
- Install the app

### **2. Login**
- Email: `drnamanya@gmail.com`
- Password: (your password)

### **3. Navigate to Premium Upgrade**
- Open the app
- Go to **SME Directory**
- Tap **"Upgrade to Premium"**

### **4. Enter Phone Number**
Use a real Ugandan mobile money number:

**MTN Numbers (any of these):**
- `0772XXXXXX`
- `0783XXXXXX`
- `0313XXXXXX`
- `0393XXXXXX`
- `0763XXXXXX`
- `0793XXXXXX`

**Airtel Numbers (any of these):**
- `0702XXXXXX`
- `0743XXXXXX`
- `0753XXXXXX`

### **5. Initiate Payment**
- Accept Terms & Conditions
- Tap **"Pay with Mobile Money"**

### **6. Expected Results**

**Immediate:**
- ✅ "Payment initiated successfully" message
- ✅ Processing dialog appears
- ✅ **Mobile money prompt appears on your phone** ← KEY FIX!

**On Your Phone:**
- ✅ You receive a mobile money prompt
- ✅ Shows: "Approve payment of UGX 50,000?"
- ✅ Shows merchant: Sayekatale (or test merchant)

**After Entering PIN:**
- ✅ Payment completes
- ✅ Transaction status: `initiated` → `completed`
- ✅ Subscription status: `pending` → `active`
- ✅ You can now access SME Directory features

---

## 🔍 Troubleshooting

### Issue: "Could not detect mobile money operator"
**Solution:** Verify your number starts with:
- MTN: `077, 078, 031, 039, 076, 079`
- Airtel: `070, 074, 075`

### Issue: No mobile money prompt received
**Possible Causes:**
1. Using sandbox mode with production number (use test numbers)
2. Phone number not registered for mobile money
3. Network connectivity issues
4. PawaPay API issues

**Check:**
- Verify phone number is registered for mobile money
- Check if you can receive other mobile money transactions
- Try a different phone number

### Issue: Payment fails immediately
**Check Firebase Logs:**
https://console.firebase.google.com/project/sayekataleapp/functions/logs

**Look for:**
- `🌐 Calling PawaPay API` - Confirms API call was made
- `📤 Request body` - Verify correct correspondent (MTN_MOMO_UGA / AIRTEL_OAPI_UGA)
- `📥 Response status` - Should be 200/201/202 for success
- Error messages from PawaPay

---

## 📊 Monitoring Payment Flow

### **1. Firebase Function Logs**
https://console.firebase.google.com/project/sayekataleapp/functions/logs

**Filter:** `pawaPayWebhook`

**Expected Log Sequence:**
```
1. 🌐 Calling PawaPay API: https://api.sandbox.pawapay.cloud/deposits
2. 📤 Request body: {...correspondent: "MTN_MOMO_UGA"...}
3. 📥 Response status: 201
4. 📥 Response body: {depositId: "...", status: "SUBMITTED"}
5. (After user approves) Webhook receives: {status: "COMPLETED"}
6. ✅ Transaction updated: completed
7. ✅ Subscription updated: active
```

### **2. Firestore Collections**
https://console.firebase.google.com/project/sayekataleapp/firestore

**Check `subscriptions` collection:**
```
Document ID: SccSSc08HbQUIYH731HvGhgSJNX2
status: "pending" → "active"  (after payment)
type: "smeDirectory"
amount: 50000
payment_method: "MTN Mobile Money" or "Airtel Money"
payment_reference: <depositId>
```

**Check `transactions` collection:**
```
Document ID: <depositId>
status: "initiated" → "completed"  (after payment)
type: "shgPremiumSubscription"
amount: 50000
operator: "MTN" or "Airtel"
phone_number: <your number>
```

---

## 🎯 Test Scenarios

### **Scenario 1: MTN Payment (Most Common)**
1. Use MTN number: `077XXXXXXX`
2. Initiate payment
3. Receive MTN prompt: `*165*3#`
4. Enter PIN
5. Verify payment completes

### **Scenario 2: Airtel Payment**
1. Use Airtel number: `070XXXXXXX`
2. Initiate payment
3. Receive Airtel prompt
4. Enter PIN
5. Verify payment completes

### **Scenario 3: Different MTN Prefixes**
Test with each prefix to verify operator detection:
- `077` ✅
- `078` ✅
- `031` ✅
- `039` ✅
- `076` ✅
- `079` ✅

### **Scenario 4: Different Airtel Prefixes**
Test with each prefix:
- `070` ✅
- `074` ✅
- `075` ✅

---

## 🐛 Known Issues & Solutions

### Already Fixed ✅
- ❌ ~~Zambia country code (ZMB)~~ → ✅ Uganda (UGA)
- ❌ ~~Zambian currency (ZMW)~~ → ✅ Uganda Shillings (UGX)
- ❌ ~~Zambian correspondents~~ → ✅ Uganda correspondents
- ❌ ~~Missing newer MTN prefixes (076, 079)~~ → ✅ All prefixes supported
- ❌ ~~Missing Airtel 074 prefix~~ → ✅ All prefixes supported

### Remaining Limitations
- ⚠️ Sandbox mode may have limited phone number testing
- ⚠️ Webhook requires proper PawaPay configuration
- ⚠️ Some older or unregistered numbers may not work

---

## 📞 Support & Documentation

**GitHub Repository:**  
https://github.com/DrakeNamanya/sayekataleapp

**Firebase Console:**  
https://console.firebase.google.com/project/sayekataleapp

**PawaPay Documentation:**  
https://docs.pawapay.io/

**Reference Docs:**
- `UGANDA_MOBILE_NUMBERS.md` - Complete phone number reference
- `PAYMENT_FLOW_SUCCESS.md` - Payment flow documentation
- `WEBHOOK_DEPLOYMENT_GUIDE.md` - Webhook setup guide

---

## ✅ Confirmation Checklist

Before reporting issues, verify:

- [ ] Using latest APK (Nov 20, 2025 - 67 MB)
- [ ] Phone number is Ugandan (077/078/031/039/076/079 or 070/074/075)
- [ ] Phone number is registered for mobile money
- [ ] Phone has sufficient balance (UGX 50,000+)
- [ ] Mobile money account is active
- [ ] Network connectivity is stable
- [ ] Checked Firebase logs for errors
- [ ] Verified webhook is deployed and configured

---

**Last Updated:** November 20, 2025  
**App Version:** 1.0.0  
**APK Build:** Nov 20, 2025 10:52 UTC
