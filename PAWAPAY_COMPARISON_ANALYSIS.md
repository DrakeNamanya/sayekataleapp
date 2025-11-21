# 🔍 PawaPay Integration Analysis - Tutorial vs Our Implementation

## 📚 Reference Repository

**Repository:** https://github.com/JoelFickson/pawapay-payment-tutorial  
**Medium Article:** https://medium.com/@joelfickson/how-to-integrate-pawapay-into-your-web-app-nextjs-nodejs-810e718f84bc  
**Stack:** Next.js (Frontend) + Node.js/Express (Backend)

---

## 🎯 KEY INSIGHT: They Use PawaPay Widget API (Different from Direct API)

### **PawaPay Widget vs Direct API**

| Aspect | **Widget API** (Tutorial Uses) | **Direct Deposits API** (We Use) |
|--------|-------------------------------|-----------------------------------|
| **Endpoint** | `https://api.sandbox.pawapay.cloud/v1/widget/sessions` | `https://api.sandbox.pawapay.cloud/deposits` |
| **Purpose** | Create a checkout session with hosted payment page | Direct mobile money integration with push notification |
| **User Experience** | Redirects to PawaPay hosted page → User selects operator → Enters number → Receives prompt | App shows number input → Backend sends to operator → User receives prompt on phone |
| **Mobile Money Prompt** | Sent by PawaPay after user enters number on their page | Sent directly to user's phone number |
| **Return Flow** | Redirects back to merchant's `returnUrl` | Webhook callback to backend |
| **Best For** | Web applications, e-commerce checkouts | Mobile apps, seamless in-app payments |
| **Implementation Complexity** | Simpler (redirect flow) | More complex (direct integration) |

---

## 📊 Architecture Comparison

### **Tutorial Implementation (Widget API)**

```
┌──────────────┐
│  Next.js App │
│  (Frontend)  │
└──────┬───────┘
       │ 1. POST /payments/initiate
       │    {depositId, amount}
       ▼
┌──────────────────────┐
│  Node.js Backend     │
│  (Express)           │
└──────┬───────────────┘
       │ 2. POST /v1/widget/sessions
       │    {depositId, amount, returnUrl}
       │    Authorization: Bearer JWT_TOKEN
       ▼
┌──────────────────────┐
│  PawaPay Widget API  │
└──────┬───────────────┘
       │ 3. Returns {redirectUrl}
       ▼
┌──────────────────────┐
│  Backend             │
└──────┬───────────────┘
       │ 4. Send {redirectUrl} to frontend
       ▼
┌──────────────────────┐
│  Next.js App         │
│  window.location =   │
│  redirectUrl         │
└──────┬───────────────┘
       │ 5. User redirected to PawaPay hosted page
       ▼
┌──────────────────────────┐
│  PawaPay Hosted Page     │
│  - User selects operator │
│  - Enters phone number   │
│  - Receives MM prompt    │
└──────┬───────────────────┘
       │ 6. After payment, redirect to returnUrl
       ▼
┌──────────────────────┐
│  Merchant's Site     │
│  (returnUrl)         │
└──────────────────────┘
```

### **Our Implementation (Direct Deposits API)**

```
┌──────────────┐
│  Flutter App │
└──────┬───────┘
       │ 1. POST /initiatePayment
       │    {userId, phoneNumber, amount}
       ▼
┌────────────────────────────┐
│  Firebase Cloud Function   │
│  (initiatePayment)         │
└──────┬─────────────────────┘
       │ 2. POST /deposits
       │    {depositId, amount, currency: UGX,
       │     correspondent: MTN_MOMO_UGA,
       │     payer: {type: MSISDN, address: 256774...}}
       │    Authorization: Bearer API_TOKEN
       ▼
┌──────────────────────┐
│  PawaPay Direct API  │
└──────┬───────────────┘
       │ 3. Sends mobile money prompt DIRECTLY to user's phone
       │    (No redirect, no hosted page)
       ▼
┌──────────────────────┐
│  User's Phone        │
│  MTN/Airtel MM App   │
│  - Receives prompt   │
│  - Enters PIN        │
└──────┬───────────────┘
       │ 4. Payment completes
       ▼
┌──────────────────────────┐
│  PawaPay API             │
│  Sends webhook callback  │
└──────┬───────────────────┘
       │ 5. POST /pawaPayWebhook
       │    {depositId, status: COMPLETED, ...}
       ▼
┌────────────────────────────┐
│  Firebase Cloud Function   │
│  (pawaPayWebhook)          │
│  - Verifies signature      │
│  - Updates transaction     │
│  - Activates subscription  │
└────────────────────────────┘
```

---

## 🔍 Code Analysis

### **Tutorial Backend (Node.js/Express)**

**File:** `backend/src/app.ts`

```typescript
server.post('/payments/initiate', async (req, res) => {
    const {depositId, amount} = req.body;

    if (!depositId || !amount) {
        return res.status(400).json({
            error: true,
            message: 'Invalid request. depositId and amount are required',
        });
    }

    // ⚠️ USES WIDGET API (different endpoint)
    const response = await axios.post(
        'https://api.sandbox.pawapay.cloud/v1/widget/sessions',
        {
            depositId,
            amount,
            returnUrl: 'https://merchant.com/paymentProcessed',
        },
        {
            headers: {
                'Content-Type': 'application/json',
                Authorization: 'Bearer JWT_TOKEN_HERE',
            },
        },
    );

    const { redirectUrl } = response.data;

    return res.status(200).json({
        error: false,
        redirectUrl,  // ← Returns URL to redirect user
    });
});
```

**Key Points:**
- ✅ Uses Widget API (`/v1/widget/sessions`)
- ✅ Returns `redirectUrl` for user redirect
- ✅ Requires `returnUrl` parameter
- ❌ No webhook handling shown
- ❌ No MSISDN format handling
- ❌ No correspondent detection

### **Tutorial Frontend (Next.js)**

**File:** `frontend/app/page.tsx`

```typescript
const handlePurchase = async () => {
    const fakePaymentData = {
        depositId: "6a13259e-ff31-452f-844c-e4ce6e9d25db",
        amount: "40000",
    };

    setIsLoading({ isLoading: true });

    const response = await fetch("http://localhost:9000/payments/initiate", {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify(fakePaymentData),
    });

    if (response.ok) {
        const paymentResponse = await response.json();
        
        // ⚠️ REDIRECTS TO PAWAPAY HOSTED PAGE
        window.location.href = paymentResponse.redirectUrl;
    } else {
        alert("Payment Failed");
    }
};
```

**Key Points:**
- ✅ Calls backend to initiate payment
- ✅ Redirects user to PawaPay hosted checkout
- ❌ No phone number input (done on PawaPay page)
- ❌ No operator selection (done on PawaPay page)
- ❌ Simple redirect-based flow

### **Our Implementation (Flutter + Firebase)**

**File:** `functions/index.js` (Backend)

```javascript
exports.initiatePayment = functions.https.onRequest(async (req, res) => {
  const { userId, phoneNumber, amount } = req.body;
  
  // ✅ Sanitize MSISDN to correct format
  const msisdn = toMsisdn(phoneNumber); // 256774000001
  
  // ✅ Detect correspondent (MTN_MOMO_UGA / AIRTEL_OAPI_UGA)
  const correspondent = detectCorrespondent(phoneNumber);
  
  // ✅ Create transaction record first
  await transactionRef.set({...});
  
  // ✅ USES DIRECT DEPOSITS API (different endpoint)
  const depositData = {
    depositId: depositId,
    amount: parseFloat(amount).toFixed(2),
    currency: 'UGX',
    country: 'UGA',
    correspondent: correspondent,  // ← Direct operator selection
    payer: {
      type: 'MSISDN',
      address: {
        value: msisdn,  // ← Direct phone number (no + prefix)
      },
    },
    customerTimestamp: new Date().toISOString(),
    statementDescription: 'Premium Subscription Payment',
  };
  
  const pawaPayResponse = await callPawaPayApi(depositData);
  
  return res.status(200).json({
    success: true,
    depositId: depositId,
    message: 'Payment initiated. Please approve on your phone.',
    status: 'SUBMITTED',  // ← No redirectUrl, payment sent to phone
  });
});
```

**File:** `lib/services/pawapay_service.dart` (Frontend)

```dart
Future<PaymentResult> initiatePremiumPayment({
  required String userId,
  required String phoneNumber,
  required String userName,
}) async {
  // ✅ Validate phone number format
  if (!isValidPhoneNumber(phoneNumber)) {
    return PaymentResult(status: PaymentStatus.failed);
  }

  // ✅ Detect operator (MTN/Airtel)
  final operator = detectOperator(phoneNumber);

  // ✅ Call backend Cloud Function
  final response = await _callBackendInitiatePayment(
    userId: userId,
    phoneNumber: phoneNumber,
    amount: premiumSubscriptionPrice,
  );

  if (response['success'] == true) {
    // ✅ Create PENDING subscription
    await _createPendingSubscription(...);
    
    return PaymentResult(
      status: PaymentStatus.pending,
      depositId: response['depositId'],
    );
  }
}
```

---

## 📈 Comparison Matrix

| Feature | **Tutorial (Widget)** | **Our Implementation (Direct)** |
|---------|----------------------|----------------------------------|
| **Payment Method** | Redirect to hosted page | Direct mobile money push |
| **User Experience** | Multi-step (redirect → select → enter) | Single-step (enter number → prompt) |
| **Phone Number Input** | On PawaPay hosted page | In mobile app |
| **Operator Selection** | On PawaPay hosted page | Auto-detected by app |
| **MSISDN Format** | Not handled (PawaPay handles) | Explicitly sanitized (`2567...`) |
| **Correspondent Detection** | Not needed (Widget handles) | Required (`MTN_MOMO_UGA` / `AIRTEL_OAPI_UGA`) |
| **API Endpoint** | `/v1/widget/sessions` | `/deposits` |
| **Response** | `redirectUrl` | `depositId` + status |
| **Transaction Tracking** | Via `depositId` parameter | Via Firestore with metadata |
| **Webhook Handling** | Not shown in tutorial | Fully implemented with signature verification |
| **Subscription Management** | Not shown | Complete PENDING → ACTIVE flow |
| **Security** | API key in backend ✅ | API key in Firebase config ✅ |
| **Idempotency** | Not shown | Implemented with `webhook_logs` |
| **Best For** | Web apps, e-commerce | Mobile apps, Uganda-specific |

---

## 🎯 Which Approach Is Better?

### **Widget API (Tutorial) - Better For:**

✅ **Web Applications**
- E-commerce sites
- Online marketplaces
- Booking platforms
- Multi-country support

✅ **Simpler Implementation**
- Less code to maintain
- PawaPay handles UI
- No operator detection needed
- No MSISDN format handling

✅ **Multi-Operator Support**
- User chooses operator on PawaPay page
- Supports many operators automatically
- Good for international payments

❌ **Drawbacks:**
- Requires user to leave your site
- Multiple steps (redirect → select → enter)
- Less control over UX
- Not ideal for mobile apps

### **Direct Deposits API (Our Implementation) - Better For:**

✅ **Mobile Applications**
- Native mobile apps (Flutter, React Native)
- Seamless in-app experience
- Single-step payment flow

✅ **Country-Specific Solutions**
- Uganda-focused (MTN, Airtel)
- Pre-selected operators
- Optimized for local market

✅ **Advanced Features**
- Complete transaction tracking
- Subscription management
- Webhook-based automation
- Custom business logic

✅ **Better UX**
- No page redirects
- Instant mobile money prompt
- User stays in app

❌ **Drawbacks:**
- More complex implementation
- Need to handle MSISDN formats
- Need correspondent detection
- More code to maintain

---

## 💡 Key Learnings from Tutorial

### **1. Widget API Simplicity**

The tutorial demonstrates that PawaPay offers a simpler integration path via the Widget API:

```javascript
// Just 3 parameters needed
{
  depositId: "unique-id",
  amount: "40000",
  returnUrl: "https://merchant.com/success"
}
```

**vs our Direct API:**

```javascript
// More parameters required
{
  depositId: "unique-id",
  amount: "40000.00",
  currency: "UGX",
  country: "UGA",
  correspondent: "MTN_MOMO_UGA",
  payer: {
    type: "MSISDN",
    address: { value: "256774000001" }
  },
  customerTimestamp: "2025-11-20T...",
  statementDescription: "..."
}
```

### **2. Return URL Pattern**

Tutorial uses `returnUrl` to redirect user after payment:

```javascript
returnUrl: 'https://merchant.com/paymentProcessed'
```

We could add this as an additional confirmation mechanism:

```javascript
// In our implementation, could add
returnUrl: 'myapp://payment-success' // Deep link
```

### **3. Simple Error Handling**

Tutorial keeps it simple:

```javascript
if (response.ok) {
  window.location.href = paymentResponse.redirectUrl;
} else {
  alert("Payment Failed");
}
```

Our implementation is more detailed with specific error codes and messages.

---

## 🔧 Potential Improvements to Our Implementation

### **Option 1: Add Widget API Support (for Web Users)**

We could offer BOTH approaches:

```typescript
// New Cloud Function
exports.initiatePaymentWidget = functions.https.onRequest(async (req, res) => {
  const { userId, amount } = req.body;
  
  const depositId = generateDepositId();
  
  // Create transaction record
  await createTransaction(userId, depositId, amount);
  
  // Call Widget API
  const response = await axios.post(
    'https://api.pawapay.cloud/v1/widget/sessions',
    {
      depositId,
      amount,
      returnUrl: 'https://app.sayekatale.com/payment-success'
    },
    {
      headers: {
        Authorization: `Bearer ${PAWAPAY_API_TOKEN}`
      }
    }
  );
  
  return res.json({
    success: true,
    redirectUrl: response.data.redirectUrl,
    depositId
  });
});
```

**Flutter App:**

```dart
// Detect platform and use appropriate method
if (kIsWeb) {
  // Use Widget API for web
  final result = await initiatePaymentWidget();
  // Open redirectUrl in browser
} else {
  // Use Direct API for mobile
  final result = await initiatePremiumPayment();
  // Show "Check your phone" message
}
```

### **Option 2: Add Return URL / Deep Link**

Add deep link handling for better UX:

```dart
// In our current implementation
final depositData = {
  ...
  'returnUrl': 'sayekatale://payment-complete', // Deep link
};
```

Handle deep link in app:

```dart
// Add to AndroidManifest.xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <data android:scheme="sayekatale" />
</intent-filter>
```

### **Option 3: Simplified API for Other Use Cases**

Create a simpler API for non-subscription payments:

```typescript
exports.initiateSimplePayment = functions.https.onRequest(async (req, res) => {
  const { phoneNumber, amount, description } = req.body;
  
  // Auto-detect everything
  const msisdn = toMsisdn(phoneNumber);
  const correspondent = detectCorrespondent(phoneNumber);
  const depositId = generateDepositId();
  
  // Simple direct call
  const result = await callPawaPayApi({
    depositId,
    amount,
    currency: 'UGX',
    country: 'UGA',
    correspondent,
    payer: { type: 'MSISDN', address: { value: msisdn } }
  });
  
  return res.json({ success: true, depositId });
});
```

---

## ✅ Conclusion

### **Our Implementation Strengths:**

1. ✅ **Perfect for Mobile Apps** - Direct integration, no redirects
2. ✅ **Uganda-Optimized** - MTN and Airtel pre-configured
3. ✅ **Complete Backend** - Webhook handling, idempotency, subscription management
4. ✅ **Security** - API keys server-side, signature verification
5. ✅ **Advanced Features** - Transaction tracking, PENDING → ACTIVE flow

### **Tutorial's Strengths:**

1. ✅ **Simpler Implementation** - Less code, less complexity
2. ✅ **Better for Web** - Redirect flow works well for websites
3. ✅ **PawaPay Handles UI** - No need for operator selection
4. ✅ **Multi-Country** - Easier to support multiple countries

### **Recommendation:**

**Keep our current Direct Deposits API implementation** because:

1. We're building a **mobile app** (Flutter), not a web app
2. We need **seamless in-app payments** without redirects
3. We're **Uganda-focused** (MTN, Airtel)
4. We have **advanced requirements** (subscriptions, webhooks)
5. Our implementation is **production-ready** with complete error handling

**But consider adding Widget API as an option for:**
- Future web version of the app
- Users who prefer hosted checkout experience
- International expansion (non-Uganda countries)

---

## 📚 Documentation References

**PawaPay Widget API:**
- Endpoint: `https://api.pawapay.cloud/v1/widget/sessions`
- Use case: Hosted checkout page with redirect flow
- Best for: Web applications

**PawaPay Deposits API (What we use):**
- Endpoint: `https://api.pawapay.cloud/deposits`
- Use case: Direct mobile money integration
- Best for: Mobile applications

**Both approaches are valid** - choice depends on:
- Platform (web vs mobile)
- User experience requirements
- Implementation complexity tolerance
- Control over payment flow needed

---

**Last Updated:** November 20, 2025  
**Tutorial Reference:** https://github.com/JoelFickson/pawapay-payment-tutorial  
**Our Implementation:** https://github.com/DrakeNamanya/sayekataleapp
