# PSA Testing Guide - Complete Registration & Login Flow

## 🎯 Test Objective
Verify that PSA (Private Service Aggregator) registration and login works without black screens or loading issues.

## 🔗 Test URL
**App Preview**: https://5060-in9hu1x2vblsbdru37ud5-18e660f9.sandbox.novita.ai

## 📋 Test Scenarios

### Scenario 1: New PSA Registration (CRITICAL)

**Previous Issue**: Black screen with loading icon, unable to proceed

**Steps**:
1. Open app URL
2. Wait for splash screen animation
3. Click **"I'm a Supplier (PSA)"** button
4. Fill registration form:
   ```
   Name: Test PSA User
   Email: testpsa{random}@example.com  (use unique email each time)
   Phone: +256700000{random}  (e.g., +256700000123)
   Password: password123
   ```
5. Click **"Sign Up"**

**Expected Results**:
- ✅ Shows loading indicator for ~2 seconds (NEW FIX)
- ✅ Automatically navigates to PSA Dashboard
- ✅ Shows "Profile Under Review" or "Profile Completion Required" screen
- ✅ NO black screen
- ✅ NO infinite loading
- ✅ Can see logout button in top-right corner

**What Was Fixed**:
- Added 2-second delay after user creation
- Ensures Firestore document is fully written before navigation
- AuthProvider has time to load user data

---

### Scenario 2: PSA Login After Registration

**Steps**:
1. After successful registration, click **"Logout"** (top-right)
2. You'll see onboarding screen again
3. Select **"I'm a Supplier (PSA)"** role again
4. Click **"Sign In"** tab (if in Sign Up mode)
5. Enter same credentials used in registration
6. Click **"Sign In"**

**Expected Results**:
- ✅ Login successful within 2 seconds
- ✅ Navigates to PSA Dashboard
- ✅ Shows appropriate gate screen based on profile status
- ✅ NO black screen
- ✅ NO authentication errors

---

### Scenario 3: Profile Completion Flow

**Steps**:
1. After login, if you see "Profile Completion Required" screen:
2. Click **"Complete Profile Now"** button
3. Fill in required information:
   ```
   National ID Number (NIN): CM123456789ABC
   Date of Birth: Select a date
   Sex: Select Male or Female
   Location: Enter a location
   ```
4. Upload National ID Photo (use any image)
5. Click **"Save"** button

**Expected Results**:
- ✅ Profile saved successfully
- ✅ Shows success message
- ✅ Can now access PSA Dashboard features
- ✅ Profile completion gate no longer blocks access

---

### Scenario 4: PSA Verification Submission

**Prerequisites**: Profile must be complete (Scenario 3 done)

**Steps**:
1. In PSA Dashboard, look for "Submit Verification" or similar option
2. Fill PSA verification form:
   ```
   Business Name: Test Business
   Business Type: Select a type
   Business Address: 123 Test Street
   Business District: Kampala
   Tax ID (TIN): 123456789
   Bank Account Details: Fill with test data
   ```
3. Upload required documents:
   - Business License
   - Tax ID Document
   - National ID (again)
   - Trade License
4. Submit form

**Expected Results**:
- ✅ Form submits successfully
- ✅ Shows "Verification Submitted" message
- ✅ Status changes to "Under Review" or "Pending"
- ✅ Can see submission in admin verification screen

---

### Scenario 5: Notifications Test

**Steps**:
1. Login as PSA
2. Navigate to **"Notifications"** tab/screen
3. Check if notifications load

**Expected Results**:
- ✅ Notifications screen loads without errors
- ✅ Either shows notifications or "No notifications" message
- ✅ NO console errors about Timestamp types
- ✅ NO "Error loading notifications" message

**What Was Fixed**:
- Fixed Timestamp type conversion in notification model
- Added `parseDateTime` helper to handle both String and Timestamp

---

## 🐛 Issues to Report

If you encounter any of these, please report with details:

### Critical Issues:
- ❌ Black screen after registration
- ❌ Infinite loading indicator
- ❌ Cannot login after registration
- ❌ App crashes on PSA selection

### Important Issues:
- ⚠️ Profile completion doesn't save
- ⚠️ Verification form doesn't submit
- ⚠️ Notifications show errors
- ⚠️ Images don't upload

### Minor Issues:
- 📝 UI layout problems
- 📝 Text typos
- 📝 Slow loading (specify how long)

## 📱 Testing on Android Phone

If testing on actual Android device:

1. Download APK (will be built after web testing passes)
2. Enable **"Install from Unknown Sources"** in phone settings
3. Install APK
4. Follow same test scenarios above
5. Check for:
   - GPS permissions (for delivery tracking)
   - Camera permissions (for photo uploads)
   - Storage permissions (for documents)
   - Internet connectivity

## 🔍 Debugging Tips

### Enable Browser Console (F12):
```javascript
// Look for these debug messages:
"⏳ Waiting for user document to be fully synced..."
"✅ User document should be synced now, navigating to dashboard"
"✅ AUTH PROVIDER - User loaded successfully"
"✅ PSA verification placeholder created for admin review"
```

### Check Network Tab:
- Firestore requests should complete in <1 second
- Firebase Auth requests should be successful (200 status)
- Image uploads should show progress

### Common Console Errors (SHOULD NOT APPEAR):
- ❌ "type 'Timestamp' is not a subtype of type 'String'" → FIXED
- ❌ "User is null" messages indefinitely → FIXED
- ❌ Navigation errors → FIXED

## ✅ Success Checklist

After testing all scenarios, confirm:

- [ ] PSA registration works without black screen
- [ ] PSA login works immediately after registration
- [ ] Profile completion saves successfully
- [ ] PSA verification form submits
- [ ] Notifications load without errors
- [ ] No console errors about Timestamps
- [ ] Can logout and login again successfully
- [ ] Images/documents upload correctly

## 🚀 Next Steps After Testing

Once all tests pass:

1. ✅ Confirm all scenarios work
2. ⏳ Build final production Android APK
3. ⏳ Commit all fixes to GitHub
4. ⏳ Create release notes
5. ⏳ Submit to Google Play Store

---

**Testing Status**: 🟡 READY FOR TESTING
**Fixes Applied**: ✅ PSA Black Screen Fix, ✅ Timestamp Type Fix
**Test URL**: https://5060-in9hu1x2vblsbdru37ud5-18e660f9.sandbox.novita.ai
**Date**: November 29, 2025
