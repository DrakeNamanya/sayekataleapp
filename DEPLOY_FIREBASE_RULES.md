# 🔒 Firebase Security Rules Deployment Guide

## Overview
This guide explains how to deploy the production-ready Firebase security rules for the SayeKatale app.

## Prerequisites
- Firebase CLI installed (`npm install -g firebase-tools`)
- Firebase project access (admin role)
- Authenticated with Firebase CLI

## Files to Deploy
1. **firestore.rules** - Firestore database security rules
2. **storage.rules** - Firebase Storage security rules
3. **firestore.indexes.json** - Firestore composite indexes

## Deployment Steps

### Step 1: Authenticate with Firebase
```bash
# Login to Firebase (opens browser)
firebase login

# Verify authentication
firebase projects:list
```

### Step 2: Verify Project Configuration
```bash
cd /home/user/flutter_app

# Check project ID
cat .firebaserc

# Expected output:
# {
#   "projects": {
#     "default": "sayekataleapp"
#   }
# }
```

### Step 3: Test Rules Locally (Optional but Recommended)
```bash
# Start Firebase emulator to test rules
firebase emulators:start --only firestore,storage

# In another terminal, run your Flutter app against emulator
# This helps catch any rule issues before production deployment
```

### Step 4: Deploy Rules to Firebase
```bash
# Deploy only Firestore rules
firebase deploy --only firestore:rules

# Deploy only Storage rules
firebase deploy --only storage

# Deploy both rules and indexes
firebase deploy --only firestore,storage

# Output should show:
# ✔  Deploy complete!
```

### Step 5: Verify Deployment
```bash
# Check deployment status
firebase firestore:rules:list
firebase storage:rules:list
```

## Manual Deployment (Firebase Console)

If you prefer to deploy via Firebase Console:

### Firestore Rules:
1. Go to: https://console.firebase.google.com/project/sayekataleapp/firestore/rules
2. Copy contents from `firestore.rules` file
3. Paste into the rules editor
4. Click "Publish"

### Storage Rules:
1. Go to: https://console.firebase.google.com/project/sayekataleapp/storage/rules
2. Copy contents from `storage.rules` file
3. Paste into the rules editor
4. Click "Publish"

### Firestore Indexes:
1. Go to: https://console.firebase.google.com/project/sayekataleapp/firestore/indexes
2. For each index in `firestore.indexes.json`, click "Create Index"
3. Configure fields and sort order as specified
4. Wait for index creation (can take several minutes)

## Key Security Improvements

### Before (Development Rules)
```javascript
// ❌ DANGEROUS - Anyone can read/write everything
match /{document=**} {
  allow read, write: if true;
}
```

### After (Production Rules)
```javascript
// ✅ SECURE - Role-based access control
match /users/{userId} {
  allow read: if isAuthenticated();
  allow update: if isOwner(userId);
  allow create, delete: if isAdmin();
}

match /wallets/{walletId} {
  allow read: if isOwner(walletId) || isAdmin();
  allow create, update, delete: if false; // Backend webhooks only
}
```

## Testing the Deployed Rules

After deployment, test the rules with your Flutter app:

### Test 1: Authenticated User Can Read Own Data
```dart
// Should succeed
final user = FirebaseAuth.instance.currentUser;
final userData = await FirebaseFirestore.instance
    .collection('users')
    .doc(user!.uid)
    .get();
```

### Test 2: Unauthenticated User Cannot Access Data
```dart
// Should fail with permission-denied
await FirebaseAuth.instance.signOut();
final userData = await FirebaseFirestore.instance
    .collection('users')
    .doc('some_user_id')
    .get(); // ❌ PERMISSION_DENIED
```

### Test 3: User Cannot Modify Wallet Directly
```dart
// Should fail - wallets can only be modified by backend
await FirebaseFirestore.instance
    .collection('wallets')
    .doc(user.uid)
    .update({'balance': 1000000}); // ❌ PERMISSION_DENIED
```

### Test 4: Admin Can Access All Users
```dart
// Should succeed if user has role='admin'
final allUsers = await FirebaseFirestore.instance
    .collection('users')
    .get();
```

## Rollback Plan

If rules cause issues, you can quickly rollback:

### Option 1: Firebase Console
1. Go to Firestore/Storage Rules page
2. Click "History" tab
3. Select previous version
4. Click "Restore"

### Option 2: Git Revert
```bash
# Revert to development rules
git checkout HEAD~1 firestore.rules storage.rules

# Deploy reverted rules
firebase deploy --only firestore,storage
```

### Option 3: Emergency Open Access (Temporary Only!)
```bash
# Create temporary open rules
cat > firestore.rules << 'EOF'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
EOF

# Deploy temporary rules
firebase deploy --only firestore:rules

# ⚠️ IMPORTANT: Fix and redeploy proper rules ASAP!
```

## Monitoring After Deployment

### Check Firebase Console for Errors
1. Go to: https://console.firebase.google.com/project/sayekataleapp/firestore/usage
2. Look for "Permission Denied" errors spike
3. Check "Requests" tab for failed operations

### Check App Logs
```dart
// Add error logging to catch permission issues
try {
  await FirebaseFirestore.instance.collection('users').get();
} catch (e) {
  if (e.toString().contains('permission-denied')) {
    print('🔒 Permission denied - check Firebase rules');
  }
}
```

## Common Issues and Solutions

### Issue 1: "Permission Denied" for Valid Operations
**Cause**: Rules might be too restrictive
**Solution**: Check rule logic for that collection, add debug logs

### Issue 2: Indexes Not Working
**Cause**: Indexes still building or not created
**Solution**: Wait 5-10 minutes, check Firebase Console indexes tab

### Issue 3: Storage Upload Fails
**Cause**: File size or content type validation
**Solution**: Check storage.rules file size limits and content type matchers

## Next Steps After Deployment

1. ✅ Monitor Firebase Console for 24 hours
2. ✅ Run integration tests against production rules
3. ✅ Update CI/CD pipeline to deploy rules automatically
4. ✅ Document any custom rules added for new features
5. ✅ Set up Firebase alerts for rule violations

## Support

If you encounter issues:
- Check Firebase Console logs
- Review rules syntax at: https://firebase.google.com/docs/rules
- Test rules in Firebase Emulator before production deployment
- Contact Firebase Support if rules are deployed but not working

---

**Last Updated**: Phase 1 - Security Hardening
**Status**: Ready for deployment
**Project**: sayekataleapp
