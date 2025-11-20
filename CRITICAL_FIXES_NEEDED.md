# 🚨 CRITICAL ISSUES FOUND & FIXES NEEDED

## 📊 Current Status (From Firestore Diagnostic)

### Subscription Data:
- **Status:** `active` ✅ (But should be `pending`)
- **End Date:** 364 days remaining
- **Payment Reference:** `SUB-1763650049951` (Test reference, not from PawaPay)
- **Issue:** Subscription was activated WITHOUT successful payment

### Transaction Data:
- **ALL 5 recent transactions:** `FAILED` ❌
- **Phone numbers tested:** 0744646069, 0701634653
- **Operator:** Airtel Money
- **Result:** No mobile money prompts received

---

## 🔍 ROOT CAUSES

### 1. ❌ WRONG WEBHOOK URL
**Current (in environment.dart):**
```
https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook
```

**Correct (Firebase Functions):**
```
https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook
```

**Impact:** Webhook cannot update subscriptions from `pending` to `active`

---

### 2. ❌ ALL PAWAPAY API CALLS FAILING
**Evidence:** 5 consecutive `failed` transactions

**Possible Causes:**
1. **API Endpoint Issue:** Using sandbox URL but need production URL (or vice versa)
2. **API Token Invalid:** Token might be expired or incorrect
3. **Correspondent Mismatch:** `AIRTEL_OAPI_UGA` might not be configured in PawaPay account
4. **Account Not Activated:** PawaPay sandbox/production account not fully set up

**Debug needed:** Check Firebase Functions logs for PawaPay API response

---

### 3. ⚠️ SUBSCRIPTION STATUS ISSUE
**Current:** Subscription is `active` even though no payment succeeded

**How it happened:**
- Either manual activation during testing
- OR: Bug in subscription creation logic

**Required Fix:** Reset subscription to `pending` or delete it

---

## 🔧 IMMEDIATE FIXES REQUIRED

### Fix 1: Update Webhook URL in App Code

**File:** `lib/config/environment.dart`

**Change lines 60-72:**
```dart
// OLD (WRONG):
static const String pawaPayDepositCallback = String.fromEnvironment(
  'PAWAPAY_DEPOSIT_CALLBACK',
  defaultValue: 'https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook',
);

static const String pawaPayWithdrawalCallback = String.fromEnvironment(
  'PAWAPAY_WITHDRAWAL_CALLBACK',
  defaultValue: 'https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook',
);

// NEW (CORRECT):
static const String pawaPayDepositCallback = String.fromEnvironment(
  'PAWAPAY_DEPOSIT_CALLBACK',
  defaultValue: 'https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook',
);

static const String pawaPayWithdrawalCallback = String.fromEnvironment(
  'PAWAPAY_WITHDRAWAL_CALLBACK',
  defaultValue: 'https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook',
);
```

---

### Fix 2: Verify PawaPay Dashboard Configuration

**Go to:** https://dashboard.pawapay.io/

**Settings → Webhooks → Edit:**
1. **Deposits Callback URL:** `https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook`
2. **Method:** `POST`
3. **Events:** ✅ `deposit.status.updated`
4. **Active:** ✅ Enabled

---

### Fix 3: Reset Test Subscription Data

**Delete current active subscription:**
```javascript
// Firebase Console → Firestore
// Delete document: subscriptions/SccSSc08HbQUIYH731HvGhgSJNX2
```

**OR update to pending:**
```javascript
{
  status: "pending"  // Change from "active" to "pending"
}
```

---

### Fix 4: Debug PawaPay API Failures

**Check Firebase Functions Logs:**
https://console.firebase.google.com/project/sayekataleapp/functions/logs

**Filter for:** `pawaPayService` or `PawaPay`

**Look for:**
- `🌐 Calling PawaPay API`
- `📥 Response status` - Should be 200/201, if 400/401/403 = API issue
- `📥 Response body` - Will show exact error from PawaPay

**Common PawaPay API Errors:**
- **401 Unauthorized:** API token invalid/expired
- **400 Bad Request:** Correspondent not configured or wrong parameters
- **403 Forbidden:** Account not activated for correspondent
- **404 Not Found:** Wrong API endpoint

---

### Fix 5: Verify PawaPay API Mode (Sandbox vs Production)

**Current Setting:**
```dart
// lib/services/pawapay_service.dart
final apiUrl = _debugMode ? _sandboxApiUrl : _productionApiUrl;
```

**Questions to Answer:**
1. Are you using **Sandbox** or **Production** PawaPay account?
2. Is `debugMode` set correctly when creating PawaPayService?
3. Does your API token match the environment (sandbox token for sandbox API)?

**Check in Firebase Functions logs:** Should see:
```
🌐 Calling PawaPay API: https://api.sandbox.pawapay.cloud/deposits
```
OR
```
🌐 Calling PawaPay API: https://api.pawapay.cloud/deposits
```

---

## 🧪 TESTING PLAN

### Step 1: Apply All Fixes Above

1. Update `environment.dart` webhook URLs
2. Verify PawaPay Dashboard webhook URL
3. Delete or reset test subscription
4. Rebuild APK
5. Install new APK

### Step 2: Test Payment Flow

1. Login: `drnamanya@gmail.com`
2. Navigate to: SME Directory → Upgrade to Premium
3. Enter Ugandan mobile money number
4. Initiate payment
5. **Expected:** Mobile money prompt on phone

### Step 3: Monitor Logs

**Watch for:**
- `🌐 Calling PawaPay API` - Confirms API call
- `📥 Response status: 201` - Successful deposit initiation
- `📥 Response body: {status: "SUBMITTED"}` - Payment pending user approval

**If still failing:**
- Check exact API error response in logs
- Verify API token is valid for the environment
- Confirm correspondent (`AIRTEL_OAPI_UGA` / `MTN_MOMO_UGA`) is configured in your PawaPay account

---

## 📊 SUCCESS CRITERIA

✅ Webhook URL matches deployed Firebase Function
✅ PawaPay API returns 200/201 status
✅ Transaction status changes: `failed` → `initiated`
✅ Mobile money prompt reaches phone
✅ After PIN entry: Transaction `completed`, Subscription `active`
✅ Premium features unlock ONLY after successful payment

---

## 🆘 NEXT STEPS

1. **Apply Fix 1** (webhook URL) - CRITICAL
2. **Check Firebase Functions logs** - Identify exact PawaPay API error
3. **Verify PawaPay account setup** - Ensure correspondents are activated
4. **Test with new APK** - Should receive mobile money prompt
5. **Report back** with Firebase Functions log output from next payment attempt

