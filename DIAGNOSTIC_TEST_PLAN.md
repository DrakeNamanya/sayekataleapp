# 🔍 Comprehensive Diagnostic Test Plan

## Purpose
Systematically identify why profile photos upload but don't save, and why product photos upload but don't display.

---

## 🧪 Test 1: Profile Photo Upload - Full Diagnostic

### Setup:
1. Open browser Developer Tools (F12)
2. Go to **Console** tab
3. Keep console visible throughout test
4. Clear console (trash icon) before starting

### Steps:
1. Login as SHG user
2. Go to Profile → Edit Profile
3. **Before uploading anything**, note current state:
   - Does profile show "Complete your profile" banner? ✅ / ❌
   - Are there existing photos displayed? ✅ / ❌

4. **Upload Profile Photo:**
   - Click camera icon on profile photo
   - Select "Gallery"
   - Choose an image
   - **PAUSE - Check Console for:**
     ```
     Expected logs:
     - "📖 Reading bytes from XFile..."
     - "✅ Read XXXXX bytes from XFile"
     ```

5. **Upload National ID Photo:**
   - Click camera icon on National ID section
   - Select image
   - **PAUSE - Check Console**

6. **Fill ALL Required Fields:**
   - National ID Number: (enter valid format)
   - Name on ID Photo: (enter name)
   - Sex: (select Male or Female)
   - Location: (fill District, Subcounty, Parish, Village)

7. **Click "Save" Button**
   - **CRITICAL: Watch Console Carefully**

### Expected Console Output (Successful Flow):

```
📤 SHG EDIT PROFILE - Calling updateProfile with:
   - profileImageFile: blob:https://...
   - profileImagePath: blob:https://...
   - nationalIdPhotoFile: blob:https://...
   - nationalIdPhotoPath: blob:https://...
   - nationalId: filled
   - nameOnIdPhoto: filled
   - sex: Sex.male (or female)
   - location: District Name

🔄 Starting profile update for user: abc123xyz...
📥 Received parameters:
   - profileImageFile: blob:https://...
   - profileImageUrl: blob:https://...  (or null)
   - nationalIdPhotoFile: blob:https://...
   - nationalIdPhotoUrl: blob:https://...  (or null)
   - nationalId: CF123456789
   - nameOnIdPhoto: John Doe
   - sex: Sex.male
   - location: Kampala, Central

🔍 FIREBASE STORAGE DIAGNOSTICS
✅ User is authenticated
   - User ID: abc123xyz...

📤 Uploading profile image from XFile: blob:https://...
📖 Reading bytes from XFile...
✅ Read 123456 bytes from XFile
📝 Generated filename: profile_1234567890.jpg
📁 Storage path: profiles/abc123xyz/profile_1234567890.jpg
☁️ Uploading to Firebase Storage...
✅ Upload task completed
🔗 Getting download URL...
✅ Image uploaded successfully: https://firebasestorage.googleapis.com/...

📤 Uploading national ID photo from XFile: blob:https://...
(similar upload logs)
✅ Image uploaded successfully: https://firebasestorage.googleapis.com/...

📊 Final URLs after upload:
   - finalProfileImageUrl: https://firebasestorage.googleapis.com/... (MUST BE URL, NOT NULL!)
   - finalNationalIdPhotoUrl: https://firebasestorage.googleapis.com/... (MUST BE URL, NOT NULL!)

✓ Profile completion check:
   - nationalId: ✅
   - finalNationalIdPhotoUrl: ✅  (CRITICAL - Must be checkmark!)
   - nameOnIdPhoto: ✅
   - sex: ✅
   - location: ✅
   - RESULT: ✅ COMPLETE  (CRITICAL - Must say COMPLETE!)

💾 Saving to Firestore:
   - Updates: {
       profile_image: https://firebasestorage.googleapis.com/...,
       national_id_photo: https://firebasestorage.googleapis.com/...,
       national_id: CF123456789,
       name_on_id_photo: John Doe,
       sex: MALE,
       location: {...},
       is_profile_complete: true  (CRITICAL - Must be true!)
     }
   - Profile complete: true

✅ Profile saved to Firestore successfully

🔍 VERIFICATION - Reading back from Firestore:
   - profile_image: https://firebasestorage.googleapis.com/... (MUST MATCH UPLOADED URL!)
   - national_id_photo: https://firebasestorage.googleapis.com/... (MUST MATCH UPLOADED URL!)
   - national_id: CF123456789
   - is_profile_complete: true  (CRITICAL!)
```

### 🚨 ERROR PATTERNS TO WATCH FOR:

#### Error Pattern 1: "Not Authorized"
```
❌ Error uploading image: [firebase_storage/unauthorized] not authorized
```
**Diagnosis:** Firebase Storage rules issue
**Solution:** Update Storage rules (see previous instructions)

#### Error Pattern 2: URLs are NULL
```
📊 Final URLs after upload:
   - finalProfileImageUrl: null  ❌ PROBLEM!
   - finalNationalIdPhotoUrl: null  ❌ PROBLEM!
```
**Diagnosis:** Upload didn't complete or return URL
**Check:** Were there upload errors before this?

#### Error Pattern 3: Profile marked INCOMPLETE despite all fields
```
✓ Profile completion check:
   - finalNationalIdPhotoUrl: ❌  (PROBLEM - why is this false?)
   - RESULT: ❌ INCOMPLETE
```
**Diagnosis:** One or more required fields missing
**Action:** Check which field has ❌

#### Error Pattern 4: Saved but verification shows NOT SAVED
```
✅ Profile saved to Firestore successfully
🔍 VERIFICATION - Reading back from Firestore:
   - profile_image: NOT SAVED  ❌ PROBLEM!
```
**Diagnosis:** Update statement didn't include the field
**Check:** Look at "💾 Saving to Firestore" updates object

---

## 🧪 Test 2: Product Photo Upload - Full Diagnostic

### Setup:
Same as Test 1 (console open and visible)

### Steps:
1. Go to "My Products" screen
2. Click "+" button (Add Product)
3. Fill in ALL product details:
   - Name
   - Description
   - Category (select main + subcategory)
   - Price
   - Unit
   - Stock Quantity

4. **Add First Photo:**
   - Click "Add Photo" button
   - Select image
   - **Check Console for upload logs**
   - Verify photo appears in preview gallery

5. **Add Second and Third Photos:**
   - Repeat for 2 more photos
   - **Check Console after each upload**

6. **Click "Add Product" Button**
   - **CRITICAL: Watch Console**

### Expected Console Output:

```
📤 Uploading 3 product images...
📂 Starting upload: folder=products, userId=abc123xyz
(upload logs for each image)
✅ Uploaded 3 product images

📸 Saving 3 images for product
   Image 1: https://firebasestorage.googleapis.com/v0/b/.../photo1.jpg
   Image 2: https://firebasestorage.googleapis.com/v0/b/.../photo2.jpg
   Image 3: https://firebasestorage.googleapis.com/v0/b/.../photo3.jpg

📦 Creating product: Product Name for farmer John Doe
✅ Product created with ID: abc123xyz
```

7. **After Success:**
   - Go back to products list
   - **Check if product shows image** (not placeholder)
   - **Click on product** to view details
   - **Check if all 3 photos are visible**

---

## 📊 Diagnostic Checklist

### Issue 1: Profile Saves But Still Shows "Complete Profile"

**Check Console For:**
- [ ] `finalProfileImageUrl` is a URL (not null)
- [ ] `finalNationalIdPhotoUrl` is a URL (not null)
- [ ] Profile completion check shows all ✅
- [ ] `is_profile_complete: true` in Updates object
- [ ] Verification shows URLs were actually saved to Firestore

**If verification shows URLs are saved but banner still appears:**
- Problem is with UI refresh logic, not save logic
- Need to check profile banner component

### Issue 2: Product Photos Upload But Don't Display

**Check Console For:**
- [ ] "📸 Saving X images for product" message
- [ ] All image URLs are logged (Image 1, Image 2, Image 3)
- [ ] "✅ Product created with ID: ..." message

**Check Firestore Console:**
1. Go to Firebase Console → Firestore → products collection
2. Find the newly created product document
3. Check fields:
   - [ ] `images` field exists and is an array
   - [ ] `images` array contains all uploaded URLs
   - [ ] `image_url` field contains first image URL

**If Firestore has images but UI doesn't show:**
- Problem is with product display component, not save logic
- Need to check how product cards render images

---

## 🆘 Common Problems & Quick Fixes

### Problem: No console logs at all
**Cause:** Debug mode not enabled or console filtered
**Fix:** 
- Make sure you're testing on web (not release build)
- Check console filter (should show "All levels")
- Refresh page and try again

### Problem: "Request failed with error 403"
**Cause:** Firebase Storage rules blocking upload
**Fix:** Update Storage rules as per previous instructions

### Problem: Upload succeeds but URL is blob:// not https://
**Cause:** Local file path being saved instead of Firebase URL
**Fix:** Check the "📊 Final URLs" log - should be https:// URLs

### Problem: Firestore shows data but UI doesn't update
**Cause:** Local state not refreshing
**Fix:** Manually reload page (F5) and check if data persists

---

## 📝 Reporting Template

When reporting issues, provide:

```
## Console Output
[Paste complete console output from test]

## Issue Description
[What went wrong? Be specific]

## Critical Checks
- finalProfileImageUrl in console: [URL / null / not shown]
- finalNationalIdPhotoUrl in console: [URL / null / not shown]  
- is_profile_complete in Firestore: [true / false / not saved]
- Profile banner after reload: [shows / doesn't show]
- Product images in Firestore: [saved as array / saved as single / not saved]
- Product images in UI: [display / don't display]

## Screenshots
[If possible, screenshot of console output]
```

---

**Ready to start systematic testing! Open console, follow Test 1 step by step, and capture the console output!**
