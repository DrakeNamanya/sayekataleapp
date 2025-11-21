# 📋 Firestore Collections Update Tracker

## 🎯 Purpose
Track all Firestore collections that need schema updates, security rule changes, or data migrations.

---

## 📊 Current Collections Status

### ✅ Working Collections
*(Collections that are functioning correctly)*

| Collection | Status | Notes |
|-----------|--------|-------|
| `subscriptions` | ✅ Working | Documents being created, structure correct |
| `users` | ✅ Working | User authentication and profiles |

### ⚠️ Collections with Issues

| Collection | Status | Issue | Priority |
|-----------|--------|-------|----------|
| `transactions` | ❌ Not Working | Documents not being created | 🔴 HIGH |

---

## 🔧 Collections Needing Changes

### **Please provide details for each collection that needs updates:**

**Template for each collection:**
```
Collection Name: [name]
Current Issue: [what's wrong]
Desired Changes: [what you want to change]
Fields to Add/Remove/Modify: [list fields]
Sample Data: [example of desired structure]
Priority: [High/Medium/Low]
```

---

## 📝 Identified Issues

### 1. **`transactions` Collection**

**Current Status:** ❌ Documents not being created

**Known Issues:**
- Firestore security rules blocking writes from Cloud Functions
- Cloud Functions running without authentication (`request.auth = null`)

**Required Changes:**
- [ ] Update Firestore security rules to allow Cloud Function writes
- [ ] Verify transaction document structure
- [ ] Test transaction creation after rule update

**Expected Document Structure:**
```javascript
{
  id: "dep_1763757059282_6xcbs7",
  type: "shgPremiumSubscription",
  buyerId: "SccSSc08HbQUIYH731HvGhgSJNX2",
  buyerName: "User",
  sellerId: "system",
  sellerName: "SayeKatale Platform",
  amount: 50000,
  serviceFee: 0,
  sellerReceives: 50000,
  status: "initiated", // or "SUBMITTED", "COMPLETED", "FAILED"
  paymentMethod: "mtnMobileMoney", // or "airtelMoney"
  paymentReference: "dep_1763757059282_6xcbs7",
  createdAt: Timestamp,
  completedAt: null,
  metadata: {
    subscription_type: "premium_sme_directory",
    phone_number: "0774000001",
    msisdn: "256774000001",
    operator: "MTN Mobile Money",
    deposit_id: "dep_1763757059282_6xcbs7",
    correspondent: "MTN_MOMO_UGA"
  }
}
```

---

### 2. **`subscriptions` Collection**

**Current Status:** ✅ Working (documents being created)

**Current Structure:**
```javascript
{
  user_id: "SccSSc08HbQUIYH731HvGhgSJNX2",
  type: "smeDirectory",
  status: "pending", // or "active"
  start_date: Timestamp,
  end_date: Timestamp,
  amount: 50000,
  payment_method: "Airtel Money",
  payment_reference: "TEST-1763754637613",
  created_at: Timestamp
}
```

**Potential Issues/Changes Needed:**
- [ ] *(Waiting for your input)*

---

### 3. **Other Collections**

**Please list any other collections that need updates:**

*(Waiting for your input)*

---

## 🎯 Proposed Changes

### **Section 1: [Collection Name]**
*(To be filled based on your input)*

**Current Schema:**
```javascript
{
  // Current fields
}
```

**Proposed Changes:**
- [ ] Add field: `[field_name]` - [description]
- [ ] Remove field: `[field_name]` - [reason]
- [ ] Modify field: `[field_name]` - [from X to Y]
- [ ] Rename field: `[old_name]` → `[new_name]`

**New Schema:**
```javascript
{
  // Updated fields
}
```

**Migration Required:** Yes/No
**Backward Compatible:** Yes/No

---

### **Section 2: [Another Collection]**
*(Template - repeat for each collection)*

---

## 🔒 Security Rules Updates

### **Current Rules Issues:**
- ❌ `transactions` collection: Cloud Functions can't write
- ⚠️ Other collections: *(awaiting your input)*

### **Proposed Security Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Transactions - Allow Cloud Function writes
    match /transactions/{transactionId} {
      allow create, update: if true;
      allow read: if request.auth != null && resource.data.buyerId == request.auth.uid;
    }
    
    // Subscriptions - Allow Cloud Function writes
    match /subscriptions/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow write: if true; // Allow webhook to activate
    }
    
    // Add more collection rules here based on your input
    
  }
}
```

---

## 📦 Data Migration Plan

### **Collections Requiring Migration:**

**1. [Collection Name]**
- Migration Type: [Schema update / Data cleanup / Field rename]
- Affected Documents: [Estimated count]
- Migration Script Needed: Yes/No
- Downtime Required: Yes/No
- Rollback Plan: [Description]

---

## ✅ Update Checklist

### **Pre-Update:**
- [ ] Backup existing Firestore data
- [ ] Document current schemas
- [ ] Test updates in development/staging
- [ ] Prepare rollback plan

### **During Update:**
- [ ] Deploy Firestore security rules
- [ ] Run migration scripts (if needed)
- [ ] Update Cloud Functions code
- [ ] Deploy updated Cloud Functions

### **Post-Update:**
- [ ] Verify collections are accessible
- [ ] Test CRUD operations
- [ ] Verify security rules working
- [ ] Monitor for errors in logs
- [ ] Test from mobile app

---

## 🧪 Testing Plan

### **Test Cases:**

**Test 1: Transaction Creation**
```bash
# Call initiatePayment
curl -X POST https://us-central1-sayekataleapp.cloudfunctions.net/initiatePayment \
  -H "Content-Type: application/json" \
  -d '{...}'

# Expected: Document created in transactions collection
```

**Test 2: Subscription Activation**
```bash
# Webhook callback simulation
# Expected: Subscription status changes to "active"
```

**Test 3: [Add more tests based on your changes]**

---

## 📝 Change Log

### **Changes Made:**

**[Date] - [Collection Name]**
- Change: [What was changed]
- Reason: [Why it was changed]
- Impact: [What this affects]
- Status: [Completed/In Progress/Pending]

---

## 🔗 Related Documentation

- Firestore Console: https://console.firebase.google.com/project/sayekataleapp/firestore
- Security Rules: https://console.firebase.google.com/project/sayekataleapp/firestore/rules
- Cloud Functions: https://console.firebase.google.com/project/sayekataleapp/functions

---

## 💬 Notes & Comments

*(Space for additional notes about collections and changes needed)*

---

**Please provide the following information for each collection that needs changes:**

1. **Collection name**
2. **What's currently wrong or missing**
3. **What changes you want to make**
4. **New fields to add (with types and descriptions)**
5. **Fields to remove or modify**
6. **Any specific security rule requirements**
7. **Priority level (High/Medium/Low)**

**I'll help you update each collection with the proper schema, security rules, and migration strategy!**
