# Monetization System Testing Guide

## 🧪 Testing Environment Setup

### MTN MoMo Sandbox Configuration
The app is currently configured for **MTN MoMo Sandbox** testing:

**Collection Credentials (Receive Payments)**:
```
Name: sayekatale
Primary Key: 671e6e6fda93459987a2c8a9a4ac17ec
Secondary Key: f509a9d571254950a07d8c074afa9715
```

**Disbursement Credentials (Send Payments)**:
```
Name: sayekataledisbursement
Primary Key: b37dc5e1948f4f8dab7e8e882867c1d1
Secondary Key: 52d54ed5795f4bb39b9d3c8c0458aabb
```

**Sandbox Base URL**: `https://sandbox.momodeveloper.mtn.com`

### Switching Between Sandbox and Production

In `lib/services/mtn_momo_service.dart`:
```dart
// For sandbox testing
final MtnMomoService _momoService = MtnMomoService(useSandbox: true);

// For production (AFTER full testing)
final MtnMomoService _momoService = MtnMomoService(useSandbox: false);
```

---

## 📋 Test Cases

### Phase 1: SHG → PSA Input Purchase (UGX 7,000 Fee)

#### Test Case 1.1: Mobile Money Payment Flow
**Steps**:
1. Login as SHG user
2. Navigate to "Buy Inputs" screen
3. Add PSA products to cart (e.g., UGX 50,000)
4. Proceed to checkout
5. Select "MTN Mobile Money" as payment method
6. Verify total: UGX 52,000 (50,000 product + 2,000 SHG fee)
7. Enter MTN phone number (sandbox test number)
8. Complete payment

**Expected Results**:
- ✅ Payment request sent to MTN MoMo API
- ✅ Transaction created in Firestore with status: `paymentPending`
- ✅ Order created with status: `paymentPending`
- ✅ Anti-scam banner displayed on checkout screen
- ✅ User receives USSD prompt on phone (sandbox simulation)
- ✅ After confirmation: Transaction status → `paymentHeld`
- ✅ Order status → `deliveryPending`
- ✅ PSA can see full SHG details (name, phone, location)

**Database Verification**:
```
Collection: transactions
Document: {
  type: "shgToPsaInputPurchase",
  amount: 50000,
  serviceFee: 7000,
  buyerFee: 2000,
  sellerFee: 5000,
  sellerReceives: 45000,
  status: "paymentHeld",
  paymentMethod: "mtnMobileMoney"
}

Collection: orders
Document: {
  type: "shgToPsaInputPurchase",
  subtotal: 50000,
  serviceFee: 7000,
  totalAmount: 52000,
  status: "deliveryPending"
}
```

#### Test Case 1.2: Delivery & Confirmation Flow
**Steps**:
1. Login as PSA (seller)
2. View order with status: "Awaiting Delivery"
3. Click "Mark as Delivered"
4. Verify order status → `deliveredPendingConfirmation`
5. Logout and login as SHG (buyer)
6. View order with status: "Confirm Receipt"
7. Click "Confirm Receipt"
8. Verify escrow status widget shows payment release progress

**Expected Results**:
- ✅ Order status: `deliveredPendingConfirmation` → `confirmed`
- ✅ Transaction status: `deliveredPendingConfirmation` → `disbursementPending`
- ✅ Disbursement initiated to PSA mobile number
- ✅ PSA receives: UGX 45,000 (50,000 - 5,000 seller fee)
- ✅ Transaction status → `completed`
- ✅ Order status → `completed`
- ✅ Revenue tracking updated: +UGX 7,000

#### Test Case 1.3: Payment Failure Handling
**Steps**:
1. Start SHG → PSA order
2. Enter invalid MTN phone number
3. Attempt payment

**Expected Results**:
- ✅ Transaction status: `failed`
- ✅ Error message shown to user
- ✅ Order remains in `pending` status
- ✅ User can retry payment

---

### Phase 2: SME → SHG Product Purchase (FREE - No Service Fee)

#### Test Case 2.1: 50% Deposit Payment Flow
**Steps**:
1. Login as SME user
2. Browse SHG products
3. Add items to cart (e.g., UGX 100,000)
4. Proceed to checkout
5. Select "50% Deposit + 50% on Delivery"
6. Verify deposit amount: UGX 50,000
7. Select MTN Mobile Money
8. Complete payment

**Expected Results**:
- ✅ Total amount: UGX 100,000 (no service fee)
- ✅ First payment: UGX 50,000 (deposit)
- ✅ Transaction status: `paymentHeld`
- ✅ Order status: `deliveryPending`
- ✅ Remaining balance: UGX 50,000 visible in order details

#### Test Case 2.2: Cash on Delivery (COD) Flow
**Steps**:
1. Login as SME user
2. Add SHG products to cart (e.g., UGX 30,000)
3. Select "Cash on Delivery"
4. Place order
5. Verify COD warning: "Both parties must confirm within 48 hours"
6. Login as SHG (seller)
7. Mark as delivered
8. Logout and login as SME (buyer)
9. Confirm receipt with COD confirmation dialog
10. Verify both confirmations required

**Expected Results**:
- ✅ Order created with payment method: `cashOnDelivery`
- ✅ Order status: `deliveryPending`
- ✅ No payment collection (COD)
- ✅ Anti-scam banner displayed
- ✅ After delivery: Status → `deliveredPendingConfirmation`
- ✅ Both parties must confirm
- ✅ 48-hour countdown timer displayed
- ✅ After both confirmations: Order status → `completed`

#### Test Case 2.3: COD 48-Hour Deadline
**Steps**:
1. Create COD order
2. Mark as delivered
3. Wait 48 hours (or simulate time)
4. Verify deadline enforcement

**Expected Results**:
- ✅ At 24 hours: Reminder sent to both parties
- ✅ At 36 hours: Second reminder sent
- ✅ At 48 hours: Order status → `codOverdue`
- ✅ Account flagging initiated
- ✅ Notification sent to admin dashboard

---

### Phase 3: SHG Premium Subscription (UGX 50,000/year)

#### Test Case 3.1: Subscription Purchase
**Steps**:
1. Login as SHG user
2. Navigate to "Premium SME Contacts" screen
3. View subscription benefits (should show non-premium prompt)
4. Click "Subscribe Now"
5. Enter MTN phone number
6. Complete payment (UGX 50,000)

**Expected Results**:
- ✅ Transaction created with type: `shgPremiumSubscription`
- ✅ Payment requested via MTN MoMo
- ✅ After confirmation: Subscription created
- ✅ Subscription status: `active`
- ✅ Expiry date: 365 days from now
- ✅ Premium badge displayed
- ✅ SME contacts list unlocked

**Database Verification**:
```
Collection: subscriptions
Document: {
  userId: "SHG-00001",
  type: "shgPremium",
  status: "active",
  amount: 50000,
  startDate: "2025-01-08",
  expiryDate: "2026-01-08",
  transactionId: "TXN-SUB-xxx"
}

Collection: revenue_tracking
Document (2025-01): {
  subscriptionRevenue: 50000,
  totalSubscriptions: 1
}
```

#### Test Case 3.2: Premium Features Access
**Steps**:
1. Login as premium SHG user
2. Navigate to "Premium SME Contacts"
3. Verify full access to SME list
4. Test search functionality
5. Filter by district
6. Filter by product interest
7. Click "Call" on SME contact
8. Click "Message" on SME contact

**Expected Results**:
- ✅ All SME users displayed (name, phone, location, business)
- ✅ Search works across name, district, business name
- ✅ District filter applies correctly
- ✅ Product filter applies correctly
- ✅ "Call" button opens phone dialer
- ✅ "Message" button opens SMS app
- ✅ Premium status banner shows expiry date

#### Test Case 3.3: Non-Premium Access Block
**Steps**:
1. Login as non-premium SHG user
2. Navigate to "Premium SME Contacts"
3. Verify access blocked

**Expected Results**:
- ✅ Subscription prompt displayed
- ✅ Premium benefits listed
- ✅ Pricing: UGX 50,000/year
- ✅ "Subscribe Now" button visible
- ✅ SME contacts hidden

#### Test Case 3.4: Subscription Expiry & Renewal
**Steps**:
1. Create subscription with expiry date 30 days from now
2. Wait for renewal reminder (or simulate)
3. Verify 30-day reminder sent
4. Set expiry to 7 days from now
5. Verify 7-day reminder sent
6. Set expiry to past date
7. Verify subscription status → `expired`
8. Verify premium access revoked

**Expected Results**:
- ✅ 30-day reminder: In-app notification sent
- ✅ 7-day reminder: In-app notification sent
- ✅ After expiry: Subscription status → `expired`
- ✅ Premium features locked
- ✅ Renewal prompt displayed with original subscription ID

---

### Phase 4: PSA Annual Subscription (UGX 120,000/year - MANDATORY)

#### Test Case 4.1: PSA Subscription Purchase
**Steps**:
1. Login as verified PSA user without subscription
2. Attempt to post product
3. Verify subscription prompt displayed
4. Click "Subscribe to Post Products"
5. Enter MTN phone number
6. Complete payment (UGX 120,000)

**Expected Results**:
- ✅ Subscription required before posting products
- ✅ Transaction created with type: `psaAnnualSubscription`
- ✅ Payment processed: UGX 120,000
- ✅ Subscription created with status: `active`
- ✅ Verified badge + star icon displayed
- ✅ PSA can now post products

#### Test Case 4.2: PSA Product Visibility Enforcement
**Steps**:
1. Login as PSA with active subscription
2. Post multiple products
3. Verify products visible to SHG users
4. Manually expire subscription (set expiry to past)
5. Run subscription enforcement
6. Verify products hidden from SHG users

**Expected Results**:
- ✅ Active subscription: Products visible to all SHG users
- ✅ Expired subscription: Products hidden (`isVisible: false`)
- ✅ PSA notified about expired subscription
- ✅ Products show "Subscription expired" reason
- ✅ After renewal: Products automatically re-enabled

#### Test Case 4.3: PSA Subscription Renewal
**Steps**:
1. Login as PSA with subscription expiring in 30 days
2. Verify renewal reminder displayed
3. Click "Renew Subscription"
4. Complete payment
5. Verify new subscription extends from previous expiry date

**Expected Results**:
- ✅ Renewal reminder at 30 days, 7 days
- ✅ New subscription created with type: `psaAnnual`
- ✅ Expiry date: Previous expiry + 365 days
- ✅ Products remain visible throughout renewal
- ✅ Transaction recorded with renewal metadata

---

## 🔧 Testing Tools & Commands

### View Firestore Collections
```bash
# Check transactions
firebase firestore:get transactions --limit 10

# Check subscriptions
firebase firestore:get subscriptions --limit 10

# Check orders
firebase firestore:get orders --limit 10

# Check revenue tracking
firebase firestore:get revenue_tracking
```

### Manual Payment Testing
```dart
// In Flutter app, create test button:
ElevatedButton(
  onPressed: () async {
    final momoService = MtnMomoService(useSandbox: true);
    
    // Test payment collection
    final referenceId = await momoService.requestPayment(
      amount: 1000, // Small test amount
      phoneNumber: '256XXXXXXXXX', // Your test number
      payerMessage: 'Test payment',
    );
    
    print('Payment reference: $referenceId');
    
    // Check status after 30 seconds
    await Future.delayed(Duration(seconds: 30));
    final status = await momoService.checkPaymentStatus(referenceId);
    print('Payment status: ${status.status}');
  },
  child: Text('Test MTN MoMo Payment'),
)
```

### Simulate Time for Testing
```dart
// Manually set order delivery time for COD testing
await FirebaseFirestore.instance
    .collection('orders')
    .doc(orderId)
    .update({
  'deliveredAt': Timestamp.fromDate(
    DateTime.now().subtract(Duration(hours: 49)), // Simulate 49 hours ago
  ),
});
```

---

## ⚠️ Common Issues & Solutions

### Issue 1: Payment Request Fails
**Symptoms**: Exception when calling `requestPayment`

**Solutions**:
1. Verify sandbox credentials are correct
2. Check phone number format (must be 256XXXXXXXXX)
3. Ensure MTN MoMo API subscription is active
4. Check network connectivity
5. Verify Firebase rules allow transaction creation

### Issue 2: Payment Status Always Pending
**Symptoms**: `checkPaymentStatus` returns `PENDING` indefinitely

**Solutions**:
1. In sandbox, payments may need manual approval
2. Wait 1-2 minutes before checking status
3. Verify payment reference ID is correct
4. Check MTN MoMo developer console for sandbox transactions

### Issue 3: Disbursement Fails
**Symptoms**: Error when releasing payment to seller

**Solutions**:
1. Verify disbursement credentials are correct
2. Ensure sufficient balance in collection account
3. Check seller phone number format
4. Verify transaction is in correct status (`confirmed`)

### Issue 4: Subscription Not Activating
**Symptoms**: User pays but subscription remains inactive

**Solutions**:
1. Check payment confirmation logic
2. Verify `confirmSubscriptionPayment` is called after payment
3. Check Firestore rules for subscription collection
4. Verify transaction status is `completed`

---

## 📊 Success Metrics

### Key Performance Indicators (KPIs)

**Transaction Success Rate**:
- Target: > 95%
- Measure: `completed_transactions / total_transactions`

**Payment Processing Time**:
- Target: < 2 minutes (collection + confirmation)
- Measure: Time from payment request to `paymentHeld` status

**Disbursement Success Rate**:
- Target: > 98%
- Measure: `successful_disbursements / total_disbursements`

**COD Confirmation Rate**:
- Target: > 90% within 48 hours
- Measure: `confirmed_cod_orders / delivered_cod_orders`

**Subscription Renewal Rate**:
- Target: > 70%
- Measure: `renewed_subscriptions / expired_subscriptions`

### Revenue Tracking

**Monthly Reports** (auto-generated):
```
Collection: revenue_tracking
Document (YYYY-MM): {
  month: "2025-01",
  totalRevenue: 500000,
  totalTransactions: 50,
  subscriptionRevenue: 200000,
  totalSubscriptions: 4,
  serviceFeeRevenue: 300000,
  completedAt: Timestamp
}
```

**Year 1 Projection**:
- Service Fees: UGX 28M (4,000 transactions × UGX 7,000)
- SHG Subscriptions: UGX 10M (200 subscriptions × UGX 50,000)
- PSA Subscriptions: UGX 15M (125 subscriptions × UGX 120,000)
- **Total: UGX 53M**

---

## 🚀 Going Live Checklist

### Before Production Launch:

**1. Complete Sandbox Testing**:
- ✅ All 20+ test cases passed
- ✅ Payment flows working correctly
- ✅ Escrow logic verified
- ✅ Subscription enforcement tested
- ✅ COD deadline tested

**2. Switch to Production**:
- [ ] Update `useSandbox: false` in services
- [ ] Update MTN MoMo base URL
- [ ] Verify production API credentials
- [ ] Test with small real-money amounts (UGX 1,000)

**3. Database Setup**:
- [ ] Firestore security rules reviewed
- [ ] Indexes created for query optimization
- [ ] Backup strategy implemented
- [ ] Admin dashboard deployed

**4. User Communication**:
- [ ] In-app tutorial for payment flows
- [ ] FAQ section updated
- [ ] Customer support channels ready
- [ ] Anti-scam warnings visible

**5. Monitoring & Support**:
- [ ] Transaction monitoring dashboard live
- [ ] Error alerting configured
- [ ] Support team trained on payment issues
- [ ] Refund process documented

---

## 📞 Support & Documentation

### MTN MoMo Developer Resources:
- **Developer Portal**: https://momodeveloper.mtn.com/
- **API Documentation**: https://momodeveloper.mtn.com/api-documentation
- **Support Email**: momo.api@mtn.com

### Internal Documentation:
- `MONETIZATION_IMPLEMENTATION_PLAN.md` - Complete technical architecture
- `MONETIZATION_SUMMARY.md` - Executive summary
- `lib/services/mtn_momo_service.dart` - API integration
- `lib/services/escrow_service.dart` - Escrow logic
- `lib/services/subscription_service.dart` - Subscription management

---

## 🧪 Quick Test Script

Use this script for rapid testing:

```dart
// Add to main.dart for testing purposes (REMOVE before production)
class MonetizationTestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Monetization Tests')),
      body: ListView(
        children: [
          ElevatedButton(
            onPressed: () => _testPaymentCollection(),
            child: Text('Test Payment Collection'),
          ),
          ElevatedButton(
            onPressed: () => _testDisbursement(),
            child: Text('Test Disbursement'),
          ),
          ElevatedButton(
            onPressed: () => _testSubscription(),
            child: Text('Test Subscription'),
          ),
          ElevatedButton(
            onPressed: () => _testEscrow(),
            child: Text('Test Escrow Flow'),
          ),
        ],
      ),
    );
  }
}
```

---

**Last Updated**: January 2025  
**Version**: 1.0.0  
**Status**: Ready for Sandbox Testing
