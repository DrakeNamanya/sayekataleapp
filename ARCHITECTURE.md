# 🏗️ PawaPay Integration Architecture

## 📊 System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER'S PHONE                             │
│  ┌────────────────────┐         ┌─────────────────────────┐    │
│  │  Flutter App       │         │  Mobile Money App       │    │
│  │  (Android)         │         │  (MTN/Airtel)          │    │
│  │                    │         │                         │    │
│  │  [Pay Button]      │         │  [Enter PIN Prompt]    │    │
│  └─────────┬──────────┘         └────────▲────────────────┘    │
│            │                              │                      │
└────────────┼──────────────────────────────┼──────────────────────┘
             │                              │
             │ ① Payment Request            │ ③ Mobile Money Prompt
             │    (userId, phone, amount)   │
             ▼                              │
┌─────────────────────────────────────────────────────────────────┐
│               FIREBASE CLOUD FUNCTIONS (Server-Side)             │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  initiatePayment                                          │  │
│  │  ─────────────────────────────────────────────────────   │  │
│  │  1. Sanitize MSISDN: +256774000001 → 256774000001       │  │
│  │  2. Detect Correspondent: MTN_MOMO_UGA / AIRTEL_OAPI_UGA │  │
│  │  3. Create Transaction (status: initiated)                │  │
│  │  4. Call PawaPay API with Bearer token                    │  │
│  │  5. Return depositId to client                            │  │
│  └───────────────────┬──────────────────────────────────────┘  │
│                      │                                           │
│                      │ ② PawaPay API Call                       │
│                      │    POST /deposits                         │
│                      │    {depositId, msisdn, amount, ...}      │
│                      ▼                                           │
└─────────────────────────────────────────────────────────────────┘
                       │
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                      PAWAPAY API                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Production: https://api.pawapay.cloud                    │  │
│  │  Sandbox: https://api.sandbox.pawapay.cloud              │  │
│  │                                                            │  │
│  │  1. Validate API token                                    │  │
│  │  2. Validate correspondent (MTN_MOMO_UGA)                 │  │
│  │  3. Send mobile money prompt to user's phone             │  │
│  │  4. Return 201 Created (depositId)                        │  │
│  └───────────────────┬──────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
                       │
                       │ ④ Webhook Callback
                       │    POST /pawaPayWebhook
                       │    {depositId, status: "COMPLETED", ...}
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│               FIREBASE CLOUD FUNCTIONS (Webhook)                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  pawaPayWebhook                                           │  │
│  │  ─────────────────────────────────────────────────────   │  │
│  │  1. Verify webhook signature (RFC-9421)                   │  │
│  │  2. Check idempotency (prevent duplicate processing)      │  │
│  │  3. Update Transaction (status: completed)                │  │
│  │  4. Activate Subscription (status: active)                │  │
│  │  5. Mark webhook as processed                             │  │
│  │  6. Return 200 OK                                         │  │
│  └───────────────────┬──────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
                       │
                       │ ⑤ Firestore Update
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    FIREBASE FIRESTORE                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  transactions/{depositId}                                 │  │
│  │    status: initiated → completed                          │  │
│  │    metadata: {msisdn, correspondent, ...}                 │  │
│  │                                                            │  │
│  │  subscriptions/{userId}                                   │  │
│  │    status: pending → active                               │  │
│  │    end_date: +1 year                                      │  │
│  │                                                            │  │
│  │  webhook_logs/{depositId}                                 │  │
│  │    processed_at: timestamp                                │  │
│  └───────────────────┬──────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
                       │
                       │ ⑥ Real-time Update
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                         USER'S PHONE                             │
│  ┌────────────────────┐                                          │
│  │  Flutter App       │                                          │
│  │                    │                                          │
│  │  [Premium Unlocked] ✅                                        │
│  └────────────────────┘                                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Payment Flow Sequence

### Phase 1: Payment Initiation (Client → Backend)

```
User                Flutter App           Cloud Function        PawaPay API
 │                      │                       │                    │
 │ Click "Pay"          │                       │                    │
 ├─────────────────────►│                       │                    │
 │                      │ POST /initiatePayment │                    │
 │                      ├──────────────────────►│                    │
 │                      │ {userId, phone, amt}  │                    │
 │                      │                       │ Sanitize MSISDN    │
 │                      │                       │ 0774001 → 2567... │
 │                      │                       │                    │
 │                      │                       │ POST /deposits     │
 │                      │                       ├───────────────────►│
 │                      │                       │ {depositId, ...}   │
 │                      │                       │                    │
 │                      │                       │ 201 Created        │
 │                      │                       │◄───────────────────┤
 │                      │                       │                    │
 │                      │ {success, depositId}  │                    │
 │                      │◄──────────────────────┤                    │
 │                      │                       │                    │
 │ "Payment initiated"  │                       │                    │
 │◄─────────────────────┤                       │                    │
 │                      │                       │                    │
```

### Phase 2: User PIN Entry (Mobile Money)

```
User's Phone            PawaPay              Mobile Money Operator
     │                     │                          │
     │                     │ Send prompt request      │
     │                     ├─────────────────────────►│
     │                     │                          │
     │ [PIN Prompt]        │                          │
     │◄──────────────────────────────────────────────┤
     │                     │                          │
     │ Enter PIN           │                          │
     ├──────────────────────────────────────────────►│
     │                     │                          │
     │                     │ Process payment          │
     │                     │                          │
```

### Phase 3: Webhook Callback (PawaPay → Backend)

```
PawaPay API         Cloud Function         Firestore           Flutter App
     │                     │                    │                   │
     │ POST /webhook       │                    │                   │
     ├────────────────────►│                    │                   │
     │ {depositId,         │ Verify Signature   │                   │
     │  status:COMPLETED}  │                    │                   │
     │                     │                    │                   │
     │                     │ Update Transaction │                   │
     │                     ├───────────────────►│                   │
     │                     │ status: completed  │                   │
     │                     │                    │                   │
     │                     │ Activate Sub       │                   │
     │                     ├───────────────────►│                   │
     │                     │ status: active     │                   │
     │                     │                    │                   │
     │                     │                    │ Real-time Update  │
     │                     │                    ├──────────────────►│
     │                     │                    │                   │
     │ 200 OK              │                    │                   │
     │◄────────────────────┤                    │                   │
     │                     │                    │ Premium Unlocked! │
     │                     │                    │                   │
```

---

## 🔐 Security Architecture

### Data Flow Security Layers

```
┌───────────────────────────────────────────────────────────────┐
│ Layer 1: Client-Side (Flutter)                                │
│ ────────────────────────────────────────────────────────────  │
│ • NO API keys stored                                          │
│ • Only user input: phone number, amount                       │
│ • Calls backend Cloud Function (HTTPS only)                   │
│ • Receives depositId (no sensitive data)                      │
└───────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────┐
│ Layer 2: Firebase Cloud Functions (Backend)                   │
│ ────────────────────────────────────────────────────────────  │
│ • API token stored in Firebase Functions config               │
│ • Server-side validation of all inputs                        │
│ • MSISDN sanitization (2567XXXXXXXX format)                   │
│ • Correspondent detection (MTN_MOMO_UGA / AIRTEL_OAPI_UGA)    │
│ • Structured logging (no sensitive data)                      │
└───────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────┐
│ Layer 3: PawaPay API                                          │
│ ────────────────────────────────────────────────────────────  │
│ • HTTPS with Bearer token authentication                      │
│ • Request validation and correspondent verification           │
│ • Webhook signatures (RFC-9421)                               │
│ • Idempotency keys (depositId)                                │
└───────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────┐
│ Layer 4: Webhook Verification                                 │
│ ────────────────────────────────────────────────────────────  │
│ • Digest header verification (SHA-256)                        │
│ • Signature timestamp validation (replay protection)          │
│ • Idempotency check (prevent duplicate processing)            │
│ • Transaction matching in Firestore                           │
└───────────────────────────────────────────────────────────────┘
```

---

## 📦 Component Responsibilities

### Flutter App (Client)

**File:** `lib/services/pawapay_service.dart`

**Responsibilities:**
- ✅ Validate phone number format
- ✅ Detect mobile money operator
- ✅ Call backend payment initiation endpoint
- ✅ Create PENDING subscription
- ✅ Display user feedback

**Does NOT:**
- ❌ Store API keys
- ❌ Call PawaPay API directly
- ❌ Activate subscriptions
- ❌ Process webhook callbacks

### Cloud Function: initiatePayment

**File:** `functions/index.js`

**Responsibilities:**
- ✅ Sanitize MSISDN to correct format
- ✅ Detect correspondent (MTN/Airtel)
- ✅ Create transaction record (status: initiated)
- ✅ Call PawaPay API with correct parameters
- ✅ Return depositId to client
- ✅ Log all operations for debugging

**Security:**
- ✅ API token from Firebase config (not exposed)
- ✅ Server-side validation
- ✅ Structured error handling

### Cloud Function: pawaPayWebhook

**File:** `functions/index.js`

**Responsibilities:**
- ✅ Verify webhook signature (RFC-9421)
- ✅ Check idempotency (prevent duplicates)
- ✅ Update transaction status (completed/failed)
- ✅ Activate subscription (only on success)
- ✅ Mark webhook as processed
- ✅ Return HTTP 200 quickly

**Security:**
- ✅ Signature verification
- ✅ Timestamp validation
- ✅ Idempotency tracking

### Firestore Database

**Collections:**

1. **transactions/**
   - Purpose: Track all payment transactions
   - Created by: `initiatePayment` function
   - Updated by: `pawaPayWebhook` function
   - Key fields: `depositId`, `status`, `msisdn`, `correspondent`

2. **subscriptions/**
   - Purpose: Manage user premium subscriptions
   - Created by: Flutter app (status: pending)
   - Updated by: `pawaPayWebhook` (status: active)
   - Key fields: `userId`, `status`, `end_date`

3. **webhook_logs/**
   - Purpose: Idempotency tracking
   - Created by: `pawaPayWebhook` function
   - Prevents duplicate webhook processing

---

## 🌐 API Endpoints

### Client → Backend

**Endpoint:** `https://us-central1-sayekataleapp.cloudfunctions.net/initiatePayment`

**Method:** POST

**Request:**
```json
{
  "userId": "user123",
  "phoneNumber": "0774000001",
  "amount": 50000
}
```

**Response (Success):**
```json
{
  "success": true,
  "depositId": "dep_1732000000_abc123",
  "message": "Payment initiated. Please approve on your phone.",
  "status": "SUBMITTED"
}
```

**Response (Error):**
```json
{
  "success": false,
  "error": "Unknown operator for prefix 071"
}
```

### PawaPay → Backend (Webhook)

**Endpoint:** `https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook`

**Method:** POST

**Headers:**
```
Content-Type: application/json
Digest: sha-256=...
Signature: ...
Signature-Timestamp: 1732000000
```

**Body:**
```json
{
  "depositId": "dep_1732000000_abc123",
  "status": "COMPLETED",
  "amount": "50000.00",
  "currency": "UGX",
  "correspondent": "MTN_MOMO_UGA",
  "customerTimestamp": "2025-11-20T10:00:00Z",
  "created": "2025-11-20T10:00:01Z"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Webhook processed successfully",
  "depositId": "dep_1732000000_abc123",
  "status": "COMPLETED",
  "timestamp": "2025-11-20T10:00:02Z"
}
```

---

## 🔍 Data Models

### Transaction Model

```json
{
  "id": "dep_1732000000_abc123",
  "type": "shgPremiumSubscription",
  "buyerId": "user123",
  "buyerName": "User",
  "sellerId": "system",
  "sellerName": "SayeKatale Platform",
  "amount": 50000.0,
  "serviceFee": 0.0,
  "sellerReceives": 50000.0,
  "status": "completed",
  "paymentMethod": "mtnMobileMoney",
  "paymentReference": "dep_1732000000_abc123",
  "createdAt": "2025-11-20T10:00:00Z",
  "completedAt": "2025-11-20T10:00:30Z",
  "metadata": {
    "subscription_type": "premium_sme_directory",
    "phone_number": "0774000001",
    "msisdn": "256774000001",
    "operator": "MTN Mobile Money",
    "deposit_id": "dep_1732000000_abc123",
    "correspondent": "MTN_MOMO_UGA",
    "pawapay_status": "COMPLETED"
  }
}
```

### Subscription Model

```json
{
  "user_id": "user123",
  "type": "smeDirectory",
  "status": "active",
  "start_date": "2025-11-20T10:00:00Z",
  "end_date": "2026-11-20T10:00:00Z",
  "amount": 50000.0,
  "payment_method": "MTN Mobile Money",
  "payment_reference": "dep_1732000000_abc123",
  "created_at": "2025-11-20T10:00:00Z",
  "cancelled_at": null
}
```

---

## 📈 Monitoring Architecture

### Logging Strategy

```
┌────────────────────────────────────────────────────────────┐
│ Firebase Functions Logs                                     │
│ ─────────────────────────────────────────────────────────  │
│                                                             │
│ Payment Initiation:                                         │
│   🔧 PawaPay Configuration: {baseUrl, mode}                │
│   💳 Payment initiation request: {userId, phone, amount}   │
│   📱 Sanitized MSISDN: 256774000001                        │
│   📡 Correspondent: MTN_MOMO_UGA                           │
│   🌐 Calling PawaPay API: {url, depositId}                │
│   📥 PawaPay Response: {statusCode, body}                  │
│   ✅ PawaPay deposit initiated: depositId                  │
│                                                             │
│ Webhook Processing:                                         │
│   📥 PawaPay Webhook Received                              │
│   ✅ Digest verified                                       │
│   ✅ Signature verification passed                         │
│   📋 Transaction found: {depositId, userId, status}        │
│   ✅ Payment COMPLETED: depositId, Amount: UGX 50000       │
│   ✅ Premium subscription activated for user: userId       │
│   ✅ Marked as processed: depositId                        │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

### Error Tracking

```
Common Errors and Resolutions:

❌ 401 Unauthorized
   Cause: Invalid or expired API token
   Solution: Rotate API key and redeploy

❌ 403 Forbidden  
   Cause: Correspondent not activated (MTN_MOMO_UGA / AIRTEL_OAPI_UGA)
   Solution: Enable correspondent in PawaPay Dashboard

❌ 400 Bad Request
   Cause: Invalid MSISDN format or missing parameters
   Solution: Check MSISDN sanitization (should be 2567XXXXXXXX)

❌ 404 Not Found
   Cause: Wrong API endpoint
   Solution: Verify using production URL (https://api.pawapay.cloud)

❌ 500 Internal Server Error
   Cause: PawaPay service issue
   Solution: Check PawaPay status page and retry
```

---

## 🔄 State Management

### Transaction Status Flow

```
initiated ──► [PawaPay processing] ──► completed
    │                                      │
    │                                      └─► [Subscription activation]
    │
    └──► failed (if API rejects or user cancels)
```

### Subscription Status Flow

```
pending ──► [Webhook receives COMPLETED] ──► active
    │                                           │
    │                                           └─► Premium unlocked
    │
    └──► (stays pending if payment fails)
```

---

## 🎯 Design Principles

### 1. Security First
- API keys never exposed to client
- All sensitive operations server-side
- Webhook signature verification
- Idempotency for reliability

### 2. User Experience
- Immediate feedback ("Payment initiated")
- Clear error messages
- Mobile money prompt guidance
- Real-time subscription activation

### 3. Reliability
- Idempotent webhook processing
- Transaction logging
- Comprehensive error handling
- Retry-safe operations

### 4. Observability
- Structured logging at every step
- Firestore audit trail
- Real-time monitoring capabilities
- Clear error categorization

---

**Last Updated:** November 20, 2025  
**Version:** 1.0.0 - Server-Side Architecture  
**Repository:** https://github.com/DrakeNamanya/sayekataleapp
