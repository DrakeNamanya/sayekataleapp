# 🔍 Quick Diagnostic Reference Card

## Before You Start
1. **Open Browser Developer Tools** (Press F12)
2. **Go to Console Tab**
3. **Clear Console** (click trash icon)
4. **Keep console visible** during entire test

---

## 🧪 Test Profile Upload - Follow These Steps

### STEP 1: Login & Navigate
- Login as SHG user
- Go to Profile → Edit Profile

### STEP 2: Upload Photos
- Upload Profile Photo (camera icon)
- Upload National ID Photo (camera icon)
- **DON'T SAVE YET**

### STEP 3: Fill ALL Required Fields
- ✅ National ID Number
- ✅ Name on ID Photo
- ✅ Sex (Male/Female)
- ✅ Location (District, Subcounty, Parish, Village)

### STEP 4: Click "Save" and Watch Console

---

## ✅ What You SHOULD See in Console

```
📤 SHG EDIT PROFILE - Calling updateProfile with:
   - profileImageFile: blob:https://... ✅ GOOD
   - nationalIdPhotoFile: blob:https://... ✅ GOOD

🔄 Starting profile update for user: abc123...

📤 Uploading profile image from XFile: blob:...
✅ Image uploaded successfully: https://firebasestorage... ✅ MUST BE HTTPS URL!

📤 Uploading national ID photo from XFile: blob:...
✅ Image uploaded successfully: https://firebasestorage... ✅ MUST BE HTTPS URL!

📊 Final URLs after upload:
   - finalProfileImageUrl: https://firebasestorage... ✅ MUST NOT BE NULL!
   - finalNationalIdPhotoUrl: https://firebasestorage... ✅ MUST NOT BE NULL!

✓ Profile completion check:
   - nationalId: ✅
   - finalNationalIdPhotoUrl: ✅  ← CRITICAL CHECK!
   - nameOnIdPhoto: ✅
   - sex: ✅
   - location: ✅
   - RESULT: ✅ COMPLETE  ← MUST SAY COMPLETE!

💾 Saving to Firestore:
   - Updates: {
       profile_image: https://firebasestorage...,  ✅ URL PRESENT
       national_id_photo: https://firebasestorage...,  ✅ URL PRESENT
       is_profile_complete: true  ✅ MUST BE TRUE!
     }

✅ Profile saved to Firestore successfully

🔍 VERIFICATION - Reading back from Firestore:
   - profile_image: https://firebasestorage... ✅ SAVED!
   - national_id_photo: https://firebasestorage... ✅ SAVED!
   - is_profile_complete: true ✅ SAVED!
```

---

## ❌ PROBLEM PATTERNS

### Problem 1: URLs are NULL
```
📊 Final URLs after upload:
   - finalProfileImageUrl: null  ❌ PROBLEM!
```
**Meaning:** Upload failed or didn't return URL
**Action:** Scroll up to find error message

### Problem 2: Profile Marked INCOMPLETE
```
✓ Profile completion check:
   - RESULT: ❌ INCOMPLETE
```
**Action:** Check which field has ❌ mark

### Problem 3: NOT SAVED to Firestore
```
🔍 VERIFICATION:
   - profile_image: NOT SAVED  ❌
```
**Action:** Check if "Updates" object had the URLs

### Problem 4: "Not Authorized" Error
```
❌ Error: not authorized to perform desired action
```
**Action:** Firebase Storage rules need updating

---

## 📋 Quick Checklist

Copy this and check off as you test:

```
PROFILE TEST:
[ ] Opened console (F12)
[ ] Cleared console
[ ] Uploaded profile photo
[ ] Uploaded national ID photo
[ ] Filled ALL required fields
[ ] Clicked "Save"
[ ] Saw "📤 SHG EDIT PROFILE" log
[ ] Saw "✅ Image uploaded successfully: https://..." (TWO TIMES)
[ ] Saw "📊 Final URLs" with HTTPS URLs (not null)
[ ] Saw "RESULT: ✅ COMPLETE"
[ ] Saw "💾 Saving to Firestore" with URLs in Updates
[ ] Saw "🔍 VERIFICATION" with URLs saved
[ ] Reloaded page (F5)
[ ] Profile banner gone? YES / NO
[ ] Photos persist? YES / NO
```

---

## 🚨 If You See Errors

**Copy the ENTIRE console output** and report:
1. What error appeared?
2. At which step did it fail?
3. What were the "📊 Final URLs" values?
4. What was in "💾 Saving to Firestore" Updates object?
5. What did "🔍 VERIFICATION" show?

---

## Product Photo Test (Shorter Version)

1. Go to "My Products" → Add Product
2. Fill product details
3. Add 2-3 photos
4. Click "Add Product"
5. **Check console for:**
   ```
   📸 Saving X images for product
      Image 1: https://... ✅
      Image 2: https://... ✅
   ✅ Product created with ID: ...
   ```
6. Go back to products list
7. **Does product show photo?** YES / NO

---

**🔗 App URL:** https://5060-i25ra390rl3tp6c83ufw7-583b4d74.sandbox.novita.ai

**Ready to test! Follow the steps above and watch console output carefully!**
