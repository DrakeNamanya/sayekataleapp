# 🔍 Transactions Not Appearing in Firestore - Investigation

## ✅ Good News
The `initiatePayment` function IS working! Your test results show:

```json
{
  "success": true,
  "depositId": "dep_1763757059282_6xcbs7",
  "message": "Payment initiated. Please approve on your phone.",
  "status": "SUBMITTED"
}
```

This means:
- ✅ Correspondent detection fixed and working
- ✅ PawaPay API called successfully
- ✅ Payment initiated successfully

## ❌ The Issue
But transactions are NOT appearing in Firestore `transactions` collection.

---

## 🔍 Possible Causes

### **1. Firestore Security Rules Blocking Writes**
The Cloud Function might not have permission to write to Firestore.

**Check Firestore Rules:**
```bash
# In Google Cloud Shell
firebase firestore:rules
```

**Expected rule for Cloud Functions:**
```javascript
// Allow Cloud Functions to write to transactions
service cloud.firestore {
  match /databases/{database}/documents {
    match /transactions/{transactionId} {
      allow read, write: if request.auth != null; // Users can read their own
      allow write: if request.auth == null; // Allow server writes
    }
  }
}
```

### **2. Transaction Creation Code Not Being Executed**
Let me check if the transaction creation code is actually running.

**Check Firebase Function Logs:**
```bash
# In Google Cloud Shell
firebase functions:log --only initiatePayment --lines 50
```

**Look for:**
- ✅ `✅ Transaction created: dep_...`
- ❌ `Error creating transaction`
- ❌ `Firestore permission denied`

### **3. Transaction Being Created But Wrong Collection Name**
The function might be writing to a different collection name.

---

## 🚀 Quick Fixes to Try

### **Fix 1: Update Firestore Security Rules**

**Run in Google Cloud Shell:**

```bash
cd ~/sayekataleapp

# Create firestore.rules file
cat > firestore.rules << 'EOF'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Transactions collection - Allow Cloud Functions to write
    match /transactions/{transactionId} {
      // Allow authenticated users to read their own transactions
      allow read: if request.auth != null && resource.data.buyerId == request.auth.uid;
      
      // Allow Cloud Functions (unauthenticated server calls) to write
      allow create, update: if true;
      
      // Allow authenticated users to create (for testing)
      allow create: if request.auth != null;
    }
    
    // Subscriptions collection
    match /subscriptions/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      // Allow Cloud Functions to write
      allow write: if true;
    }
    
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Default: deny all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
EOF

# Deploy the updated rules
firebase deploy --only firestore:rules

echo "✅ Firestore rules deployed!"
```

### **Fix 2: Check Function Logs for Errors**

```bash
# Watch logs in real-time
firebase functions:log --only initiatePayment

# Or get last 50 lines
firebase functions:log --only initiatePayment --lines 50
```

**Look for:**
- `PERMISSION_DENIED` errors
- `Missing or insufficient permissions`
- `Firestore write failed`

### **Fix 3: Test Transaction Creation Again**

After deploying new Firestore rules:

```bash
# Test with MTN number
curl -X POST https://us-central1-sayekataleapp.cloudfunctions.net/initiatePayment \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test-user-456",
    "phoneNumber": "0774000001",
    "amount": "50000"
  }'

# Then check Firestore
echo ""
echo "Now check Firestore transactions collection:"
echo "https://console.firebase.google.com/project/sayekataleapp/firestore/data/transactions"
```

---

## 🔍 Debug Steps

### **Step 1: Check Current Firestore Rules**

```bash
firebase firestore:rules
```

### **Step 2: Check Function Logs**

```bash
firebase functions:log --only initiatePayment --lines 100 | grep -E "(Transaction|transaction|error|Error|PERMISSION|Firestore)"
```

### **Step 3: Check Firestore Directly**

1. Open: https://console.firebase.google.com/project/sayekataleapp/firestore
2. Look for `transactions` collection
3. Check if ANY documents exist
4. Check document structure if they exist

### **Step 4: Enable Debug Logging**

The function already has console.log statements. Check logs:

```bash
firebase functions:log --only initiatePayment --lines 100
```

You should see:
- `💳 Payment initiation request`
- `📱 Sanitized MSISDN`
- `📡 Correspondent`
- `✅ Transaction created: dep_...` ← THIS IS KEY!

---

## 🐛 Most Likely Cause

Based on your description, the most likely cause is:

**Firestore Security Rules are blocking Cloud Function writes**

Cloud Functions run without authentication (`request.auth` is null), so if your rules require authentication, writes will be silently blocked.

---

## 🚀 Immediate Action

**Run this command block in Google Cloud Shell:**

```bash
cd ~/sayekataleapp

# Deploy Firestore rules that allow Cloud Function writes
cat > firestore.rules << 'EOF'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /transactions/{transactionId} {
      allow create, update: if true;  // Allow all writes for testing
      allow read: if request.auth != null;
    }
    
    match /subscriptions/{userId} {
      allow read, write: if request.auth != null || true;  // Allow all for testing
    }
    
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
EOF

firebase deploy --only firestore:rules

# Wait 10 seconds for rules to propagate
sleep 10

# Test again
curl -X POST https://us-central1-sayekataleapp.cloudfunctions.net/initiatePayment \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test-after-rules-update",
    "phoneNumber": "0774000001",
    "amount": "50000"
  }'

echo ""
echo "✅ Test complete! Check Firestore now:"
echo "https://console.firebase.google.com/project/sayekataleapp/firestore/data/transactions"
```

---

## 📊 What to Check After

1. **Firestore Console:** Should see new transaction document
   - Collection: `transactions`
   - Document ID: `dep_...` (the depositId from response)
   - Fields: `status`, `amount`, `phoneNumber`, etc.

2. **Function Logs:** Should see transaction creation log
   ```
   ✅ Transaction created: dep_1763757059282_6xcbs7
   ```

3. **Test Response:** Should still show success
   ```json
   {"success":true,"depositId":"dep_...","message":"Payment initiated..."}
   ```

---

## 🔗 Quick Links

- **Firestore Console:** https://console.firebase.google.com/project/sayekataleapp/firestore
- **Function Logs:** https://console.firebase.google.com/project/sayekataleapp/functions/logs
- **Firestore Rules:** https://console.firebase.google.com/project/sayekataleapp/firestore/rules

---

## 💡 Summary

**The function IS working** - payments are being initiated successfully.

**The issue:** Transactions not appearing in Firestore is likely due to **Firestore security rules blocking writes from Cloud Functions**.

**Solution:** Deploy updated Firestore rules that allow Cloud Functions to write to the `transactions` collection.

**After fix:** You should see transaction documents appear in Firestore immediately after calling the function.

---

**Run the command block above to fix this now!** 🚀
