# PawaPay Integration Guide

## Overview

This document describes the PawaPay mobile money integration for the SayeKatale app's premium SME directory subscription feature.

**Feature**: Premium SME Directory Payment (UGX 50,000/year)
**Payment Methods**: MTN Mobile Money, Airtel Money
**Integration Package**: `pawa_pay_flutter ^0.0.1`

## Production Credentials

```
API Key: eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJ0dCI6IkFBVCIsInN1YiI6IjE5MTEiLCJtYXYiOiIxIiwiZXhwIjoyMDc5MTIwMDM2LCJpYXQiOjE3NjM1ODcyMzYsInBtIjoiREFGLFBBRiIsImp0aSI6Ijc4NWE5ZWFlLWM2YWQtNDNjZC1hN2RlLTA4YzQzNmJkMzQ0ZCJ9.sed2zJT2ZkNSsHm4kB-GXLejgbE5VQLHNGULX9L7mI_Vxcrcqcu6_Vb9i83nuHKZ00c3eV6-s1DWKZ1bzVYunw

Callback URL: https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook
```

**⚠️ Security Note**: The API key is currently hardcoded in `subscription_purchase_screen.dart`. For better security, consider moving it to:
- Environment variables (using `--dart-define`)
- Firebase Remote Config
- Secure backend API endpoint

## Architecture

### Component Overview

```
┌──────────────────────────┐
│   User Interface         │
│  (Purchase Screen)       │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│   PawaPay Service        │
│  - Phone validation      │
│  - Operator detection    │
│  - Payment initiation    │
│  - Transaction recording │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│   pawa_pay_flutter       │
│  Package (0.0.1)         │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│   PawaPay API            │
│  (Production)            │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│   Mobile Money Operator  │
│  (MTN / Airtel)          │
└──────────────────────────┘
```

### Key Files

1. **`lib/services/pawapay_service.dart`**
   - Core payment service
   - Phone number validation and normalization
   - Mobile money operator detection
   - Payment initiation and status handling
   - Transaction record management

2. **`lib/screens/shg/subscription_purchase_screen.dart`**
   - Payment UI
   - User input collection
   - Payment flow orchestration
   - Success/failure handling

3. **`lib/models/subscription.dart`**
   - Subscription data model
   - Already exists, no changes needed

4. **`lib/services/subscription_service.dart`**
   - Subscription management
   - Already exists, no changes needed

## Mobile Money Operator Detection

### Uganda Phone Number Prefixes

**MTN Mobile Money**:
- 077x xxx xxx
- 078x xxx xxx
- 039x xxx xxx
- 031x xxx xxx

**Airtel Money**:
- 070x xxx xxx
- 075x xxx xxx
- 020x xxx xxx

### Detection Logic

```dart
MobileMoneyOperator detectOperator(String phoneNumber) {
  // Automatically detects operator from phone number prefix
  // Returns: MobileMoneyOperator.mtn, .airtel, or .unknown
}
```

### Supported Phone Formats

- `+256772123456` (International format)
- `256772123456` (Without +)
- `0772123456` (National format)

All formats are automatically normalized to `0XXXXXXXXX` for PawaPay API.

## Payment Flow

### 1. User Initiates Payment

```dart
// User enters phone number
// Operator is detected automatically
// User clicks "Activate Subscription"
```

### 2. Payment Validation

```dart
// Validate phone number format
if (!_pawaPayService.isValidPhoneNumber(phoneNumber)) {
  // Show error
  return;
}

// Detect operator
final operator = _pawaPayService.detectOperator(phoneNumber);
if (operator == MobileMoneyOperator.unknown) {
  // Show error - unsupported operator
  return;
}
```

### 3. Payment Initiation

```dart
// Create pending transaction record in Firestore
await _createPendingTransaction(
  userId: userId,
  depositId: uuid.v4(),
  phoneNumber: phoneNumber,
  operator: operator,
);

// Initiate PawaPay deposit
final purchaseStatus = await _purchase.customerDeposit(
  phone: normalizedPhone, // "0772123456"
  amount: 50000.0, // UGX 50,000
);
```

### 4. Customer Authorization

- User receives payment prompt on their phone
- User enters Mobile Money PIN
- User approves or rejects payment

### 5. Payment Response Handling

```dart
switch (purchaseStatus) {
  case 'PAYMENT_APPROVED':
    // ✅ Success - activate subscription
    break;
  case 'PAYMENT_NOT_APPROVED':
    // ❌ User cancelled
    break;
  case 'INSUFFICIENT_BALANCE':
    // ❌ Insufficient funds
    break;
  case 'PAYER_LIMIT_REACHED':
    // ❌ Transaction limit reached
    break;
}
```

### 6. Subscription Activation

```dart
// Create subscription record
await _subscriptionService.createSubscription(
  userId: userId,
  type: SubscriptionType.smeDirectory,
  paymentMethod: 'MTN Mobile Money', // or 'Airtel Money'
  paymentReference: depositId,
);

// Update transaction status
await _updateTransactionStatus(
  depositId,
  TransactionStatus.completed,
);
```

## Transaction Recording

### Firestore Collections

#### `transactions` Collection

**Document ID**: UUID v4 (depositId)

**Fields**:
```javascript
{
  id: "uuid-v4",
  type: "shgPremiumSubscription",
  buyerId: "user_id",
  buyerName: "User Name",
  sellerId: "system",
  sellerName: "SayeKatale Platform",
  amount: 50000.0,
  serviceFee: 0.0,
  sellerReceives: 50000.0,
  status: "initiated" | "completed" | "failed",
  paymentMethod: "mtnMobileMoney" | "airtelMoney",
  paymentReference: "deposit_id",
  createdAt: Timestamp,
  completedAt: Timestamp | null,
  metadata: {
    subscription_type: "premium_sme_directory",
    phone_number: "+256772123456",
    operator: "MTN Mobile Money",
    deposit_id: "uuid"
  }
}
```

#### `subscriptions` Collection

**Document ID**: userId

**Fields**:
```javascript
{
  user_id: "user_id",
  type: "smeDirectory",
  status: "active" | "expired" | "cancelled" | "pending",
  start_date: Timestamp,
  end_date: Timestamp, // 1 year from start_date
  amount: 50000.0,
  payment_method: "MTN Mobile Money" | "Airtel Money",
  payment_reference: "deposit_id",
  created_at: Timestamp,
  cancelled_at: Timestamp | null
}
```

### Security Rules

**Updated** `/home/user/flutter_app/firestore.rules`:

```javascript
match /transactions/{transactionId} {
  // Allow users to create their own payment transactions
  allow create: if isAuthenticated() &&
                   (request.resource.data.buyerId == request.auth.uid ||
                    request.resource.data.userId == request.auth.uid);
  
  // Allow updating transaction status (for payment processing)
  allow update: if isAuthenticated() &&
                   (resource.data.buyerId == request.auth.uid) &&
                   request.resource.data.diff(resource.data).affectedKeys()
                     .hasOnly(['status', 'completedAt', 'paymentReference']);
  
  // Users can read their own transactions
  allow get: if isTransactionOwner() || isAdmin();
  allow list: if isAuthenticated();
}
```

## Error Handling

### Payment Failure Scenarios

1. **Invalid Phone Number**
   ```
   Message: "Invalid phone number format. Use +256XXXXXXXXX or 0XXXXXXXXX"
   Action: User corrects phone number
   ```

2. **Unknown Operator**
   ```
   Message: "Could not detect mobile money operator. Please use MTN or Airtel number."
   Action: User enters valid MTN/Airtel number
   ```

3. **User Cancelled Payment**
   ```
   Status: PAYMENT_NOT_APPROVED
   Message: "Payment was not approved. Please try again."
   Action: User can retry
   ```

4. **Insufficient Balance**
   ```
   Status: INSUFFICIENT_BALANCE
   Message: "Insufficient balance in your [Operator] wallet. Please top up and try again."
   Action: User tops up account and retries
   ```

5. **Transaction Limit Reached**
   ```
   Status: PAYER_LIMIT_REACHED
   Message: "You have reached your [Operator] transaction limit. Try again later or use different number."
   Action: User waits or uses different number
   ```

## Testing

### Test Credentials

**Note**: Package documentation mentions sandbox mode with `debugMode: true` and debug API key passed via `--dart-define`.

Current implementation uses **production mode** (`debugMode: false`).

### Test Phone Numbers

Refer to PawaPay documentation for test phone numbers:
- https://docs.pawapay.io/testing

### Testing Checklist

- [ ] Test MTN Mobile Money payment (077x number)
- [ ] Test Airtel Money payment (070x number)
- [ ] Test invalid phone number format
- [ ] Test unknown operator (e.g., 074x number)
- [ ] Test payment approval
- [ ] Test payment cancellation
- [ ] Test insufficient balance scenario
- [ ] Test transaction limit scenario
- [ ] Verify transaction record created in Firestore
- [ ] Verify subscription activated after payment
- [ ] Verify premium directory access granted

## Webhook Integration (Future Enhancement)

### Current Status

**⚠️ Callback URL configured but NOT IMPLEMENTED in app**:
```
https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook
```

### Implementation Recommendation

For production reliability, implement webhook handler:

1. **Backend Webhook Endpoint** (Google Cloud Run)
   - Receives PawaPay deposit callbacks
   - Validates callback signature (RFC-9421)
   - Updates transaction status
   - Activates subscription
   - Records payment in wallet

2. **Security**
   - Verify SHA-256/SHA-512 digest header
   - Verify RFC-9421 signature
   - Validate timestamp (prevent replay attacks)
   - Use idempotency (deposit ID) to prevent duplicates

3. **Callback Payload**
   ```json
   {
     "id": "uuid-v4",
     "status": "COMPLETED" | "FAILED",
     "amount": "50000.00",
     "currency": "UGX",
     "country": "UGA",
     "correspondent": "MTN_MOMO_UGA",
     "address": { "value": "256772123456" },
     "created": "2025-11-19T12:34:56Z"
   }
   ```

### Without Webhook

Current implementation:
- ✅ Uses synchronous `customerDeposit()` response
- ✅ Works for immediate payment approvals
- ⚠️ May timeout for slow payments
- ⚠️ No retry mechanism if app crashes during payment

With webhook (recommended):
- ✅ Reliable asynchronous payment confirmation
- ✅ Handles slow payments and retries
- ✅ Works even if app is closed
- ✅ Proper audit trail and reconciliation

## Monitoring & Analytics

### Key Metrics to Track

1. **Payment Success Rate**
   - Successful payments / Total attempts
   - Track by operator (MTN vs Airtel)

2. **Failure Reasons**
   - Count by failure type
   - User cancellation rate
   - Insufficient balance rate

3. **Average Payment Time**
   - Time from initiation to completion
   - Track by operator

4. **Revenue**
   - Total subscription revenue
   - Revenue by period
   - Active subscriptions count

### Firebase Analytics Events

Recommended events to track:

```dart
// Payment initiated
FirebaseAnalytics.instance.logEvent(
  name: 'premium_payment_initiated',
  parameters: {
    'operator': 'MTN', // or 'Airtel'
    'amount': 50000,
  },
);

// Payment completed
FirebaseAnalytics.instance.logEvent(
  name: 'premium_payment_completed',
  parameters: {
    'operator': 'MTN',
    'amount': 50000,
    'duration_seconds': 15,
  },
);

// Payment failed
FirebaseAnalytics.instance.logEvent(
  name: 'premium_payment_failed',
  parameters: {
    'operator': 'MTN',
    'failure_reason': 'INSUFFICIENT_BALANCE',
  },
);
```

## Troubleshooting

### Issue: Payment Stuck in "Processing"

**Symptoms**:
- Processing dialog never closes
- No success or error message

**Possible Causes**:
1. PawaPay API timeout
2. Network connectivity issues
3. customerDeposit() method hanging

**Solutions**:
1. Add timeout to customerDeposit() call
2. Implement webhook for async confirmation
3. Allow user to check payment status later

### Issue: "No Firebase App" Error

**Symptoms**:
- Firebase error when recording transaction

**Solution**:
- Ensure Firebase is initialized in main.dart
- Check `app_loader_screen.dart` completes successfully

### Issue: Transaction Record Not Created

**Symptoms**:
- Payment succeeds but no transaction in Firestore

**Possible Causes**:
1. Firestore security rules blocking write
2. Network error during transaction creation

**Solutions**:
1. Check firestore.rules allow create for transactions
2. Verify user is authenticated
3. Check transaction.toFirestore() data format

### Issue: Subscription Not Activated

**Symptoms**:
- Payment succeeds but user can't access premium directory

**Possible Causes**:
1. Subscription creation failed
2. Subscription status check incorrect

**Solutions**:
1. Check subscription_service.dart createSubscription()
2. Verify userId matches authenticated user
3. Check subscription document exists with status="active"

## Future Enhancements

### Planned Improvements

1. **Webhook Integration** (HIGH PRIORITY)
   - Implement Google Cloud Run webhook handler
   - Add payment verification and reconciliation
   - Handle async payment confirmations

2. **Payment History**
   - Show user's payment history
   - Download receipts
   - Retry failed payments

3. **Multiple Subscriptions**
   - Support different subscription tiers
   - Add auto-renewal option
   - Subscription upgrade/downgrade

4. **Analytics Dashboard**
   - Admin view of payment metrics
   - Revenue tracking
   - Operator performance comparison

5. **Better Error Recovery**
   - Implement payment status polling
   - Add "Check Payment Status" button
   - Automatic retry for network errors

## Support & Maintenance

### PawaPay Resources

- **Documentation**: https://docs.pawapay.io/
- **API Reference**: https://docs.pawapay.io/v1/api-reference
- **Support**: Contact PawaPay support team

### Package Resources

- **Package**: https://pub.dev/packages/pawa_pay_flutter
- **GitHub**: https://github.com/KanyantaM/pawa_pay_flutter
- **Issues**: https://github.com/KanyantaM/pawa_pay_flutter/issues

### Internal Contacts

- **Developer**: [Your Name]
- **Last Updated**: 2025-11-19
- **Version**: 1.0.0

## Deployment Checklist

Before deploying to production:

- [ ] Verify production API key is valid
- [ ] Test with real phone numbers (small amounts first)
- [ ] Deploy updated firestore.rules
- [ ] Monitor first few transactions closely
- [ ] Set up payment monitoring/alerts
- [ ] Document webhook endpoint (if implemented)
- [ ] Train support team on payment issues
- [ ] Create user FAQ for payment problems

## Security Best Practices

1. **API Key Management**
   - [ ] Move API key out of source code
   - [ ] Use environment variables or secure storage
   - [ ] Rotate API key periodically

2. **Transaction Security**
   - [ ] Use UUID v4 for deposit IDs
   - [ ] Implement idempotency
   - [ ] Log all payment attempts

3. **User Data**
   - [ ] Never log full phone numbers
   - [ ] Mask sensitive data in logs
   - [ ] Comply with data protection regulations

4. **Webhook Security** (when implemented)
   - [ ] Verify all webhook signatures
   - [ ] Validate request timestamp
   - [ ] Use HTTPS only
   - [ ] Implement rate limiting

---

**End of PawaPay Integration Guide**

For questions or issues, refer to the troubleshooting section or contact the development team.
