# 🔍 PSA Authentication Error - Root Cause Analysis

## Issue Status: **UNDER INVESTIGATION**

### What User Reported
mulungi@gmail.com PSA user cannot upload documents when clicking "Submit for Review":
- **Error**: "Authentication error. Logout and login again."
- **When**: After selecting 4 documents and clicking "Submit for Review" button
- **Impact**: Complete blockage of PSA verification workflow

---

## Investigation History

### 1. Initial Fix Attempt (COMPLETED)
**Problem**: App was using custom `PSA-XXXXX` IDs instead of Firebase Auth UIDs
**Fix**: Changed all upload calls to use `firebase_auth.FirebaseAuth.instance.currentUser.uid`
**Result**: Code is CORRECT but error persists

### 2. Code Verification (COMPLETED ✅)
Checked all critical code paths:

#### ✅ Upload Code (`psa_verification_form_screen.dart` Lines 301-373)
```dart
// Correct implementation:
final psaId = authProvider.currentUser?.id;  // PSA-12345
final firebaseAuthUid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;  // abc123...

// All 4 uploads use firebaseAuthUid ✅
_businessLicenseUrl = await _imageStorageService.uploadImageFromXFile(
  userId: firebaseAuthUid,  // ✅ Correct
  ...
);
```

#### ✅ Validation Code (`image_storage_service.dart` Lines 45-56)
```dart
final currentUser = FirebaseAuth.instance.currentUser;
if (currentUser.uid != userId) {
  throw Exception('User ID mismatch...');
}
```

#### ✅ Firebase Storage Rules (`storage.rules` Lines 160-172)
```
match /psa_verifications/{documentName} {
  allow write: if isAuthenticated() && isReasonableSize();
}
```

---

## Possible Root Causes

### Theory #1: Session State Issue
Firebase Auth `currentUser` might be different between:
- `psa_verification_form_screen.dart` (getting UID)
- `image_storage_service.dart` (validating UID)

**Why this happens**:
- Race condition during login
- AuthProvider loads Firestore user before Firebase Auth completes
- Multiple Firebase Auth instances

### Theory #2: Firebase Auth Not Fully Initialized
PSA might be:
1. Logging in successfully
2. Firestore profile loads (AuthProvider)
3. But Firebase Auth session not fully established
4. `FirebaseAuth.instance.currentUser` returns null or stale UID

### Theory #3: Firebase Storage Rules Not Deployed
Despite local file being correct, Firebase Console might have old rules expecting:
```
match /psa_verifications/{psaUserId}/{allPaths=**}
```
Instead of current:
```
match /psa_verifications/{documentName}
```

---

## Debug Logging Added

### In `image_storage_service.dart` (Line 52):
```dart
// 🔍 DEBUG: Log UID comparison
if (kDebugMode) {
  debugPrint('🔍 UID COMPARISON:');
  debugPrint('   Firebase Auth UID: ${currentUser.uid}');
  debugPrint('   Provided userId: $userId');
  debugPrint('   Match: ${currentUser.uid == userId}');
}
```

### In `psa_verification_form_screen.dart` (Line 307):
```dart
// 🔍 DEBUG: Log authentication state
if (kDebugMode) {
  debugPrint('🔐 AUTHENTICATION STATE:');
  debugPrint('   PSA ID (custom): $psaId');
  debugPrint('   Firebase Auth UID: $firebaseAuthUid');
  debugPrint('   AuthProvider user: ${authProvider.currentUser?.name}');
  debugPrint('   AuthProvider firebaseUser UID: ${authProvider.firebaseUser?.uid}');
}
```

---

## Next Steps

### For Developer (Me):
1. ✅ Add comprehensive debug logging
2. ⏳ Rebuild APK with debug logging
3. ⏳ Test with mulungi@gmail.com account
4. ⏳ Check Firebase Console logs
5. ⏳ Identify exact UID mismatch

### For User:
1. **Install NEW debug APK** (coming next)
2. **Login as mulungi@gmail.com**
3. **Try to submit verification again**
4. **Share Flutter logs/output** if error persists
5. **CRITICAL**: Deploy Firebase Storage Rules (see below)

---

## Firebase Console Actions Required

### 🔥 Firebase Storage Rules Deployment
**CRITICAL**: This must be done regardless of code fixes!

#### URL:
https://console.firebase.google.com/project/sayekataleapp/storage/sayekataleapp.firebasestorage.app/rules

#### Find This Rule:
```
match /psa_verifications/{psaUserId}/{allPaths=**} {
  allow write: if isAuthenticated() && isOwner(psaUserId);
  allow read: if isAuthenticated() && (isOwner(psaUserId) || isAdmin());
  allow delete: if isAdmin();
}
```

#### Replace With:
```
match /psa_verifications/{documentName} {
  // PSA users can read verification documents
  allow read: if isAuthenticated();
  
  // PSA users can upload verification documents
  // Must be authenticated and reasonable file size (5MB max)
  allow write: if isAuthenticated() && 
                  isReasonableSize();
  
  // No deletion by PSAs (admin review evidence)
  allow delete: if false;
}
```

#### Ensure `isReasonableSize()` function exists:
```
function isReasonableSize() {
  return request.resource.size < 5 * 1024 * 1024; // 5MB max
}
```

#### Then:
1. Click **"Publish"** button
2. Wait for deployment confirmation
3. Test PSA verification upload again

---

## Expected Behavior After Fix

### ✅ Success Flow:
1. PSA selects 4 documents
2. PSA clicks "Submit for Review"
3. **See debug logs** showing UIDs match:
   ```
   🔐 AUTHENTICATION STATE:
      PSA ID (custom): PSA-12345
      Firebase Auth UID: abc123def456...
   
   🔍 UID COMPARISON:
      Firebase Auth UID: abc123def456...
      Provided userId: abc123def456...
      Match: true
   ```
4. Documents upload successfully
5. Green snackbar: "Verification request submitted successfully!"
6. Admin sees verification in admin panel

### ❌ If Still Fails:
Debug logs will show EXACTLY which UID mismatches

---

## Files Modified

1. `/home/user/flutter_app/lib/services/image_storage_service.dart`
   - Added UID comparison debug logging

2. `/home/user/flutter_app/lib/screens/psa/psa_verification_form_screen.dart`
   - Added authentication state debug logging

---

## Related Documentation

- `/home/user/CRITICAL_BUG_FIX_SUMMARY.md` - Previous fix attempt
- `/home/user/ACTION_REQUIRED_NOW.txt` - Firebase deployment instructions
- `/home/user/PATH_MISMATCH_EXPLAINED.txt` - Storage path fix explanation
- `/home/user/PSA_VERIFICATION_FLOW_COMPLETE_ANALYSIS.md` - Complete flow analysis

---

## Debugging Timeline

| Time | Action | Result |
|------|--------|--------|
| Initial | User reports "Authentication error" | Error persists despite fixes |
| Fix #1 | Changed to use Firebase Auth UID | Code is correct but error continues |
| Fix #2 | Added debug logging | Ready for testing |
| Next | Rebuild APK + Deploy Storage Rules | TBD |

---

**Last Updated**: Now
**Status**: Waiting for APK rebuild and Firebase Storage Rules deployment
