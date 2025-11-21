# 🔒 SECURITY & CRITICAL FIXES APPLIED

## ⚠️ CRITICAL: API Key Security

### 🚨 IMMEDIATE ACTION REQUIRED

**The following API key was EXPOSED in client-side code and MUST be rotated immediately:**

```
eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJ0dCI6IkFBVCIsInN1YiI6IjE5MTEiLCJtYXYiOiIxIiwiZXhwIjoyMDc5MTY2MzYxLCJpYXQiOjE3NjM2MzM1NjEsInBtIjoiREFGLFBBRiIsImp0aSI6IjBlYmU3NDAwLWYxNzgtNGIyMi04ODRjLWZkZmJlODdmNjNjZiJ9.omxE-Q_5xu3wL8bq90REgP8FTPB7uWtJFgjtOZAUamuIYlOF9QlHn719zmi-kk0r7OFQUzBU3LiTi4nJdF_Tqw
```

### ✅ Steps to Rotate API Key

1. **Log in to PawaPay Dashboard**: https://dashboard.pawapay.io/
2. **Navigate to**: Settings → API Keys
3. **Revoke the exposed key** (shown above)
4. **Generate a new Production API key**
5. **Configure in Firebase**:
   ```bash
   firebase functions:config:set pawapay.api_token="YOUR_NEW_PRODUCTION_KEY"
   firebase functions:config:set pawapay.use_sandbox="false"
   ```
6. **Redeploy Cloud Functions**:
   ```bash
   cd functions
   firebase deploy --only functions:initiatePayment,functions:pawaPayWebhook
   ```

---

## ✅ SECURITY FIXES APPLIED

### 1. 🛡️ Server-Side Payment Initiation

**BEFORE (❌ INSECURE):**
- PawaPay API calls made directly from Flutter client
- API token embedded in client code
- MSISDN sent as `+256...` format
- No server-side validation

**AFTER (✅ SECURE):**
- All PawaPay API calls made from Cloud Functions backend
- API token stored in Firebase Functions config (never exposed to client)
- MSISDN sanitized to `2567XXXXXXXX` format
- Server-side validation of phone numbers and operators

### 2. 📱 Correct MSISDN Format

**BEFORE:** `+256774000001` (incorrect format with + prefix)

**AFTER:** `256774000001` (correct PawaPay MSISDN format)

**Implementation:**
```javascript
function toMsisdn(phone) {
  let cleaned = phone.replace(/[^\d+]/g, '');
  if (cleaned.startsWith('+')) cleaned = cleaned.substring(1);
  if (cleaned.startsWith('256')) return cleaned;
  if (cleaned.startsWith('0')) return '256' + cleaned.substring(1);
  return cleaned;
}
```

### 3. 🔄 Proper Subscription Flow

**BEFORE (❌ INCORRECT):**
1. Client calls PawaPay API directly
2. Subscription created as `active` immediately
3. Premium unlocked without payment confirmation
4. Webhook had no effect

**AFTER (✅ CORRECT):**
1. Client calls backend Cloud Function
2. Backend creates transaction as `initiated`
3. Backend calls PawaPay API with correct MSISDN
4. Client creates subscription as `pending`
5. User receives mobile money prompt
6. User enters PIN on phone
7. PawaPay webhook calls backend with status
8. Backend updates transaction to `completed`
9. Backend activates subscription (sets status to `active`)
10. Premium features unlock

### 4. 🔍 Structured Logging

**Added comprehensive logging at every step:**
- Payment initiation requests
- MSISDN sanitization
- Correspondent detection
- PawaPay API calls and responses
- Transaction state changes
- Subscription activation

**Example logs:**
```
🌐 Calling PawaPay API: https://api.pawapay.cloud/deposits
📤 Request body: {"depositId":"...","amount":"50000.00","msisdn":"256774000001"}
📥 PawaPay Response: {"statusCode":201,"data":{"status":"SUBMITTED"}}
✅ Transaction created: dep_1732000000_abc123
✅ Premium subscription activated for user: userId123
```

---

## 📋 NEW ARCHITECTURE

### Client-Side (Flutter)

**File:** `lib/services/pawapay_service.dart`

```dart
class PawaPayService {
  // NO API KEY in client code
  static const String _paymentInitiationUrl = 
    'https://us-central1-sayekataleapp.cloudfunctions.net/initiatePayment';

  Future<PaymentResult> initiatePremiumPayment({
    required String userId,
    required String phoneNumber,
    required String userName,
  }) async {
    // Call backend Cloud Function
    final response = await _callBackendInitiatePayment(
      userId: userId,
      phoneNumber: phoneNumber,
      amount: premiumSubscriptionPrice,
    );
    
    if (response['success'] == true) {
      // Create PENDING subscription
      await _createPendingSubscription(...);
      return PaymentResult(status: PaymentStatus.pending);
    }
  }
}
```

### Server-Side (Cloud Functions)

**File:** `functions/index.js`

```javascript
exports.initiatePayment = functions.https.onRequest(async (req, res) => {
  const { userId, phoneNumber, amount } = req.body;
  
  // Sanitize MSISDN
  const msisdn = toMsisdn(phoneNumber); // 256774000001
  
  // Detect correspondent
  const correspondent = detectCorrespondent(phoneNumber); // MTN_MOMO_UGA
  
  // Create transaction as 'initiated'
  await db.collection('transactions').doc(depositId).set({...});
  
  // Call PawaPay API with correct format
  const pawaPayResponse = await callPawaPayApi({
    depositId,
    amount,
    currency: 'UGX',
    country: 'UGA',
    correspondent,
    payer: {
      type: 'MSISDN',
      address: { value: msisdn } // NO + prefix
    }
  });
  
  return res.json({ success: true, depositId });
});
```

### Webhook Handler

**File:** `functions/index.js`

```javascript
exports.pawaPayWebhook = functions.https.onRequest(async (req, res) => {
  // Verify signature
  const signatureValid = verifyWebhookSignature(req);
  if (!signatureValid) return res.status(401).json({error: 'Invalid signature'});
  
  // Check idempotency
  if (await isAlreadyProcessed(depositId)) {
    return res.status(200).json({message: 'Already processed'});
  }
  
  // Update transaction
  await transactionRef.update({ status: 'completed' });
  
  // ACTIVATE SUBSCRIPTION (only after successful payment)
  if (status === 'COMPLETED') {
    await activatePremiumSubscription(userId, depositId, paymentMethod);
  }
  
  // Mark as processed
  await markAsProcessed(depositId);
  
  return res.status(200).json({success: true});
});
```

---

## 🔧 DEPLOYMENT CHECKLIST

### 1. Rotate API Key (CRITICAL - Do this FIRST)
- [ ] Revoke exposed API key in PawaPay Dashboard
- [ ] Generate new Production API key
- [ ] Configure in Firebase Functions config

### 2. Deploy Cloud Functions
```bash
cd /home/user/flutter_app/functions
firebase deploy --only functions:initiatePayment,functions:pawaPayWebhook
```

### 3. Update PawaPay Dashboard Webhook
- [ ] URL: `https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook`
- [ ] Method: POST
- [ ] Events: `deposit.status.updated`
- [ ] Active: Enabled

### 4. Build and Deploy Flutter App
```bash
cd /home/user/flutter_app
flutter build apk --release
```

### 5. Test Payment Flow
- [ ] Login to app
- [ ] Navigate to Premium Upgrade
- [ ] Enter real Uganda mobile money number
- [ ] **EXPECT**: Mobile money prompt on phone
- [ ] Enter PIN
- [ ] **EXPECT**: Subscription activates after successful payment

---

## 🧪 TESTING GUIDE

### Sandbox Testing (Development)

**Configure sandbox mode:**
```bash
firebase functions:config:set pawapay.use_sandbox="true"
firebase functions:config:set pawapay.api_token="YOUR_SANDBOX_KEY"
firebase deploy --only functions
```

**Test numbers:**
- **MTN**: 0772000001
- **Airtel**: 0702000001

### Production Testing (Live Money)

**Configure production mode:**
```bash
firebase functions:config:set pawapay.use_sandbox="false"
firebase functions:config:set pawapay.api_token="YOUR_PRODUCTION_KEY"
firebase deploy --only functions
```

**Test with real phone numbers:**
- **MTN**: 077/078/076/079/031/039
- **Airtel**: 070/074/075

---

## 📊 MONITORING

### Firebase Functions Logs
```
https://console.firebase.google.com/project/sayekataleapp/functions/logs
```

**Look for:**
- ✅ `🌐 Calling PawaPay API`
- ✅ `📥 Response status: 201`
- ✅ `✅ Transaction created`
- ✅ `✅ Premium subscription activated`

### Firestore Database
```
https://console.firebase.google.com/project/sayekataleapp/firestore
```

**Monitor collections:**
- **transactions**: `status` should be `initiated` → `completed`
- **subscriptions**: `status` should be `pending` → `active`
- **webhook_logs**: Verify idempotency

---

## ✅ SUCCESS CRITERIA

### Payment Initiation
- [ ] No API key in Flutter code
- [ ] Backend receives payment request
- [ ] MSISDN format is `2567XXXXXXXX` (no + prefix)
- [ ] Correspondent is correct (`MTN_MOMO_UGA` or `AIRTEL_OAPI_UGA`)
- [ ] PawaPay API returns 201 status
- [ ] Transaction created as `initiated`
- [ ] Subscription created as `pending`

### Mobile Money Prompt
- [ ] **User receives mobile money prompt on phone**
- [ ] Prompt shows correct amount (UGX 50,000)
- [ ] User can enter PIN

### Payment Completion
- [ ] Webhook receives callback from PawaPay
- [ ] Signature verification passes
- [ ] Idempotency check works
- [ ] Transaction updated to `completed`
- [ ] Subscription updated to `active`
- [ ] Premium features unlock

---

## 🚨 KNOWN ISSUES FIXED

### Issue 1: No Mobile Money Prompt
**Root Cause:** Client-side API calls with wrong MSISDN format

**Fix Applied:**
- Moved to server-side API calls
- Fixed MSISDN format to `2567XXXXXXXX`
- Added proper correspondent detection

### Issue 2: Premium Unlocks Without Payment
**Root Cause:** Subscription created as `active` immediately

**Fix Applied:**
- Subscription now created as `pending`
- Only activated by webhook after successful payment
- Premium check verifies `status === 'active'`

### Issue 3: Exposed API Key
**Root Cause:** API token embedded in Flutter client code

**Fix Applied:**
- Removed API key from client
- Stored in Firebase Functions config
- Only accessible to backend

---

## 📚 REFERENCES

- **PawaPay API Docs**: https://docs.pawapay.io/
- **MSISDN Format**: https://docs.pawapay.io/v1/api-reference/deposits
- **Webhook Signatures**: https://docs.pawapay.io/v1/api-reference/deposits/deposit-callback
- **Firebase Functions Config**: https://firebase.google.com/docs/functions/config-env

---

## 🔐 SECURITY REMINDERS

1. **NEVER commit API keys to git**
2. **ALWAYS use server-side payment initiation**
3. **ALWAYS rotate exposed API keys immediately**
4. **ALWAYS verify webhook signatures**
5. **ALWAYS use MSISDN format without + prefix**
6. **ONLY activate subscriptions after webhook confirms payment**

---

**Last Updated:** November 20, 2025  
**Status:** ✅ SECURITY FIXES APPLIED - READY FOR PRODUCTION DEPLOYMENT
