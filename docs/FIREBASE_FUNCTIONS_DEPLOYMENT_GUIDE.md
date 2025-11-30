# 🚀 Firebase Cloud Functions Deployment Guide

## 📋 Overview

This guide will help you deploy the new delivery tracking notification functions to Firebase.

### New Functions to Deploy:
1. **onDeliveryTrackingCreated** - Notifies buyers when tracking becomes available
2. **onDeliveryStatusUpdate** - Notifies buyers when delivery status changes

### Existing Functions (Already Deployed):
1. onNewOrder
2. onOrderStatusUpdate
3. onNewMessage
4. onPSAVerificationSubmitted
5. onPSAVerificationStatusUpdate
6. onLowStockAlert
7. onReceiptGenerated

---

## ⚙️ Prerequisites

### 1. Firebase CLI Installed ✅
```bash
firebase --version
# Output: 14.20.0 ✅
```

### 2. Firebase Project Configured ✅
```bash
cat .firebaserc
# Output: { "projects": { "default": "sayekataleapp" } } ✅
```

### 3. Node.js Environment ✅
```bash
node --version
# Required: Node 20 or higher
```

---

## 🔐 Step 1: Firebase Authentication

### Option A: Login to Firebase (Recommended)

If you're deploying from your local machine:

```bash
# Login to Firebase
firebase login

# This will open a browser window for authentication
# Sign in with your Google account that has access to sayekataleapp
```

### Option B: Use Service Account (CI/CD)

If you're deploying from a CI/CD pipeline or server:

```bash
# Set service account credentials
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"

# Or use Firebase token
firebase login:ci
# Copy the token and set it
export FIREBASE_TOKEN="your-token-here"
```

### Verify Authentication:

```bash
# Check current user
firebase login:list

# Check project access
firebase projects:list
```

**Expected Output**:
```
✔ Logged in as: your-email@example.com
✔ sayekataleapp (active project)
```

---

## 📦 Step 2: Install Dependencies

Navigate to functions directory and ensure all dependencies are installed:

```bash
cd /home/user/flutter_app/functions

# Install Node.js dependencies
npm install

# Expected output:
# added X packages in Xs
```

**Common Issues**:
- If `npm install` fails, try: `npm install --legacy-peer-deps`
- If Node version mismatch, use: `nvm use 20` or `nvm install 20`

---

## ✅ Step 3: Validate Functions Code

Before deploying, validate that the code compiles correctly:

```bash
cd /home/user/flutter_app/functions

# Run ESLint to check for errors
npm run lint

# Expected: No critical errors (warnings are okay)
```

**If Lint Errors Occur**:
```bash
# Auto-fix most lint issues
npx eslint . --fix

# Then re-run lint
npm run lint
```

---

## 🚀 Step 4: Deploy Functions

### Option A: Deploy All Functions (Recommended First Time)

Deploy all functions including the new delivery tracking functions:

```bash
cd /home/user/flutter_app

# Deploy all functions
firebase deploy --only functions

# This will deploy:
# - onNewOrder
# - onOrderStatusUpdate
# - onNewMessage
# - onPSAVerificationSubmitted
# - onPSAVerificationStatusUpdate
# - onLowStockAlert
# - onReceiptGenerated
# - onDeliveryTrackingCreated (NEW)
# - onDeliveryStatusUpdate (NEW)
```

**Deployment Time**: ~3-5 minutes

**Expected Output**:
```
=== Deploying to 'sayekataleapp'...

i  deploying functions
i  functions: ensuring required API cloudfunctions.googleapis.com is enabled...
✔  functions: required API cloudfunctions.googleapis.com is enabled
i  functions: preparing codebase default for deployment
i  functions: ensuring required API artifactregistry.googleapis.com is enabled...
✔  functions: required API artifactregistry.googleapis.com is enabled
i  functions: preparing functions directory for uploading...
i  functions: packaged functions (XX KB) for uploading
✔  functions: functions folder uploaded successfully

i  functions: updating Node.js 20 function onDeliveryTrackingCreated(us-central1)...
i  functions: updating Node.js 20 function onDeliveryStatusUpdate(us-central1)...
✔  functions[onDeliveryTrackingCreated] Successful update operation.
✔  functions[onDeliveryStatusUpdate] Successful update operation.

✔  Deploy complete!
```

### Option B: Deploy Only New Functions (Faster)

If you only want to deploy the new delivery functions:

```bash
cd /home/user/flutter_app

# Deploy only delivery tracking functions
firebase deploy --only functions:onDeliveryTrackingCreated,functions:onDeliveryStatusUpdate
```

**Deployment Time**: ~1-2 minutes

---

## 🔍 Step 5: Verify Deployment

### Check Deployed Functions:

```bash
# List all deployed functions
firebase functions:list

# Expected output:
# ✔ onNewOrder
# ✔ onOrderStatusUpdate
# ✔ onNewMessage
# ✔ onPSAVerificationSubmitted
# ✔ onPSAVerificationStatusUpdate
# ✔ onLowStockAlert
# ✔ onReceiptGenerated
# ✔ onDeliveryTrackingCreated (NEW)
# ✔ onDeliveryStatusUpdate (NEW)
```

### View Function Details:

```bash
# Get info about specific function
firebase functions:config:get onDeliveryTrackingCreated
firebase functions:config:get onDeliveryStatusUpdate
```

### Check Function Logs:

```bash
# View recent logs for all functions
firebase functions:log

# View logs for specific function
firebase functions:log --only onDeliveryTrackingCreated
firebase functions:log --only onDeliveryStatusUpdate
```

---

## 🧪 Step 6: Test Deployment

### Test onDeliveryTrackingCreated:

**Manual Test**:
1. Go to Firebase Console → Firestore Database
2. Navigate to `delivery_tracking` collection
3. Create a test document with these fields:
```json
{
  "order_id": "test_order_123",
  "recipient_id": "your_test_user_id",
  "delivery_person_name": "Test Farmer",
  "delivery_person_id": "farmer_id",
  "recipient_name": "Test Buyer",
  "status": "pending",
  "created_at": "2025-11-29T10:00:00Z",
  "updated_at": "2025-11-29T10:00:00Z"
}
```
4. ✅ Check: Notification should be sent to recipient
5. ✅ Verify: Check function logs for success message

### Test onDeliveryStatusUpdate:

**Manual Test**:
1. Find the test document created above
2. Update the `status` field: `pending` → `inProgress`
3. ✅ Check: Notification should be sent with "🚚 Delivery Started" message
4. Update `status` again: `inProgress` → `completed`
5. ✅ Check: Notification should be sent with "✅ Delivery Completed" message

### App Integration Test:

**End-to-End Test**:
1. Open SayeKatale app as SME user
2. Place an order from a farmer
3. Login as farmer and confirm the order
4. ✅ Check: SME receives "📦 Delivery Tracking Available" notification
5. Farmer starts delivery
6. ✅ Check: SME receives "🚚 Delivery Started" notification
7. Farmer completes delivery
8. ✅ Check: SME receives "✅ Delivery Completed" notification

---

## 📊 Step 7: Monitor Function Performance

### View Function Metrics in Firebase Console:

1. Go to: https://console.firebase.google.com/
2. Select project: **sayekataleapp**
3. Navigate to: **Functions** → **Dashboard**
4. Check metrics:
   - Invocations count
   - Execution time
   - Error rate
   - Memory usage

### Set Up Alerts:

```bash
# Configure alert for function failures
firebase functions:config:set alert.email="your-email@example.com"
```

### Monitor Logs in Real-Time:

```bash
# Stream logs (useful during testing)
firebase functions:log --tail
```

---

## ⚠️ Common Issues & Solutions

### Issue 1: Authentication Failed

**Error**: `Error: Failed to authenticate`

**Solution**:
```bash
# Re-authenticate
firebase logout
firebase login
```

### Issue 2: Insufficient Permissions

**Error**: `Error: HTTP Error: 403, The caller does not have permission`

**Solution**:
- Ensure your Google account has **Owner** or **Editor** role in Firebase project
- Check in Firebase Console → Project Settings → Users and permissions

### Issue 3: Function Deploy Timeout

**Error**: `Error: Functions deploy timed out`

**Solution**:
```bash
# Increase timeout
firebase deploy --only functions --timeout 15m
```

### Issue 4: Node Version Mismatch

**Error**: `Error: Unsupported Node.js version`

**Solution**:
```bash
# Check required version in package.json
cat functions/package.json | grep '"node"'

# Install correct version
nvm install 20
nvm use 20

# Verify
node --version
```

### Issue 5: Dependency Installation Failed

**Error**: `npm ERR! peer dependency conflict`

**Solution**:
```bash
cd functions
rm -rf node_modules package-lock.json
npm install --legacy-peer-deps
```

### Issue 6: Function Not Triggering

**Symptom**: Function deployed but not executing on Firestore changes

**Solution**:
1. Check Firestore Security Rules allow writes to `delivery_tracking`
2. Verify function trigger path matches collection name exactly
3. Check function logs for errors: `firebase functions:log`
4. Ensure Firebase Admin SDK is initialized in functions

---

## 🔒 Step 8: Update Firestore Security Rules

After deployment, update security rules to allow Cloud Functions to write:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Delivery Tracking Collection
    match /delivery_tracking/{trackingId} {
      // Allow authenticated users to read their own deliveries
      allow read: if request.auth != null && (
        resource.data.delivery_person_id == request.auth.uid ||
        resource.data.recipient_id == request.auth.uid
      );
      
      // Allow delivery person to update tracking
      allow update: if request.auth != null && 
        resource.data.delivery_person_id == request.auth.uid;
      
      // Allow system (Cloud Functions & authenticated users) to create
      allow create: if request.auth != null;
      
      // Allow Cloud Functions to update for notifications
      allow update: if request.auth != null;
    }
  }
}
```

**Deploy Rules**:
```bash
firebase deploy --only firestore:rules
```

---

## ✅ Deployment Checklist

Before marking deployment as complete, verify:

- [ ] Firebase CLI authenticated successfully
- [ ] Dependencies installed (`npm install` completed)
- [ ] Code validation passed (`npm run lint`)
- [ ] Functions deployed successfully
- [ ] Functions visible in Firebase Console
- [ ] onDeliveryTrackingCreated function active
- [ ] onDeliveryStatusUpdate function active
- [ ] Test notification received for tracking created
- [ ] Test notification received for status update
- [ ] Function logs show successful execution
- [ ] Firestore security rules updated
- [ ] End-to-end app test passed
- [ ] No errors in production logs

---

## 📞 Support & Troubleshooting

### View Detailed Logs:

```bash
# View last 100 log entries
firebase functions:log --limit 100

# Filter by function name
firebase functions:log --only onDeliveryStatusUpdate

# Filter by severity
firebase functions:log --min-log-level error
```

### Rollback Deployment:

If something goes wrong:

```bash
# Delete problematic function
firebase functions:delete onDeliveryTrackingCreated
firebase functions:delete onDeliveryStatusUpdate

# Then fix the code and redeploy
```

### Get Help:

- **Firebase Documentation**: https://firebase.google.com/docs/functions
- **Firebase Status**: https://status.firebase.google.com/
- **Stack Overflow**: Tag your question with `firebase-cloud-functions`

---

## 🎯 Expected Results

After successful deployment:

### Immediate Effects:
- ✅ Functions visible in Firebase Console
- ✅ Functions listening to Firestore triggers
- ✅ Function logs showing initialization

### User Experience:
- ✅ SME receives push notification when tracking created
- ✅ SME receives push notification when delivery starts
- ✅ SME receives push notification when delivery completes
- ✅ In-app notifications appear in notification center
- ✅ Notification action URLs navigate to correct screens

### Performance:
- ⚡ Notification delivery: < 2 seconds
- ⚡ Function execution: < 1 second
- ⚡ Success rate: > 99%

---

## 🎉 Deployment Complete!

Once all steps are completed and verified:

✅ **Delivery tracking push notifications are LIVE!**

Users will now receive real-time notifications for:
- 📦 Delivery tracking availability
- 🚚 Delivery started
- ✅ Delivery completed
- ❌ Delivery cancelled/failed

The Track Delivery feature is now 100% complete with enterprise-grade notification capabilities!

---

## 📚 Next Steps

After successful deployment:

1. **Monitor Performance**: Watch function metrics for first 24 hours
2. **Collect User Feedback**: Ask users about notification experience
3. **Optimize if Needed**: Adjust notification content based on feedback
4. **Consider Enhancements**:
   - Add notification preferences (allow users to customize)
   - Implement notification sound/vibration customization
   - Add delivery ETA in notification message
   - Include distance remaining in progress notifications

