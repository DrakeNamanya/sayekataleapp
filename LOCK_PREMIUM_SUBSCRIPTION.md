# 🔒 Lock Premium Subscription - Testing Preparation

## 🎯 Goal
Remove/deactivate the premium subscription for `drnamanya@gmail.com` so we can test the payment flow from scratch.

---

## 🔍 Step 1: Find User ID

First, we need to find the user ID for `drnamanya@gmail.com`.

### **Option A: Firebase Console (Easiest)**

1. Open: https://console.firebase.google.com/project/sayekataleapp/firestore/data/users
2. Look through users collection
3. Find document where `email = "drnamanya@gmail.com"`
4. Copy the document ID (this is the userId)

### **Option B: Firebase Authentication**

1. Open: https://console.firebase.google.com/project/sayekataleapp/authentication/users
2. Search for: `drnamanya@gmail.com`
3. Click on the user
4. Copy the UID

---

## 🔒 Step 2: Delete/Deactivate Subscription

Once you have the userId, you have 3 options:

### **Option 1: Delete Subscription Document (Recommended for Testing)**

**In Firebase Console:**
1. Open: https://console.firebase.google.com/project/sayekataleapp/firestore/data/subscriptions
2. Find document with ID = `{userId}`
3. Click on the document
4. Click "Delete document" (trash icon)
5. Confirm deletion

**Result:** Premium will be locked, user needs to subscribe again

---

### **Option 2: Set Subscription to Expired**

**In Firebase Console:**
1. Open: https://console.firebase.google.com/project/sayekataleapp/firestore/data/subscriptions
2. Find document with ID = `{userId}`
3. Edit the document:
   - Change `status` from `"active"` to `"expired"`
   - OR
   - Change `end_date` to a past date

**Result:** Premium will be locked due to expired subscription

---

### **Option 3: Using Cloud Function (Manual Deactivation)**

**If you prefer using API:**

```bash
# Create a temporary script
cat > /tmp/deactivate_subscription.sh << 'EOF'
#!/bin/bash
USER_EMAIL="drnamanya@gmail.com"
USER_ID="SccSSc08HbQUIYH731HvGhgSJNX2"  # Replace with actual userId

echo "Deactivating subscription for $USER_EMAIL (User ID: $USER_ID)"

# Note: You'll need to create a Cloud Function for this
# or use Firebase Admin SDK from your local machine
curl -X POST https://us-central1-sayekataleapp.cloudfunctions.net/manualDeactivateSubscription \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"$USER_ID\"
  }"
EOF

chmod +x /tmp/deactivate_subscription.sh
```

**Note:** This requires a `manualDeactivateSubscription` Cloud Function (not yet created)

---

## 🔒 Step 3: Verify Premium is Locked

### **Check in App:**
1. Open Sayekatale app
2. Log in as `drnamanya@gmail.com`
3. Go to SHG Dashboard
4. Look at Premium card:
   - **Should show:** "Unlock Premium" (grey/silver)
   - **Should NOT show:** "Premium Active" (purple)
   - **Text should be:** "Full SME Directory • UGX 50,000/year"

### **Check in Firestore:**
1. Open: https://console.firebase.google.com/project/sayekataleapp/firestore/data/subscriptions
2. Document with userId should be:
   - **Deleted** (no document found)
   - OR
   - **Expired** (status = "expired")

---

## 🧪 Step 4: Ready to Test

After locking premium:

1. ✅ Premium card shows "Unlock Premium"
2. ✅ Card is grey/silver (not purple)
3. ✅ Tapping card opens Subscription Purchase Screen
4. ✅ Ready to test payment flow!

**Next:** Follow the test procedure in `TEST_PREMIUM_SME_DIRECTORY_PAYMENT.md`

---

## 📋 Quick Reference

### **User Information:**
- Email: `drnamanya@gmail.com`
- User ID: `SccSSc08HbQUIYH731HvGhgSJNX2` (example - verify actual ID)

### **Firestore Locations:**
- Users: https://console.firebase.google.com/project/sayekataleapp/firestore/data/users
- Subscriptions: https://console.firebase.google.com/project/sayekataleapp/firestore/data/subscriptions
- Transactions: https://console.firebase.google.com/project/sayekataleapp/firestore/data/transactions

---

## 🔄 Alternative: Create Test User

If you don't want to affect the main account, create a test user:

1. **Register new account in app:**
   - Email: `test@example.com`
   - Password: `TestPassword123`

2. **Use this account for testing**
   - No existing subscription
   - Clean slate for testing

---

## ⚠️ Important Notes

**Before Deleting Subscription:**
- ✅ Note down the current subscription details (for reference)
- ✅ Ensure you have Firestore backup (if needed)
- ✅ Consider using a test account instead of production account

**After Deleting:**
- ✅ Subscription is completely removed
- ✅ User needs to pay again to access Premium
- ✅ Perfect for testing payment flow

**Restoring Subscription:**
- If you need to restore, you'll need to re-create the document
- Or the user can simply subscribe again through the app

---

## 🎯 Summary

**To lock premium for drnamanya@gmail.com:**

1. ✅ Find userId in Firestore (users or authentication)
2. ✅ Delete subscription document in Firestore
3. ✅ Verify "Unlock Premium" appears in app
4. ✅ Ready to test payment flow!

**Easiest method:** Delete the subscription document in Firebase Console

**Time required:** 1-2 minutes

**After locking:** Premium will require payment to unlock

---

**Ready to lock the premium? Use Option 1 (Delete Subscription Document) for quickest results! 🔒**
